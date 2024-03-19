public with sharing class AssetHelper {
    public static void createExternalId(List<Asset> newRecordList) {
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        for(Asset asst : newRecordList) {
            accountIdSet.add(asst.AccountId);
            productIdSet.add(asst.Product2Id);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Username__c FROM Account WHERE Id IN: accountIdSet]);
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Id IN: productIdSet]);
        
        for(Asset asst : newRecordList) {
            asst.ExternalId__c = (asst.Product2Id + accountMap.get(asst.AccountId).Username__c);
            asst.Name = productMap.get(asst.Product2Id).Name;
        }
    }
}