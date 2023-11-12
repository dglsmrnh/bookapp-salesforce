@RestResource(urlMapping='/quests')
global with sharing class QuestIntegration {

    @HttpGet
    global static String getAvailableQuests() {
        try {
            RestRequest req = RestContext.request;

            if(!req.params.containsKey('username')) {
                throw new QuestException('username parameter not found.');
            }

            String username = req.params.get('username');
            Boolean recommendation = false;

            if(req.params.containsKey('recommendation')) {
                recommendation = Boolean.valueOf(req.params.get('recommendation'));
            }

            if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
                throw new QuestException('username\'s account not found.');
            }

            String fields = String.join(IntegrationUtils.getFields('Product2'), ', ');
            // String fieldsProduct = String.join(
            //     IntegrationUtils.addRelationshipObjectToFields(IntegrationUtils.getFields('Product2'), 'Product2'), 
            //     ','
            // );

            String query = 'SELECT ' + fields + ' FROM Product2 WHERE isActive = true';
            List<Product2> productList = Database.query(query);
            
            List<Quest> questList = new List<Quest>();

            for(Product2 product : productList) {
                questList.add(new Quest(product, false));
            }    
            GetResponse response = new GetResponse(questList);
            return JSON.serialize(response);
        }
        catch(Exception e) {
            // RestResponse res = RestContext.response;
            // res.statusCode = 500;
            ErrorResponse response = new ErrorResponse(e.getMessage());
            return JSON.serialize(response);
        }
    }

    global class GetResponse {
        global Boolean success;
        global String message;
        global List<Quest> quests;

        global GetResponse(List<Quest> quests) {
            this.success = true;
            this.quests = quests;
        }
    }

    global class Quest {
        global String id;
        global Product2 info;
        global Boolean recommendation;

        global Quest(Product2 product, Boolean recommendation) {
            this.id = product.id;
            this.info = product;
            this.recommendation = recommendation;
        }
    }    

    @HttpPost
    global static String createQuest(PostRequest request) {
        try {
            String username = request.username;
            if(String.isEmpty(username)) {
                throw new QuestException('username parameter not found.');
            }

            if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
                throw new QuestException('user not found.');
            }

            Id questId = Id.valueOf(request.id);

            if([SELECT Id FROM Product2 WHERE Id =: questId AND IsActive = true].size() < 1) {
                throw new QuestException('quest not available.');
            }

            Account account = [SELECT Id FROM Account WHERE Username__c =: username];
            Product2 product = [SELECT Id, Name FROM Product2 WHERE Id =: questId AND IsActive = true];

            Asset asset = new Asset();
            asset.AccountId = account.Id;
            asset.Product2Id = questId;
            asset.Name = product.Name;
            asset.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId();

            insert asset;

            PostResponse response = new PostResponse(asset.Id);
            return JSON.serialize(response);
        } catch (Exception e) {
            ErrorResponse response = new ErrorResponse(e.getMessage());
            return JSON.serialize(response);
        }
    }

    global class PostRequest {
        global String username;
        global String id;
    }
    
    global class PostResponse {
        global Boolean success;
        global String message;
        global String id;

        global PostResponse(Id id) {
            this.success = true;
            this.id = id;
        }
    }

    @HttpPatch
    global static String updateQuest(PatchRequest request) {
        try {
            String username = request.username;
            if(String.isEmpty(username)) {
                throw new QuestException('username parameter not found.');
            }

            if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
                throw new QuestException('user not found.');
            }

            Id questId = Id.valueOf(request.id);

            if([SELECT Id FROM Asset WHERE Id =: questId].size() < 1) {
                throw new QuestException('quest not available.');
            }

            if((request.currentChapter == null || request.currentChapter <= 0) && (request.currentPage == null || request.currentPage <= 0)) {
                throw new QuestException('current progress not informed.');
            }

            if(request.currentChapter != null && request.currentPage != null) {
                throw new QuestException('invalid progress informed.');
            }

            Integer currentChapter = request.currentChapter;
            Integer currentPage = request.currentPage;

            Asset asset = [SELECT Id, Product2Id, CurrentChapter__c, CurrentPage__c FROM Asset WHERE Id =: questId];
            BookCheckpoint__c bookCP = getBookCheckpoint(asset, request.currentChapter, request.currentPage);

            PatchResponse response = new PatchResponse(questId);

            if(bookCP != null) {
                response.hasCheckpoint = true;
                response.capped = ((request.currentChapter != null && request.currentChapter > bookCP.Chapter__c) || (request.currentPage != null && request.currentPage > bookCP.Page__c));
                if(response.capped) {
                    currentChapter = bookCP.Chapter__c.intValue();
                    currentPage = bookCP.Page__c.intValue();
                }

                createCheckpoint(bookCP.Id, questId);
            }

            asset.CurrentChapter__c = currentChapter;
            asset.CurrentPage__c = currentPage;
            update asset;

            response.currentChapter = currentChapter;
            response.currentPage = currentPage;

            return JSON.serialize(response);
        } catch (Exception e) {
            ErrorResponse response = new ErrorResponse(e.getMessage());
            return JSON.serialize(response);
        }
    }

    private static BookCheckpoint__c getBookCheckpoint(Asset asset, Integer currentChapter, Integer currentPage) {
        Map<Id, BookCheckpoint__c> mapBookCP;
        Id productId = asset.Product2Id;
        Id assetId = asset.Id;

        if (currentChapter != null && currentPage == null) {
            mapBookCP = new Map<ID, BookCheckpoint__c>([SELECT Id, Chapter__c, Page__c FROM BookCheckpoint__c WHERE Book__c =: productId AND Chapter__c <= :currentChapter AND Chapter__c != null ORDER BY Chapter__c ASC]);
        } else {
            mapBookCP = new Map<ID, BookCheckpoint__c>([SELECT Id, Chapter__c, Page__c FROM BookCheckpoint__c WHERE Book__c =: productId AND Page__c <= :currentPage AND Page__c != null ORDER BY Page__c ASC]);
        }

        List<Id> bookCpIdsList = new List<Id>();

        if(mapBookCP.size() <= 0) {
            return null;
        }

        for(Id bookCpId : mapBookCP.keySet()) {
            bookCpIdsList.add(bookCpId);
        }

        List<AssetCheckpoint__c> assetCPList = [SELECT Id, BookCheckpoint__c FROM AssetCheckpoint__c WHERE Book__c =: assetId AND BookCheckpoint__c IN: bookCpIdsList];

        for(AssetCheckpoint__c assetCP : assetCPList) {
            if(mapBookCP.containsKey(assetCP.BookCheckpoint__c)) {
                mapBookCP.remove(assetCP.BookCheckpoint__c);
            }
        }

        if(mapBookCP.size() <= 0) {
            return null;
        }

        return mapBookCP.values().get(0);
    }

    private static void createCheckpoint(Id bookCPId, Id questId) {
        AssetCheckpoint__c assetCP = new AssetCheckpoint__c();
        assetCP.Book__c = questId;
        assetCP.BookCheckpoint__c = bookCPId;

        insert assetCP;
    }

    global class PatchRequest {
        global String username;
        global String id;
        global Integer currentPage;
        global Integer currentChapter;
        global Boolean completed;
    }

    global class PatchResponse {
        global Boolean success;
        global String message;
        global String id;
        global Boolean hasCheckpoint;
        global Boolean capped;
        global Integer currentPage;
        global Integer currentChapter;

        global PatchResponse(Id questId) {
            this.success = true;
            this.id = questId;
            this.hasCheckpoint = false;
            this.capped = false;            
        }
    }

    global class ErrorResponse {
        global Boolean success;
        global String message;

        global ErrorResponse(String message) {
            this.success = false;
            this.message = message;
        }
    } 

    private class QuestException extends Exception {
    }
    
}