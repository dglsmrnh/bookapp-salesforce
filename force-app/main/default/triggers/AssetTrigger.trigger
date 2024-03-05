trigger AssetTrigger on Asset (before insert, after insert, before update, after update, before delete, after delete) {
	System.debug('Trigger Operation => ' + Trigger.operationType);
    
    AssetTriggerHandler handler = new AssetTriggerHandler(
        Trigger.operationType, 
        Trigger.new, 
        Trigger.old, 
        Trigger.newMap, 
        Trigger.oldMap);
    
    if(AssetTriggerHandler.isTriggerEnabled()) {
        handler.execute();
    }
}