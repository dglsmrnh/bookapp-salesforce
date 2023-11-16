trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete) {
	System.debug('Trigger Operation => ' + Trigger.operationType);
    
    AccountTriggerHandler handler = new AccountTriggerHandler(
        Trigger.operationType, 
        Trigger.new, 
        Trigger.old, 
        Trigger.newMap, 
        Trigger.oldMap);
    
    if(AccountTriggerHandler.isTriggerEnabled()) {
        handler.execute();
    }
}