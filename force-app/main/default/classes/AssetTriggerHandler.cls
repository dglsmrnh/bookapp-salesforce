/**
 * @description       : 
 * @author            : PredoVin
 * @group             : 
 * @last modified on  : 02-29-2024
 * @last modified by  : PredoVin
**/
public with sharing class AssetTriggerHandler extends TriggerHandler {
    public AssetTriggerHandler(System.TriggerOperation operation, List<Asset> newRecordList, List<Asset> oldRecordList, Map<Id, Asset> newMap, Map<Id, Asset> oldMap) {
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

    public override void beforeInsert() {
        AssetHelper.createExternalId(newRecordList);
    }

    public override void afterInsert(){
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