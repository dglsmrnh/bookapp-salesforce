trigger BookLeadTrigger on BookLead__c (before insert, after insert, before update, after update, before delete, after delete) {
	System.debug('Trigger Operation => ' + Trigger.operationType);
    
    BookLeadTriggerHandler handler = new BookLeadTriggerHandler(
        Trigger.operationType, 
        Trigger.new, 
        Trigger.old, 
        Trigger.newMap, 
        Trigger.oldMap);
    
    if(BookLeadTriggerHandler.isTriggerEnabled()) {
        handler.execute();
    }
}