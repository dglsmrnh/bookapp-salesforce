/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-24-2024
 * @last modified by  : dglsmrnh
**/
public without sharing class AccountHelper {
    
    public static final Id PRODUCT_CLASS_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    public static final Id ASSET_CLASS_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Class').getRecordTypeId();

    public static void createDefaultClass(Map<Id, Account> newMap) {
        Map<String, String> classMap = new Map<String, String>();
        for(Account account : newMap.values()) {
            if(String.isEmpty(account.Type)) {
                account.Type = 'Child';
            }
            InitialClass__mdt initialClass = InitialClass__mdt.getInstance(account.Type);
            classMap.put(account.Type, initialClass.MasterLabel);            
        }

        List<Product2> productList = [SELECT Id, Name FROM Product2 WHERE Name IN: classMap.values() AND RecordTypeId =: PRODUCT_CLASS_RECORDTYPE];
        Map<String, Id> productMap = new Map<String, Id>();
        for(Product2 product : productList) {
            productMap.put(product.Name, product.Id);
        }

        List<Asset> assetList = new List<Asset>();
        for(Account account : newMap.values()) {
            if(classMap.containsKey(account.Type)) {
                String className = classMap.get(account.Type);
                if(productMap.containsKey(className)) {
                    Asset asset = new Asset();
                    asset.AccountId = account.Id;
                    asset.RecordTypeId = ASSET_CLASS_RECORDTYPE;
                    asset.Product2Id = productMap.get(className);
                    asset.Name = className;

                    assetList.add(asset);
                }
            }
        }

        List<Account> accountList = new List<Account>();

        if(assetList.size() > 0) {
            insert assetList;

            for(Asset asset : assetList) {
                if(newMap.containsKey(asset.AccountId)) {
                    Account acc = newMap.get(asset.AccountId);
                    acc.DefaultClass__c = asset.Id;
                    accountList.add(acc);
                }
            }
        }
        AccountTriggerHandler.disableTrigger();
        update accountList;
        AccountTriggerHandler.enableTrigger();
    }
}