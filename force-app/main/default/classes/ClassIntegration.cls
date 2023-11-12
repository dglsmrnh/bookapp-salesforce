@RestResource(urlMapping='/class')
global with sharing class ClassIntegration {
    
    global static final Id ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Class').getRecordTypeId();

    @HttpGet
    global static String getAvailableClasses() {
        try {
            RestRequest req = RestContext.request;

            if(!req.params.containsKey('username')) {
                throw new ClassException('username parameter not found.');
            }

            String username = req.params.get('username');
            
            if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
                throw new ClassException('username\'s account not found.');
            }

            String fields = String.join(IntegrationUtils.getFields('Product2'), ', ');
            // String fieldsProduct = String.join(
            //     IntegrationUtils.addRelationshipObjectToFields(IntegrationUtils.getFields('Product2'), 'Product2'), 
            //     ','
            // );

            String query = 'SELECT ' + fields + ' FROM Product2 WHERE isActive = true AND RecordTypeId =: PRODUCT_RECORDTYPE';
            List<Product2> productList = Database.query(query);
              
            GetResponse response = new GetResponse(productList);
            return JSON.serialize(response);
        }
        catch(Exception e) {
            // RestResponse res = RestContext.response;
            // res.statusCode = 500;
            return JSON.serialize(new ErrorResponse(e.getMessage()));
        }
    }

    global class GetResponse {
        global Boolean success;
        global String message;
        global List<Product2> classes;

        global GetResponse(List<Product2> classes) {
            this.success = true;
            this.classes = classes;
        }
    }

    @HttpPost
    global static String saveClass(PostRequest request) {
        try {
            String username = request.username;
            if(String.isEmpty(username)) {
                throw new ClassException('username parameter not found.');
            }

            if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
                throw new ClassException('user not found.');
            }

            Id classId = Id.valueOf(request.classId);

            if([SELECT Id FROM Product2 WHERE Id =: classId].size() < 1) {
                throw new ClassException('class not available.');
            }

            Account account = [SELECT Id, DefaultClass__c FROM Account WHERE Username__c =: username];
            Product2 product = [SELECT Id, Name FROM Product2 WHERE Id =: classId AND IsActive = true];

            Asset asset = new Asset();
            asset.AccountId = account.Id;
            asset.Product2Id = classId;
            asset.Name = product.Name;
            asset.RecordTypeId = ASSET_RECORDTYPE;

            insert asset;

            account.DefaultClass__c = asset.Id;
            update account;

            PostResponse response = new PostResponse(asset.Id);
            return JSON.serialize(response);
        } catch (Exception e) {
            return JSON.serialize(new ErrorResponse(e.getMessage()));
        }
    }

    global class PostRequest {
        global String username;
        global String classId;
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

    global class ErrorResponse {
        global Boolean success;
        global String message;

        global ErrorResponse(String message) {
            this.success = false;
            this.message = message;
        }
    } 

    private class ClassException extends Exception {
    }
}