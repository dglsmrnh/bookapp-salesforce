@RestResource(urlMapping='/products')
global with sharing class ProductIntegration {
    @HttpGet
    global static String getProducts() {
        try {
            RestRequest thisReq = RestContext.request;

            String recordTypeString;
            if(thisReq.params.containsKey('type')) {
                recordTypeString = thisReq.params.get('type');
            }
            else {
                throw new TypeException('"type" parameter not found.');
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

    public class ResponseBodyObject {
        public Boolean success;
        public List<ProductDataObject> products;
        public String message;

        private ResponseBodyObject(List<ProductDataObject> productList) {
            this.success = true;
            this.products = productList;
            this.message = null;
        }
        
        private ResponseBodyObject(String message) {
            this.success = false;
            this.products = null;
            this.message = message;
        }
    }

    private class ProductDataObject {
        String recordId;
        String name;
        String type;
        String description;
        String prodClass;
        String code;
        String sku;

        private ProductDataObject(Product2 prod) {
            this.recordId = prod.Id;
            this.name = prod.Name;
            this.type = prod.Type;
            this.description = prod.Description;
            this.prodClass = prod.ProductClass;
            this.code = prod.ProductCode;
            this.sku = prod.StockKeepingUnit;
        }
    }
}