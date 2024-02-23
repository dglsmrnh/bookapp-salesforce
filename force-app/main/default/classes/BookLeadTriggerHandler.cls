/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-22-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class BookLeadTriggerHandler extends TriggerHandler{
    public BookLeadTriggerHandler(System.TriggerOperation operation, List<BookLead__c> newRecordList, List<BookLead__c> oldRecordList, Map<Id, BookLead__c> newMap, Map<Id, BookLead__c> oldMap) {
    	super(operation, newRecordList, oldRecordList, newMap, oldMap);
    }

		private static Boolean runTrigger = true;

		public static Boolean isTriggerEnabled(){
			return runTrigger;
		}

		public static Boolean enableTrigger(){
			return runTrigger = true;
		}

		public static Boolean disableTrigger(){
			return runTrigger = false;
		}

		public override void beforeInsert(){
		}

		public override void afterInsert(){
			BookLeadHelper.submitToApproval((List<BookLead__c>)newRecordList);
		}

		public override void beforeUpdate(){
			BookLeadHelper.changeOwner((Map<Id,BookLead__c>)oldMap, (Map<Id,BookLead__c>)newMap)
		}

		public override void afterUpdate(){
			BookLeadHelper.automaticReadingApproval((List<BookLead__c>)oldRecordList, (List<BookLead__c>)newRecordList);
			BookLeadHelper.automaticPublishApproval((List<BookLead__c>)oldRecordList, (List<BookLead__c>)newRecordList);
			BookLeadHelper.convertLead((Map<Id,BookLead__c>)oldMap, (Map<Id,BookLead__c>)newMap);
		}

		public override void beforeDelete(){

		}

		public override void afterDelete(){

		}
}