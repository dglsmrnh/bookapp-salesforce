/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
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
                    asset.ExternalId__c = productMap.get(className) + account.Username__c;

                    assetList.add(asset);
                }
            }
        }

        List<Account> accountList = new List<Account>();

        if(assetList.size() > 0) {
            insert assetList;

            for(Asset asset : assetList) {
                if(newMap.containsKey(asset.AccountId)) {
                    Account acc = newMap.get(asset.AccountId).clone(true, true, false, false);
                    acc.DefaultClass__c = asset.Id;
                    accountList.add(acc);
                }
            }
        }
        AccountTriggerHandler.disableTrigger();
        update accountList;
        AccountTriggerHandler.enableTrigger();
    }

    public static void createEmptyInventory(List<Account> newRecordList) {

        List<Inventory__c> inventoriesToInsert = new List<Inventory__c>();
        for(Account acc : newRecordList) {
            Inventory__c invent = new Inventory__c(
                Account__c = acc.Id,
                Coins__c = 10
            );
            inventoriesToInsert.add(invent);
        }
        String inventoriesStringified = JSON.serialize(inventoriesToInsert);

        insertInventories(inventoriesStringified);
    }

    @future
    public static void insertInventories(String inventoriesStringified) { //Future method only allows for primitive variables to be sent as parameters
        List<Inventory__c> inventoriesToInsert = (List<Inventory__c>)JSON.deserialize(inventoriesStringified, List<Inventory__c>.class);
        List<InventoryItem__c> itemsToInsert = new List<InventoryItem__c>();

        for(Inventory__c invent : inventoriesToInsert) {
            for(Potion__mdt pot : [SELECT Id, Color__c FROM Potion__mdt]) {
                InventoryItem__c newItem = new InventoryItem__c(
                    Color__c = pot.Color__c,
                    Quantity__c = 0,
                    Inventory__r = invent
                );
                itemsToInsert.add(newItem);
            }
        }

        insert(inventoriesToInsert);
        insert(itemsToInsert);
    }
}