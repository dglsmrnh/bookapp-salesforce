/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class ClassIntegrationTest {
    
    @isTest
    static void testGetAvailableClasses() {
        Test.startTest();

        // Create test data (replace with your actual test data creation logic)
        Account testAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com',
            Username__c = 'testuser',
            Password__c = 'Password@123',
            Gender__c = 'Male',
            Birthday__c = Date.newInstance(2000, 1, 1)
        );
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'TestProduct', IsActive = true, RecordTypeId = ClassIntegration.PRODUCT_RECORDTYPE);
        insert testProduct;

        // Call the REST endpoint
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/class';
        request.addParameter('username', 'testuser');
        RestContext.request = request;

        ClassIntegration.GetResponse response = ClassIntegration.getAvailableClasses();

        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.classes);

        Test.stopTest();
    }

    @isTest
    static void testSaveClass() {
        Test.startTest();

        // Create test data (replace with your actual test data creation logic)
        Account testAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com',
            Username__c = 'testuser',
            Password__c = 'Password@123',
            Gender__c = 'Male',
            Birthday__c = Date.newInstance(2000, 1, 1)
        );
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'TestProduct', IsActive = true, RecordTypeId = ClassIntegration.PRODUCT_RECORDTYPE);
        insert testProduct;

        // Construct the PostRequest object
        ClassIntegration.PostRequest postRequest = new ClassIntegration.PostRequest();
        postRequest.username = 'testuser';
        postRequest.classId = String.valueOf(testProduct.Id);

        // Call the REST endpoint
        ClassIntegration.PostResponse response = ClassIntegration.saveClass(postRequest);

        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.id);

        Test.stopTest();
    }
}