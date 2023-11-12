public without sharing class AccountTriggerHandler extends TriggerHandler{
	public AccountTriggerHandler(System.TriggerOperation operation, List<Account> newRecordList, List<Account> oldRecordList, Map<Id, Account> newMap, Map<Id, Account> oldMap) {
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
    AccountHelper.createDefaultClass((Map<Id,Account>)newMap);
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