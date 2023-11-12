@RestResource(urlMapping='/quests')
global with sharing class QuestIntegration {

    @HttpGet
    global static String getQuests() {
        try {
            RestRequest params = RestContext.request.params;

            String recordTypeString;
            if(thisReq.params.containsKey('type')) {
                recordTypeString = thisReq.params.get('type');
            }
            else {
                throw new Exception('"username" parameter not found.');
            }

            if([SELECT Id FROM RecordType WHERE Name =: recordTypeString].size() < 1) {
                throw new TypeException('Selected type not found.');
            }

            List<ProductDataObject> productList = new List<ProductDataObject>();

            for(Product2 prod : [SELECT Id, Name, Type, Description, ProductClass, ProductCode, StockKeepingUnit 
                                 FROM Product2 WHERE IsActive = TRUE AND RecordType.Name =: recordTypeString]) {
                ProductDataObject newProd = new ProductDataObject(prod);
                productList.add(newProd);
            }

            ResponseBodyObject responseBody;

            if(productList.size() > 0) {
                responseBody = new ResponseBodyObject(productList);
            }
            else {
                throw new NoSuchElementException('No records with the selected type were found.');
            }

            return JSON.serialize(responseBody);
        }
        catch(Exception e) {
            ResponseBodyObject responseBody = new ResponseBodyObject(e.getMessage());

            return JSON.serialize(responseBody);
        }
    }

    public class Response {
        public Boolean success;
        public String message;
        public List<Quest> quests;

        public Response(String message) {
            this.success = false;
            this.message = message;
        }

        public Response(List<Quest> quests) {
            this.success = true;
            this.quests = quests;
        }
    
        public static Response parse(String jsonInput) {
            return (Response) System.JSON.deserialize(jsonInput, Response.class);
        }
    }

    public class Quest {
        public String id;
        public Asset info;
        public Boolean recommendation;
    }
    
}