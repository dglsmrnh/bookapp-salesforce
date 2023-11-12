@isTest
private class AccountHelperTest {

    @isTest
    static void testCreateDefaultClass() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Child',
            Username__c = 'testUsername',
            Password__c = 'Password@123'
        );
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Novato', IsActive = true, RecordTypeId = AccountHelper.PRODUCT_CLASS_RECORDTYPE);
        insert testProduct;

        // Set up trigger context
        Map<Id, Account> newMap = new Map<Id, Account>{ testAccount.Id => testAccount };

        // Call the helper method to test
        Test.startTest();
        AccountHelper.createDefaultClass(newMap);
        Test.stopTest();

        // Assertions or verifications based on your createDefaultClass logic
        // For example, check that the asset and default class fields are populated as expected
        List<Asset> assets = [SELECT Id, AccountId, RecordTypeId, Product2Id FROM Asset WHERE AccountId = :testAccount.Id];
        System.assertNotEquals(0, assets.size());      
    }
}
