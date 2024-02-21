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
			BookLeadHelper.createApprovalProcess((Map<Id,BookLead__c>)newMap);
		}

		public override void beforeUpdate(){

		}

		public override void afterUpdate(){

		}

		public override void beforeDelete(){

		}

		public override void afterDelete(){

		}
}