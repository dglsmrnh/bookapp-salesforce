@isTest
public with sharing class ProductIntegrationTest {
    @TestSetup
    static void makeData() {
        List<Product2> prodList = new List<Product2>();

        for(RecordType recType : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Product2']) {
            System.debug('RecordType => ' + recType.Name);
            Product2 newProd = new Product2();        
            newProd.Name = 'newProd' + recType.Name;
            newProd.Type = Schema.Product2.Type.getDescribe().getPicklistValues()[0].getValue();
            newProd.Description = 'New Product' + recType.Name;
            newProd.ProductCode = 'Prod123' + recType.Name;
            newProd.StockKeepingUnit = 'SKU123' + recType.Name;
            newProd.RecordType = recType;
            newProd.IsActive = true;
            prodList.add(newProd);
        }
        Database.insert(prodList);

        System.debug('prodList => ' + prodList);
    }

    @isTest
    public static void testGetProducts() {
        for(RecordType recType : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Product2']) {
            RestRequest testReq = new RestRequest();
            testReq.params.put('type', recType.Name);
            RestContext.request = testReq;
            String prodResponse = ProductIntegration.getProducts();
        }

        RestRequest testReq = new RestRequest();
        testReq.params.put('type', 'UnkownTypeTotallyNotReal');
        RestContext.request = testReq;
        String prodResponse2 = ProductIntegration.getProducts();
    }
}