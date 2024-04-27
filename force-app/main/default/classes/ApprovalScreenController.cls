/**
 * @description       : 
 * @author            : douglas.marinho@globant.com
 * @group             : 
 * @last modified on  : 03-13-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class ApprovalScreenController {

	public static final Map<String, SObjectType> MAP_SOBJECTS = Schema.getGlobalDescribe();

	public static String getSObjectLabel(String apiName) {
		return MAP_SOBJECTS.get(apiName).getDescribe().getLabel();
	}

	@AuraEnabled
	public static ComponentData getComponentData() {
		ComponentData component = new ComponentData();

		try {
			Map<String, RecordData> recordDataMap = fillBaseRecordData();
			List<PicklistData> sobjectNameOptionList = new List<PicklistData>();
			List<PicklistData> statusOptionList = new List<PicklistData>();
			List<PicklistData> processNameOptionList = new List<PicklistData>();

			fillAllPicklistData(sobjectNameOptionList, statusOptionList, processNameOptionList);

			component = new ComponentData(recordDataMap, sobjectNameOptionList, statusOptionList, processNameOptionList);
		}
		catch (Exception ex) {
			System.debug('Exception Get Component Data => ' + ex.getMessage());
			System.debug('Stack Trace ' + ex.getStackTraceString());
			component = new ComponentData(ex);
		}

		return component;
	}

	public static Map<String, RecordData> fillBaseRecordData() {
		Map<String, RecordData> recordDataMap = new Map<String, RecordData>();
		Map<Id, Id> processIdToWorkitemIdMap = new Map<Id, Id>();

		String query = getBaseProcessInstanceWorkitemQuery();
		String groupIds = fillGroupIds();
		String conditions = String.isBlank(groupIds) ? ' ActorId = \'' + UserInfo.getUserId() + '\''
			: ' (ActorId = \'' + UserInfo.getUserId() + '\'' + ' OR ActorId IN (' + groupIds + ') )';

		query = query.replace('#WHERE#', ' WHERE ' + conditions);
		query += ' LIMIT 30';

		for (ProcessInstanceWorkitem retrievedWorkitem : Database.query(query)) {
			recordDataMap.put(retrievedWorkitem.Id, new RecordData(retrievedWorkitem));
			processIdToWorkitemIdMap.put(retrievedWorkitem.ProcessInstanceId, retrievedWorkitem.Id);
		}

		for (ProcessInstanceStep retrievedStep : getProcessInstanceStepsByProcessIds(processIdToWorkitemIdMap.keySet())) {
			Id workitemId = processIdToWorkitemIdMap.get(retrievedStep.ProcessInstanceId);
			RecordData record = recordDataMap.get(workitemId);
			record.comment = retrievedStep.Comments;
		}

		return recordDataMap;
	}

	public static void fillAllPicklistData(
		List<PicklistData> sobjectNameOptionList,
		List<PicklistData> statusOptionList,
		List<PicklistData> processNameOptionList
	) {
		Set<String> sobjectDeveloperNameList = new Set<String>();

		for (AggregateResult retrievedSObject : getWorkitemSObjectsName()) {
			String name = (String)retrievedSObject.get('Name');
			processNameOptionList.add(new PicklistData(name, name));

			sobjectDeveloperNameList.add((String)retrievedSObject.get('TableEnumOrId'));
		}

		for (Schema.DescribeSObjectResult retrievedSObjectDescribe : Schema.describeSObjects(new List<String>(sobjectDeveloperNameList))) {
			sobjectNameOptionList.add(new PicklistData(
				retrievedSObjectDescribe.getLabel(),
				retrievedSObjectDescribe.getName()
			));
		}

		Schema.DescribeFieldResult fieldDetail = ProcessInstance.Fields.Status.getDescribe();
		for (Schema.PicklistEntry retrievedValue : fieldDetail.getPicklistValues()) {
			if (retrievedValue.isActive()) {
				statusOptionList.add(new PicklistData(
					retrievedValue.getLabel(),
					retrievedValue.getValue()
				));
			}
		}
	}

	@AuraEnabled
	public static Map<String, RecordData> searchProcesses(FilterData filter, Integer workitemSize) {
		Map<String, RecordData> recordDataMap = new Map<String, RecordData>();

		try {
			Map<Id, Id> processIdToWorkitemIdMap = new Map<Id, Id>();
			String query = getBaseProcessInstanceWorkitemQuery();
			String conditions = fillConditions(filter);

			query = query.replace('#WHERE#', ' WHERE ' + conditions + ' ');

			if (workitemSize <= 0) query += ' LIMIT 30 ';
			else {
				Integer newSize = workitemSize + 30;
				query += ' LIMIT ' + String.valueOf(newSize > 50000 ? 50000 : newSize);
			}

			for (ProcessInstanceWorkitem retrievedWorkitem : Database.query(query)) {
				recordDataMap.put(retrievedWorkitem.Id, new RecordData(retrievedWorkitem));
				processIdToWorkitemIdMap.put(retrievedWorkitem.ProcessInstanceId, retrievedWorkitem.Id);
			}

			for (ProcessInstanceStep retrievedStep : getProcessInstanceStepsByProcessIds(processIdToWorkitemIdMap.keySet())) {
				Id workitemId = processIdToWorkitemIdMap.get(retrievedStep.ProcessInstanceId);
				RecordData record = recordDataMap.get(workitemId);
				record.comment = retrievedStep.Comments;
			}
		}
		catch(Exception ex) {
			System.debug('Exception Search Process => ' + ex.getMessage());
			System.debug('Stack Trace => ' + ex.getStackTraceString());
		}

		return recordDataMap;
	}

	public static String fillConditions(FilterData filter) {
		String groupIds = fillGroupIds();
		String conditions = '';
		
		String pi = getProcessInstanceIds(filter);
		if (!String.isBlank(pi)) {
			conditions += ' ProcessInstanceId IN (' + pi + ') ';
		}
		if (!String.isBlank(filter.approverName)) {
			if (!String.isBlank(conditions)) conditions += ' AND ';
			conditions += ' Actor.Name LIKE \'%' + String.escapeSingleQuotes(filter.approverName) + '%\' ';
		}

		String operation = String.isBlank(conditions) ? '' : ' AND ';
		conditions += String.isBlank(groupIds) ? operation + ' ActorId = \'' + UserInfo.getUserId() + '\''
			: operation + ' (ActorId = \'' + UserInfo.getUserId() + '\'' + ' OR ActorId IN (' + groupIds + ') )';

		return conditions;
	}

	public static String getProcessInstanceIds(FilterData filter) {
		String query = 'SELECT Id FROM ProcessInstance WHERE';
		String conditions = '';
		List<String> processInstanceIds = new List<String>();
		String pd = getProcessDefinitionIds(filter);
		if (!String.isBlank(pd)) {
			conditions += ' ProcessDefinitionId IN (' + pd + ') ';
		}
		if (filter.statusSelectedList != null && !filter.statusSelectedList.isEmpty()) {
			if (!String.isBlank(conditions)) conditions += ' AND ';
			conditions += ' Status IN (' + convertListInString(filter.statusSelectedList) + ') ';
		}
		String sb = getSubmitterIds(filter);
		if (!String.isBlank(sb)) {
			if (!String.isBlank(conditions)) conditions += ' AND ';
			conditions += ' SubmittedById IN (' + sb + ') ';
		}

		if(!String.isBlank(conditions)) {
			conditions += ' LIMIT 50000 ';
			List<ProcessInstance> processInstanceList = Database.query(query + conditions);

			for(ProcessInstance pi : processInstanceList) {
				processInstanceIds.add(pi.Id);
			}

			if(!processInstanceIds.isEmpty()) {
				return convertListInString(processInstanceIds);
			}
		}

		return '';
	}

	public static String getProcessDefinitionIds(FilterData filter) {
		String query = 'SELECT Id FROM ProcessDefinition WHERE';
		String conditions = '';
		List<String> processDefinitionIds = new List<String>();

		if (filter.objectSelectedList != null && !filter.objectSelectedList.isEmpty()) {
			conditions += ' TableEnumOrId IN (' + convertListInString(filter.objectSelectedList) + ') ';
		}
		if (filter.processSelectedList != null && !filter.processSelectedList.isEmpty()) {
			if (!String.isBlank(conditions)) conditions += ' AND ';
			conditions += ' Name IN (' + convertListInString(filter.processSelectedList) + ') ';
		}

		if(!String.isBlank(conditions)) {
			List<ProcessDefinition> processDefinitionList = Database.query(query + conditions);

			for(ProcessDefinition pd : processDefinitionList) {
				processDefinitionIds.add(pd.Id);
			}

			if(!processDefinitionIds.isEmpty()) {
				return convertListInString(processDefinitionIds);
			}
		}

		return '';
	}

	public static String getSubmitterIds(FilterData filter) {
		String query = 'SELECT Id FROM User WHERE';
		String conditions = '';
		List<String> submitterIds = new List<String>();

		if (!String.isBlank(filter.submitterName)) {
			conditions += ' Name LIKE \'%' + String.escapeSingleQuotes(filter.submitterName) + '%\' ';
		}

		if(!String.isBlank(conditions)) {
			List<User> submitterList = Database.query(query + conditions);

			for(User pd : submitterList) {
				submitterIds.add(pd.Id);
			}

			if(!submitterIds.isEmpty()) {
				return convertListInString(submitterIds);
			}
		}

		return '';
	}

	public static String convertListInString(List<String> stringList) {
		String response = '';

		for (String retrievedString : stringList) {
			if (!String.isBlank(response)) response += ' , ';

			response += ' \'' + String.escapeSingleQuotes(retrievedString) + '\' ';
		}

		return response;
	}

	@AuraEnabled
	public static List<ApprovalResponse> approvalRecords(Map<String, RecordData> recordDataMap, Boolean isApproval) {
		List<ApprovalResponse> responseList = new List<ApprovalResponse>();

		try {
			List<Approval.ProcessWorkitemRequest> workitemList = new List<Approval.ProcessWorkitemRequest>();
			Map<Id, Id> recordIdToworkitemIdMap = new Map<Id, Id>();
			Map<Id, String> workitemIdToCommentMap = new Map<Id, String>();

			for (ProcessInstanceWorkitem retrievedWorkitem : getProcessInstanceWorkitemBySObjectIds(recordDataMap.keySet())) {
				Approval.ProcessWorkitemRequest currentWorkitem = new Approval.ProcessWorkitemRequest();
				RecordData currentRecordData = recordDataMap.get(retrievedWorkitem.Id);
				String standardComment = (isApproval ? 'Approved' : 'Rejected') + ' by Approval Screen.';

				currentWorkitem.setComments(String.isBlank(currentRecordData.approvalComment) ? standardComment : currentRecordData.approvalComment);
				currentWorkitem.setWorkitemId(retrievedWorkitem.Id);
				currentWorkitem.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
				currentWorkitem.setAction(isApproval ? 'Approve' : 'Reject');

				workitemList.add(currentWorkitem);

				recordIdToworkitemIdMap.put(retrievedWorkitem.ProcessInstance.TargetObjectId, retrievedWorkitem.Id);
			}

			if (!workitemList.isEmpty()) {
				for (Approval.ProcessResult result : Approval.process(workitemList, false)) {
					Boolean isSuccess = result.isSuccess();
					Id recordId = recordIdToworkitemIdMap.get((Id)result.getEntityId());

					responseList.add(new ApprovalResponse(
						isSuccess ? recordId : result.getErrors()[0].getMessage(),
						isSuccess
					));
				}
			}
		}
		catch (Exception ex) {
			System.debug('Exception Approval Records => ' + ex.getMessage());
			System.debug('Stack Trace => ' + ex.getStackTraceString());
			responseList.add(new ApprovalResponse(ex));
		}

		return responseList;
	}

	@AuraEnabled
	public static List<RecordData> checkProcessHistory(String recordId) {
		List<RecordData> recordDataList = new  List<RecordData>();
		List<ProcessInstance> processList = new List<ProcessInstance>();
		Map<Id, String> stepIdToStepNameMap = new Map<Id, String>();

		for (ProcessNode retrievedNode : [SELECT Id, Name FROM ProcessNode]) {
			stepIdToStepNameMap.put(retrievedNode.Id, retrievedNode.Name);
		}

		for (ProcessInstance retrievedInstance : getProcessesByRecordId(recordId)) {
			System.debug('retrievedInstance => ' + retrievedInstance);
			for (ProcessInstanceHistory retrievedHistory : retrievedInstance.StepsAndWorkitems) {
				RecordData newRecordData = new RecordData(retrievedHistory);

				if (String.isBlank(retrievedHistory.ProcessNodeId) && retrievedHistory.StepStatus == 'Started') {
					newRecordData.stepName = 'Approval Request Submitted';
				}
				else newRecordData.stepName = stepIdToStepNameMap.get(retrievedHistory.ProcessNodeId);

				recordDataList.add(newRecordData);
			}

			for (ProcessInstanceStep retreivedStep : retrievedInstance.Steps) {
				RecordData newRecordData = new RecordData(retreivedStep);

				if (String.isBlank(retreivedStep.StepNodeId) && retreivedStep.StepStatus == 'Started') {
					newRecordData.stepName = 'Approval Request Submitted';
				}
				else newRecordData.stepName = stepIdToStepNameMap.get(retreivedStep.StepNodeId);

				recordDataList.add(newRecordData);
			}
		}

		return recordDataList;
	}

	public static List<ProcessInstance> getProcessesByRecordId(String recordId) {
		return [
			SELECT Id,
				   Status,
				   CompletedDate,
				   ProcessDefinitionId,
				   ProcessDefinition.Name,
				   ProcessDefinition.TableEnumOrId,
				   TargetObjectId,
				   TargetObject.Name,
				   SubmittedById,
				   SubmittedBy.Name,
				   (
					SELECT Id,
						   StepStatus,
						   Comments,
						   CreatedDate,
						   Actor.Name,
						   OriginalActor.Name,
						   ProcessInstance.TargetObjectId,
						   ProcessInstanceId,
						   ProcessInstance.Status,
						   ProcessInstance.ProcessDefinition.Name,
						   ProcessInstance.ProcessDefinition.TableEnumOrId,
						   ProcessInstance.TargetObject.Name,
						   ProcessInstance.SubmittedBy.Name,
						   ProcessNodeId
					  FROM StepsAndWorkitems
					 WHERE IsPending = true
					 ORDER BY CreatedDate DESC
				   ),
				   (
					SELECT Id,
						   StepStatus,
						   Comments,
						   CreatedDate,
						   Actor.Name,
						   OriginalActor.Name,
						   ProcessInstance.TargetObjectId,
						   ProcessInstanceId,
						   ProcessInstance.Status,
						   ProcessInstance.ProcessDefinition.Name,
						   ProcessInstance.ProcessDefinition.TableEnumOrId,
						   ProcessInstance.TargetObject.Name,
						   ProcessInstance.SubmittedBy.Name,
						   StepNodeId
					  FROM Steps
					 ORDER BY CreatedDate DESC
				   )
			  FROM ProcessInstance
			 WHERE ProcessInstance.TargetObjectId = :recordId
			 ORDER BY CreatedDate DESC
		];
	}

	public static List<ProcessInstanceWorkitem> getProcessInstanceWorkitemBySObjectIds(Set<String> workitemIdSet) {
		return [
			SELECT Id,
				   ProcessInstanceId,
				   ProcessInstance.TargetObjectId
			  FROM ProcessInstanceWorkitem
			 WHERE Id IN :workitemIdSet
		];
	}

	public static List<AggregateResult> getWorkitemSObjectsName() {
		return [
			SELECT ProcessInstance.ProcessDefinition.TableEnumOrId,
				   ProcessInstance.ProcessDefinition.Name
			  FROM ProcessInstanceWorkitem
			 GROUP BY ProcessInstance.ProcessDefinition.TableEnumOrId,
					  ProcessInstance.ProcessDefinition.Name
		];
	}

	public static List<ProcessInstanceStep> getProcessInstanceStepsByProcessIds(set<Id> processInstanceIdSet) {
		return [
			SELECT Id,
				   Comments,
				   ProcessInstanceId
			  FROM ProcessInstanceStep
			 WHERE ProcessInstanceId IN :processInstanceIdSet
			   AND Comments <> NULL
		];
	}

	public static String getBaseProcessInstanceWorkitemQuery() {
		return '' +
			' SELECT Id, ' +
			'		 CreatedDate, ' +
			'		 Actor.Name, ' +
			'		 OriginalActor.Name, ' +
			'		 ProcessInstanceId, ' +
			'		 ProcessInstance.Status, ' +
			'		 ProcessInstance.ProcessDefinitionId, ' +
			'		 ProcessInstance.ProcessDefinition.Name, ' +
			'		 ProcessInstance.ProcessDefinition.TableEnumOrId, ' +
			'		 ProcessInstance.TargetObjectId, ' +
			'		 ProcessInstance.TargetObject.Name, ' +
			'		 ProcessInstance.SubmittedBy.Name ' +
			'	FROM ProcessInstanceWorkitem ' +
			' #WHERE# ' +
			'  ORDER BY CreatedDate DESC, ProcessInstance.ProcessDefinition.TableEnumOrId, ' +
			'			ProcessInstance.Status, ' +
			'			ProcessInstance.TargetObject.Name ';
	}

	public static String fillGroupIds() {
		String groupIds = '';

		Set<Id> queueIdSet = new Set<Id>();

		for (GroupMember retrievedMember : [
			SELECT Id,
				   GroupId
			  FROM GroupMember
			 WHERE UserOrGroupId = :UserInfo.getUserId()
			   AND Group.Type = 'Queue'
			 LIMIT 50000
		]) {
			if (!String.isBlank(groupIds)) groupIds += ', ';
			groupIds += '\'' + retrievedMember.GroupId + '\'';
		}

		return groupIds;
	}

	public class CustomException extends Exception {}

	public virtual class Response {
		@AuraEnabled
		public Boolean hasError = false;
		@AuraEnabled
		public String errorMessage = '';
		@AuraEnabled
		public String exceptionMessage = '';

		public Response() {}
		public Response(String errorMessage) {
			this.hasError = true;
			this.errorMessage = errorMessage;
		}
		public Response(Exception ex) {
			this.hasError = true;
			this.errorMessage = ex.getMessage();
		}
	}

	public class ApprovalResponse extends Response {
		@AuraEnabled
		public Boolean isSuccess = false;
		@AuraEnabled
		public String id = '';

		public ApprovalResponse(String errorMessage, Boolean isSuccess) {
			super(errorMessage);
		}
		public ApprovalResponse(Exception ex) {
			super(ex);
		}
		public ApprovalResponse(Id id, Boolean isSuccess) {
			this.id = id;
			this.isSuccess = isSuccess;
		}
	}

	public class FilterData {
		@AuraEnabled
		public List<String> objectSelectedList {get; set;}
		@AuraEnabled
		public List<String> statusSelectedList {get; set;}
		@AuraEnabled
		public List<String> processSelectedList {get; set;}
		@AuraEnabled
		public String approverName {get; set;}
		@AuraEnabled
		public String submitterName {get; set;}

		public FilterData() {}
	}

	public class RecordData {
		@AuraEnabled
		public String id {get; set;}
		@AuraEnabled
		public String recordId {get; set;}
		@AuraEnabled
		public String processId {get; set;}
		@AuraEnabled
		public String processName {get; set;}
		@AuraEnabled
		public String stepName {get; set;}
		@AuraEnabled
		public String sobjectType {get; set;}
		@AuraEnabled
		public String sobjectName {get; set;}
		@AuraEnabled
		public String sobjectLabel {get; set;}
		@AuraEnabled
		public String status {get; set;}
		@AuraEnabled
		public String statusLabel {get; set;}
		@AuraEnabled
		public String submitterName {get; set;}
		@AuraEnabled
		public String actorName {get; set;}
		@AuraEnabled
		public String originalActorName {get; set;}
		@AuraEnabled
		public String createdDate {get; set;}
		@AuraEnabled
		public String comment {get; set;}
		@AuraEnabled
		public String approvalComment {get; set;}
		@AuraEnabled
		public Boolean isSelected {get; set;}

		public RecordData() {}
		public RecordData(ProcessInstanceWorkitem currentWorkitem) {
			this.id = currentWorkitem.Id;
			this.recordId = currentWorkitem.ProcessInstance.TargetObjectId;
			this.processId = currentWorkitem.ProcessInstanceId;
			this.processName = currentWorkitem.ProcessInstance.ProcessDefinition.Name;
			this.stepName = '';
			this.sobjectType = currentWorkitem.ProcessInstance.ProcessDefinition.TableEnumOrId;
			this.sobjectName = currentWorkitem.ProcessInstance.TargetObject.Name;
			this.sobjectLabel = getSObjectLabel(currentWorkitem.ProcessInstance.ProcessDefinition.TableEnumOrId);
			this.status = currentWorkitem.ProcessInstance.Status;
			this.statusLabel = getPicklistValue(currentWorkitem.ProcessInstance.Status);
			this.submitterName = currentWorkitem.ProcessInstance.SubmittedBy.Name;
			this.actorName = currentWorkitem.Actor.Name;
			this.originalActorName = currentWorkitem.OriginalActor.Name;
			this.createdDate = currentWorkitem.CreatedDate.format('yyyy-MM-dd HH:mm',  UserInfo.getTimeZone().toString());
			this.comment = 'No comments';
			this.approvalComment = '';
			this.isSelected = false;
		}
		public RecordData(ProcessInstanceHistory currentInstance) {
			this.id = currentInstance.Id;
			this.recordId = currentInstance.ProcessInstance.TargetObjectId;
			this.processId = currentInstance.ProcessInstanceId;
			this.processName = currentInstance.ProcessInstance.ProcessDefinition.Name;
			this.stepName = '';
			this.sobjectType = currentInstance.ProcessInstance.ProcessDefinition.TableEnumOrId;
			this.sobjectName = currentInstance.ProcessInstance.TargetObject.Name;
			this.sobjectLabel = getSObjectLabel(currentInstance.ProcessInstance.ProcessDefinition.TableEnumOrId);
			this.status = currentInstance.StepStatus;
			this.statusLabel = getPicklistValue(currentInstance.StepStatus);
			this.submitterName = currentInstance.ProcessInstance.SubmittedBy.Name;
			this.actorName = currentInstance.Actor.Name;
			this.originalActorName = currentInstance.OriginalActor.Name;
			this.createdDate = currentInstance.CreatedDate.format('yyyy-MM-dd HH:mm',  UserInfo.getTimeZone().toString());
			this.comment = currentInstance.Comments;
			this.approvalComment = currentInstance.Comments;
			this.isSelected = false;
		}
		public RecordData(ProcessInstanceStep currentStep) {
			this.id = currentStep.Id;
			this.recordId = currentStep.ProcessInstance.TargetObjectId;
			this.processId = currentStep.ProcessInstanceId;
			this.processName = currentStep.ProcessInstance.ProcessDefinition.Name;
			this.stepName = '';
			this.sobjectType = currentStep.ProcessInstance.ProcessDefinition.TableEnumOrId;
			this.sobjectName = currentStep.ProcessInstance.TargetObject.Name;
			this.sobjectLabel = getSObjectLabel(currentStep.ProcessInstance.ProcessDefinition.TableEnumOrId);
			this.status = currentStep.StepStatus;
			this.statusLabel = getPicklistValue(currentStep.StepStatus);
			this.submitterName = currentStep.ProcessInstance.SubmittedBy.Name;
			this.actorName = currentStep.Actor.Name;
			this.originalActorName = currentStep.OriginalActor.Name;
			this.createdDate = currentStep.CreatedDate.format('yyyy-MM-dd HH:mm',  UserInfo.getTimeZone().toString());
			this.comment = currentStep.Comments;
			this.approvalComment = currentStep.Comments;
			this.isSelected = false;
		}

		private String getPicklistValue(String type) {
			List<Schema.PicklistEntry> values = ProcessInstance.Fields.Status.getDescribe().getPicklistValues();
			Map<String,String> typeApiToLabelMap = new Map<String,String>();
			for(Schema.PicklistEntry sp : values){
				//Map to hold Picklist API as Key and Picklist Label as Value
				typeApiToLabelMap.put(sp.getValue(), sp.getLabel());
			}
			return typeApiToLabelMap.containsKey(type) ? typeApiToLabelMap.get(type) : type;
		}		
	}

	public class ComponentData extends Response {
		@AuraEnabled
		public Map<String, RecordData> recordDataMap = new Map<String, RecordData>();
		@AuraEnabled
		public List<PicklistData> sobjectOptionList = new List<PicklistData>();
		@AuraEnabled
		public List<PicklistData> statusOptionList = new List<PicklistData>();
		@AuraEnabled
		public List<PicklistData> processOptionList = new List<PicklistData>();

		public ComponentData() {}
		public ComponentData(String errorMessage) {
			super(errorMessage);
		}
		public ComponentData(Exception ex) {
			super(ex);
		}
		public ComponentData(
			Map<String, RecordData> recordDataMap,
			List<PicklistData> sobjectOptionList,
			List<PicklistData> statusOptionList,
			List<PicklistData> processOptionList
		) {
			this.recordDataMap = recordDataMap;
			this.sobjectOptionList = sobjectOptionList;
			this.statusOptionList = statusOptionList;
			this.processOptionList = processOptionList;
		}
	}

	public class PicklistData {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }

		public PicklistData() {}
		public PicklistData(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}
}