/**
 * @description       : 
 * @author            : dglrmnh
 * @group             : 
 * @last modified on  : 02-22-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class BookLeadHelper {

	public static void changeOwner(Map<Id, BookLead__c> oldMap, Map<Id, BookLead__c> newMap) {

		for(BookLead__c bk: newMap.values()) {
			if(bk.ReadingApproved__c = true && bk.Status__c == 'Working' && oldMap.get(bk.Id).Status__c != 'Working') {
				bk.OwnerId = UserInfo.getUserId();
			}
		}		
	}

	public static void convertLead(List<BookLead__c> newRecordList) {
		Set<Id> productIdList = new Set<Id>();
		List<Product2> productList = new List<Product2>();

		for(BookLead__c bk : newRecordList) {
			if(bk.PublishApproved__c == true && bk.isAvailableToPublish__c == true) {
                if(bk.Book__c != null) {
				    productIdList.add(bk.Book__c);
                }
			}
		}

		for(Id productId: productIdList) {
			productList.add(new Product2(Id = productId, IsActive = true));
		}
        
        if(!productList.isEmpty()) {
            update productList;
        }
	}

    public static void submitToApproval(List<BookLead__c> newRecordList) {
		Set<Id> setGpOrUserId = new Set<Id>();

		for (User us : [SELECT Id, Name, IsActive FROM User WHERE Profile.Name IN ('Curador', 'System Administrator', 'Administrador do Sistema')]) {
			if (!us.isActive) {
				setGpOrUserId.add(us.Id);
			}
		}

		List<Approval.ProcessSubmitRequest> listReq = new List<Approval.ProcessSubmitRequest>();

		for (BookLead__c bk : newRecordList) {
			for (Id usId : setGpOrUserId) {
				listReq.add(getProcessRequest(bk, usId));
			}
		}

		if (!listReq.isEmpty()) {
			if(!Test.isRunningTest()) {
				BookLeadTriggerHandler.disableTrigger();
				List<Approval.ProcessResult> listResult = Approval.process(listReq);
				BookLeadTriggerHandler.enableTrigger();
			}
		}        
    }    

    public static void automaticReadingApproval(List<BookLead__c> oldRecordList, List<BookLead__c> newRecordList) {
        
        Set<Id> setApprovedId = new Set<Id>();
        Set<Id> setReprovedId = new Set<Id>();

        for(BookLead__c bk : newRecordList) {
            if(bk.ReadingApproved__c == true) {
                setApprovedId.add(bk.Id);
            }
            else if(bk.Status__c == 'Closed - Not Converted') {
                setReprovedId.add(bk.Id);
            }
        }

        automaticApproval(setApprovedId, setReprovedId, 'ReadingApproval');
    }

    public static void automaticPublishApproval(List<BookLead__c> oldRecordList, List<BookLead__c> newRecordList) {
        
        Set<Id> setApprovedId = new Set<Id>();
        Set<Id> setReprovedId = new Set<Id>();

        for(BookLead__c bk : newRecordList) {
            if(bk.PublishApproved__c == true) {
                setApprovedId.add(bk.Id);
            }
            else if(bk.Status__c == 'Closed - Not Converted') {
                setReprovedId.add(bk.Id);
            }
        }

        automaticApproval(setApprovedId, setReprovedId, 'PublishApproval');
    }

    public static void automaticApproval(Set<Id> setApprovedId, Set<Id> setReprovedId, String processDeveloperName) {
        
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        
        Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE Status = 'Pending' AND ProcessDefinition.DeveloperName =: processDeveloperName AND (TargetObjectId IN: setApprovedId OR TargetObjectId IN: setReprovedId)]);

        for(ProcessInstanceWorkItem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet()]){
            if(workItem.ActorId != UserInfo.getUserId()) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (!setApprovedId.isEmpty()) {
                    if (setApprovedId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                        req.setAction('Approve');
                    }
                }
                if (!setReprovedId.isEmpty()) {
                    if (setReprovedId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                        req.setAction('Reject');
                    }
                }
                req.setWorkitemId(workItem.Id);
                requests.add(req);
            }
        }
        BookLeadTriggerHandler.disableTrigger();
        if(!Test.isRunningTest()) {
            Approval.ProcessResult[] processResults = Approval.process(requests, true);
        }
        BookLeadTriggerHandler.enableTrigger();
    }

    public static Approval.ProcessSubmitRequest getProcessRequest(BookLead__c bk, Id userId) {
        String approvalFlow = 'ReadingApproval';

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Aprovação inicial após verificação do score e das informações do livro.');
        req.setObjectId(bk.Id);
        req.setProcessDefinitionNameOrId(approvalFlow);
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }
}