@RestResource(urlMapping='/account')
global with sharing class AccountIntegration {

    global static final Id ASSET_CLASS_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id PRODUCT_CLASS_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id ASSET_COLOR_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Color').getRecordTypeId();
    global static final Id PRODUCT_COLOR_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Color').getRecordTypeId();
    global static final Id ASSET_RACE_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id PRODUCT_RACE_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id ASSET_ATTRIBUTE_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id PRODUCT_ATTRIBUTE_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id ASSET_BOOK_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Book').getRecordTypeId();
    global static final Id PRODUCT_BOOK_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId();

    @HttpPost
    global static String postAccountWithCharacter() {
        try {
            RestRequest thisReq = RestContext.request;
            List<PostResponseBodyObject> responseBody = new List<PostResponseBodyObject>();
            List<Account> accountInsertList = new List<Account>();
            List<Asset> assetInsertList = new List<Asset>();

            List<PostRequestBody> requestBodyAsList = (List<PostRequestBody>) JSON.deserialize(thisReq.requestBody.toString(), List<PostRequestBody>.Class);
            Set<String> productCodeList = new Set<String>();
            
            for(PostRequestBody reqBody : requestBodyAsList) {
                productCodeList.add(reqBody.character.classId);
                productCodeList.add(reqBody.character.raceId);
                productCodeList.add(reqBody.character.colorId);
            }

            Map<String, Product2> mapProductCodeToProduct = new Map<String, Product2>();
            for(Product2 prod : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productCodeList]) {
                if(!mapProductCodeToProduct.containsKey(prod.ProductCode)) {
                    mapProductCodeToProduct.put(prod.ProductCode, prod);
                }
            }

            for(PostRequestBody bodyObj : requestBodyAsList) {
                Account newAccount = new Account();
                newAccount.Name = bodyObj.account.name;
                //newAccount.CharacterName__c = bodyObj.character.name;
                newAccount.Email__c = bodyObj.account.email;
                newAccount.Gender__c = bodyObj.account.gender;
                newAccount.Birthday__c = bodyObj.account.birthdate;
                newAccount.Username__c = bodyObj.account.username;
                newAccount.Password__c = bodyObj.account.password;
                accountInsertList.add(newAccount);

                if(String.isNotBlank(bodyObj.character.classId)) {
                    Asset classAsset = new Asset();
                    classAsset.Account = newAccount;
                    classAsset.Product2 = mapProductCodeToProduct.get(bodyObj.character.classId);
                    assetInsertList.add(classAsset);
                }

                if(String.isNotBlank(bodyObj.character.raceId)) {
                    Asset raceAsset = new Asset();
                    raceAsset.Account = newAccount;
                    raceAsset.Product2 = mapProductCodeToProduct.get(bodyObj.character.raceId);
                    assetInsertList.add(raceAsset);
                }

                if(String.isNotBlank(bodyObj.character.colorId)) {
                    Asset colorAsset = new Asset();
                    colorAsset.Account = newAccount;
                    colorAsset.Product2 = mapProductCodeToProduct.get(bodyObj.character.colorId);
                    assetInsertList.add(colorAsset);
                }
            }

            Database.insert(accountInsertList, true);
            Database.insert(assetInsertList, true);

            for(Account acc : accountInsertList) {
                PostResponseBodyObject newResponse = new PostResponseBodyObject();
                if(acc.Id != null) {
                    newResponse.id = acc.Id;
                    newResponse.success = true;
                }
                else {
                    newResponse.success = false;
                    newResponse.message = 'An error ocurred while tring to insert the account with the name ' + acc.Name;
                }
                responseBody.add(newResponse);
            }

            return JSON.serialize(responseBody);
        }
        catch(Exception e) {
            ErrorResponse responseBody = new ErrorResponse(e.getMessage());
            return JSON.serialize(responseBody);
        }
    }

    @Httpget
    global static String getAccountAndCharacter() {
        try {
            GetResponseBodyObject responseBody = new GetResponseBodyObject();
            RestRequest thisReq = RestContext.request;
            Map<String, String> requestParams = thisReq.params;
            
            if(!requestParams.containsKey('username')) {
                throw new CalloutException('The parameter "username" could not be found on your request.');
            }
            String username = requestParams.get('username');

            String fields = String.join(IntegrationUtils.getFields('Account'), ', ');

            String query = 'SELECT ' + fields + ' FROM Account WHERE Username__c =: username';
            
            List<Account> accountList = Database.query(query);

            if(accountList.size() <= 0) {
                throw new CalloutException('No account with the username ' + username + ' could be found.');
            }

            String questFields = String.join(IntegrationUtils.getFields('Product2'), ', ');
            String questQuery = 'SELECT ' + questFields + ' FROM Product2 WHERE Id IN (SELECT Product2Id FROM Asset WHERE Account.Username__c = \'' + username + '\') AND isActive = true AND RecordType.Name = \'Book\'';
            List<Product2> productList = Database.query(questQuery);
            
            List<Quest> questList = new List<Quest>();

            for(Product2 product : productList) {
                questList.add(new Quest(product, false));
            }    

            List<Asset> assetList = [SELECT Id, RecordType.Name, Product2Id FROM Asset WHERE Account.Username__c =: username];
            Map<String, Asset> mapNameToAsset = new Map<String, Asset>();
            List<Asset> attributeList = new List<Asset>();

            for(Asset ass : assetList) {
                if(ass.RecordType.Name != 'Attribute') {
                    mapNameToAsset.put(ass.RecordType.Name, ass);
                }
                else {
                    attributeList.add(ass);
                }
            }

            for(Account acc : accountList) {
                responseBody.account.name = acc.Name;
                responseBody.account.email = acc.Email__c;
                responseBody.account.username = acc.Username__c;
                responseBody.account.password = acc.Password__c;
                responseBody.account.gender = acc.Gender__c;
                responseBody.account.birthdate = acc.Birthday__c;
                //responseBody.character.name = acc.CharacterName__c;
                //responseBody.character.level = acc.Level__c;
                //responseBody.character.levelUp = acc.LevelUp__c;
                //responseBody.character.xp = acc.Xp__c;
                //responseBody.character.bonusXp = acc.BonusXp__c;
                //responseBody.character.lostXp = acc.LostXp__c;
                //responseBody.character.level_cap = acc.LevelCap__c;
                //responseBody.character.coins = acc.Coins__c;
                //responseBody.character.attribute_points = acc.AttributePoints__c;
                responseBody.character.c_class = mapNameToAsset.containsKey('Class') ? mapNameToAsset.get('Class') : null;
                responseBody.character.race = mapNameToAsset.containsKey('Race') ? mapNameToAsset.get('Race') : null;
                responseBody.character.color = mapNameToAsset.containsKey('Color') ? mapNameToAsset.get('Color') : null;
                responseBody.character.attributes = attributeList.size() > 0 ? attributeList : null;
                responseBody.character.quests = questList.size() > 0 ? questList : null;
                //responseBody.character.inventory = mapNameToAsset.containsKey('Color') ? mapNameToAsset.get('Color') : null;
            }

            responseBody.success = true;
            responseBody.message = null;
            return JSON.serialize(responseBody);
        }
        catch (Exception e) {
            ErrorResponse responseBody = new ErrorResponse(e.getMessage());
            return JSON.serialize(responseBody);
        }
    }

    global class AccountDataObject {
        global String name;
        global String email;
        global String username;
        global String password;
        global String gender;
        global Date birthdate;
    }

    global class CharacterDataObject {
        global String name;
        global String classId;
        global String raceId;
        global String colorId;
        global Integer level;
        global Boolean levelUp;
        global Integer xp;
        global Integer bonusXp;
        global Integer lostXp;
        global Integer level_cap;
        global Integer coins;
        global Integer attribute_points;
        Asset c_class;
        Asset race;
        Asset color;
        global List<Asset> attributes;
        global List<Asset> inventory;
        global List<Quest> quests;
    }

    global class PostRequestBody {
        AccountDataObject account;
        CharacterDataObject character;
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

    global class PostResponseBodyObject {
        global Boolean success;
        global String message;
        global String id;
    }

    global class GetResponseBodyObject {
        global Boolean success;
        global String message;
        global AccountDataObject account = new AccountDataObject();
        global CharacterDataObject character = new CharacterDataObject();
    }

    global class ErrorResponse {
        global Boolean success;
        global String message;

        global ErrorResponse(String message) {
            this.success = false;
            this.message = message;
        }
    } 

    private class AccountException extends Exception {
    }
}