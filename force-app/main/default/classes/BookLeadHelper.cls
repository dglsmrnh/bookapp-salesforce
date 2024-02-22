/**
 * @description       : 
 * @author            : dglrmnh
 * @group             : 
 * @last modified on  : 02-22-2024
 * @last modified by  : douglas.marinho@globant.com
**/
public with sharing class BookLeadHelper {

	public static void changeOwner(Map<Id, BookLead__c> oldMap, Map<Id, BookLead__c> newMap) {

		for(BookLead__c bk: newMap) {
			if(bk.Status__c == 'Working' && oldMap.get(bk.Id).Status__c == 'Open') {
				bk.Owner = UserInfo.getUserId();
			}
		}		
	}

	public static void convertLead(Map<Id, BookLead__c> oldMap, Map<Id, BookLead__c> newMap) {
		Set<Id> productIdList = new Set<Id>();
		List<Product2> productList = new List<Product2>();

		for(BookLead__c bk: newMap) {
			if(bk.Status__c == 'Closed - Converted' && bk.isAvailableToPublish__c = true) {
				productIdList.add(bk.Book__c);
			}
		}

		for(Id productId: productIdList) {
			productList.add(new Product2(Id = productId, IsActive = true));
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
        
        if(!setReprovedContractId.isEmpty() || !setApprovedContractId.isEmpty()) {
            // aprova / reprova os outros processos de aprovação quando necessário
            automaticApproval(setApprovedContractId, setReprovedContractId);
        }
    }    

    public static void automaticApproval(Set<Id> setApprovedContractId, Set<Id> setReprovedContractId) {
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        
        Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE Status = 'Pending' AND (TargetObjectId IN: setApprovedContractId OR TargetObjectId IN: setReprovedContractId)]);

        for(ProcessInstanceWorkItem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet()]){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            if (!setApprovedContractId.isEmpty()) {
                if (setApprovedContractId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                    req.setAction('Approve');
                }
            }
            if (!setReprovedContractId.isEmpty()) {
                if (setReprovedContractId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                    req.setAction('Reject');
                }
            }
            req.setWorkitemId(workItem.Id);
            requests.add(req);
        }
        List<ItemContrato__c> listContractItems = new List<ItemContrato__c>();

        for(Id id : setApprovedContractId) {
            listContractItems.add(new ItemContrato__c(Id = id, isApprovalProcess__c = false));
        }

        for(Id id : setReprovedContractId) {
            listContractItems.add(new ItemContrato__c(Id = id, isApprovalProcess__c = false));
        }

        system.debug('requests: ' + requests);
        ContractItemHandler.disableTrigger();
        if(!Test.isRunningTest()) {
            Approval.ProcessResult[] processResults = Approval.process(requests, true);
        }
        update listContractItems;
        ContractItemHandler.enableTrigger();
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