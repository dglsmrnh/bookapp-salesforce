/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@RestResource(urlMapping='/product')
global with sharing class ProductIntegration {
    @HttpGet
    global static ResponseBodyObject getProducts() {
        try {
            RestRequest thisReq = RestContext.request;

            String recordTypeString;
            if(thisReq.params.containsKey('type')) {
                recordTypeString = thisReq.params.get('type');
            }
            else {
                throw new ProductException('"type" parameter not found.');
            }
            
            if([SELECT Id FROM RecordType WHERE Name =: recordTypeString].size() < 1) {
                throw new ProductException('Selected type not found.');
            }

            String fields = String.join(IntegrationUtils.getFields('Product2'), ', ');
            // String fieldsProduct = String.join(
            //     IntegrationUtils.addRelationshipObjectToFields(IntegrationUtils.getFields('Product2'), 'Product2'), 
            //     ','
            // );

            String query = 'SELECT ' + fields + ' FROM Product2 WHERE isActive = true AND RecordType.DeveloperName =: recordTypeString';
            List<Product2> productList = Database.query(query);

            ResponseBodyObject responseBody = new ResponseBodyObject(productList);
    
            if(productList.size() <= 0) {
                throw new ProductException('No records with the selected type were found.');
            }

            return responseBody;
        }
        catch(Exception e) {
            return new ResponseBodyObject(e.getMessage());
        }
    }

    global class ResponseBodyObject {
        global Boolean success;
        global List<Product2> products;
        global String message;

        global ResponseBodyObject(List<Product2> productList) {
            this.success = true;
            this.products = productList;
            this.message = null;
        }
        
        global ResponseBodyObject(String message) {
            this.success = false;
            this.message = message;
        }
    }

    private class ProductException extends Exception {
    }
}