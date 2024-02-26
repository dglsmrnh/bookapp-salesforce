/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class AccountIntegrationTest {

    @isTest
    static void testPostAccountWithCharacter() {
        // Create test data for request body
        AccountIntegration.PostRequestBody requestBody = new AccountIntegration.PostRequestBody();
        
        // Account data
        requestBody.account = new AccountIntegration.AccountDataObject();
        requestBody.account.name = 'Test Account';
        requestBody.account.email = 'test@example.com';
        requestBody.account.username = 'testuser';
        requestBody.account.password = 'Password@123';
        requestBody.account.gender = 'Male';
        requestBody.account.birthdate = Date.newInstance(2000, 1, 1);

        // Create test Product2 records
        List<Product2> productList = new List<Product2>{
            new Product2(
                Name = 'Class Product',
                ProductCode = 'TestClassProduct',
                RecordTypeId = AccountIntegration.PRODUCT_CLASS_RECORDTYPE
            ),
            new Product2(
                Name = 'Race Product',
                ProductCode = 'TestRaceProduct',
                RecordTypeId = AccountIntegration.PRODUCT_RACE_RECORDTYPE
            ),
            new Product2(
                Name = 'Color Product',
                ProductCode = 'TestColorProduct',
                RecordTypeId = AccountIntegration.PRODUCT_COLOR_RECORDTYPE
            )
        };
        insert productList;

        // Character data
        requestBody.character = new AccountIntegration.CharacterDataObject();
        requestBody.character.name = 'Test Character';
        requestBody.character.classId = productList[0].Id;
        requestBody.character.raceId = productList[1].Id;
        requestBody.character.colorId = productList[2].Id;

        // Perform the HTTP callout
        Test.startTest();
        AccountIntegration.PostResponseBodyObject response = AccountIntegration.postAccountWithCharacter(requestBody);
        Test.stopTest();

        // Add your assertions here
        System.assertNotEquals(null, response.id);
        System.assertEquals(true, response.success);
    }

    @isTest
    static void testGetAccountAndCharacter() {
        // Create test data for Account and related assets
        Account testAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com',
            Username__c = 'testuser',
            Password__c = 'Password@123',
            Gender__c = 'Male',
            Birthday__c = Date.newInstance(2000, 1, 1)
        );
        insert testAccount;

        // Create test Product2 records
        List<Product2> productList = new List<Product2>{
            new Product2(
                Name = 'Class Product',
                ProductCode = 'TestClassProduct',
                RecordTypeId = AccountIntegration.PRODUCT_CLASS_RECORDTYPE
            ),
            new Product2(
                Name = 'Race Product',
                ProductCode = 'TestRaceProduct',
                RecordTypeId = AccountIntegration.PRODUCT_RACE_RECORDTYPE
            ),
            new Product2(
                Name = 'Color Product',
                ProductCode = 'TestColorProduct',
                RecordTypeId = AccountIntegration.PRODUCT_COLOR_RECORDTYPE
            )
        };
        insert productList;

        // Create test Asset records related to the test account
        List<Asset> assetList = new List<Asset>{
            new Asset(
                AccountId = testAccount.Id,
                Name = 'Class Product',
                Product2Id = productList[0].Id, // Associate with Class Product
                RecordTypeId = AccountIntegration.ASSET_CLASS_RECORDTYPE,
                ExternalId__c = productList[0].Id + testAccount.Username__c
            ),
            new Asset(
                AccountId = testAccount.Id,
                Name = 'Race Product',
                Product2Id = productList[1].Id, // Associate with Race Product
                RecordTypeId = AccountIntegration.ASSET_RACE_RECORDTYPE,
                ExternalId__c = productList[1].Id + testAccount.Username__c
            ),
            new Asset(
                AccountId = testAccount.Id,
                Name = 'Color Product',
                Product2Id = productList[2].Id, // Associate with Color Product
                RecordTypeId = AccountIntegration.ASSET_COLOR_RECORDTYPE,
                ExternalId__c = productList[2].Id + testAccount.Username__c
            )
        };
        insert assetList;

        RestRequest testReq = new RestRequest();
        testReq.params.put('username', 'testuser');
        RestContext.request = testReq;

        // Perform the HTTP callout
        Test.startTest();
        AccountIntegration.GetResponseBodyObject response = AccountIntegration.getAccountAndCharacter();
        Test.stopTest();

        // Add your assertions here
        System.assertEquals(true, response.success);
        // Add more assertions as needed
    }
}
