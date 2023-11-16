@isTest
private class ClassIntegrationTest {

    @isTest
    static void testGetAvailableClasses() {
        Test.startTest();

        // Create test data (replace with your actual test data creation logic)
        Account testAccount = new Account(
            Name = 'Test Account',
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'TestProduct', IsActive = true, RecordTypeId = ClassIntegration.PRODUCT_RECORDTYPE);
        insert testProduct;

        // Call the REST endpoint
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/class';
        request.addParameter('username', 'testUsername');
        RestContext.request = request;

        String result = ClassIntegration.getAvailableClasses();

        // Deserialize the result and perform assertions (replace with your actual validation logic)
        ClassIntegration.GetResponse response = (ClassIntegration.GetResponse)JSON.deserialize(result, ClassIntegration.GetResponse.class);
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
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'TestProduct', IsActive = true, RecordTypeId = ClassIntegration.PRODUCT_RECORDTYPE);
        insert testProduct;

        // Construct the PostRequest object
        ClassIntegration.PostRequest postRequest = new ClassIntegration.PostRequest();
        postRequest.username = 'testUsername';
        postRequest.classId = String.valueOf(testProduct.Id);

        // Call the REST endpoint
        String result = ClassIntegration.saveClass(postRequest);

        // Deserialize the result and perform assertions (replace with your actual validation logic)
        ClassIntegration.PostResponse response = (ClassIntegration.PostResponse)JSON.deserialize(result, ClassIntegration.PostResponse.class);
        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.id);

        Test.stopTest();
    }
}
