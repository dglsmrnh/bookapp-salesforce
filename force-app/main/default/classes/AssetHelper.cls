public with sharing class AssetHelper {
    public static void createExternalId(List<Asset> newRecordList) {
        Set<Id> accountIdSet = new Set<Id>();
        for(Asset asst : newRecordList) {
            accountIdSet.add(asst.AccountId);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Username__c FROM Account WHERE Id IN: accountIdSet]);
        for(Asset asst : newRecordList) {
            asst.ExternalId__c = (asst.Product2Id + accountMap.get(asst.AccountId).Username__c);
        }
    }
}