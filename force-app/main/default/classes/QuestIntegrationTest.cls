@isTest
private class QuestIntegrationTest {

    @isTest
    static void testGetQuests() {
        // Test data setup
        Account testAccount = new Account(
            Name = 'Test Account',
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(
            isActive = true,
            Name = 'Test Asset'
            // Add other required fields
        );
        insert testProduct;

        // Call the REST service
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/quests';
        request.httpMethod = 'GET';
        request.addParameter('username', 'testUsername');
        request.addParameter('recommendation', 'true');

        RestContext.request = request;
        String responseString = QuestIntegration.getAvailableQuests();
        Test.stopTest();

        // Deserialize the response
        QuestIntegration.GetResponse response = (QuestIntegration.GetResponse)JSON.deserialize(responseString, QuestIntegration.GetResponse.class);

        // Assertions
        System.assert(response != null, 'Response should not be null');
        System.assert(response.success, 'Success should be true');
        System.assert(response.quests != null, 'Quests should not be null');
        System.assertEquals(1, response.quests.size(), 'There should be one quest in the response');
        System.assertEquals(testProduct.Id, response.quests[0].id, 'The quest ID should match the test asset ID');
    }

    @isTest
    static void testCreateQuest() {
        // Test data setup
        Account testAccount = new Account(
            Name = 'Test Account',
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
            // Add other required fields
        );
        insert testProduct;

        // Call the REST service
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/quests';
        request.httpMethod = 'POST';

        QuestIntegration.PostRequest postRequest = new QuestIntegration.PostRequest();
        postRequest.username = 'testUsername';
        postRequest.id = testProduct.Id;

        request.requestBody = Blob.valueOf(JSON.serialize(postRequest));
        RestContext.request = request;

        String responseString = QuestIntegration.createQuest(postRequest);
        Test.stopTest();

        // Deserialize the response
        QuestIntegration.PostResponse response = (QuestIntegration.PostResponse)JSON.deserialize(responseString, QuestIntegration.PostResponse.class);

        // Assertions
        System.assert(response != null, 'Response should not be null');
        System.assert(response.success, 'Success should be true');
        // Add more assertions based on the expected response
    }

    @isTest
    static void testUpdateQuest() {
        // Test data setup
        Account testAccount = new Account(
            Name = 'Test Account',
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId()
            // Add other required fields
        );
        insert testProduct;

        Asset testAsset = new Asset(
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id,
            CurrentChapter__c = 1,
            CurrentPage__c = 5,
            Name = 'Test Product',
            RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Book').getRecordTypeId()
            // Add other required fields
        );
        insert testAsset;

        BookCheckpoint__c testBookCheckpoint = new BookCheckpoint__c(
            Book__c = testProduct.Id,
            Chapter__c = 2,
            Page__c = 5            
            // Add other required fields
        );
        insert testBookCheckpoint;

        // Call the REST service
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/quests';
        request.httpMethod = 'PATCH';

        QuestIntegration.PatchRequest patchRequest = new QuestIntegration.PatchRequest();
        patchRequest.username = 'testUsername';
        patchRequest.id = testAsset.Id;
        patchRequest.currentChapter = 2;

        request.requestBody = Blob.valueOf(JSON.serialize(patchRequest));
        RestContext.request = request;

        String responseString = QuestIntegration.updateQuest(patchRequest);
        Test.stopTest();

        // Deserialize the response
        QuestIntegration.PatchResponse response = (QuestIntegration.PatchResponse)JSON.deserialize(responseString, QuestIntegration.PatchResponse.class);

        // Assertions
        System.assert(response != null, 'Response should not be null');
        System.assert(response.success, 'Success should be true');
        // Add more assertions based on the expected response
    }
}
