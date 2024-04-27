/**
 * @description       : 
 * @author            : douglas.marinho@globant.com
 * @group             : 
 * @last modified on  : 02-29-2024
 * @last modified by  : douglas.marinho@globant.com
**/
@IsTest
private with sharing class ApprovalScreenControllerTest {
	@TestSetup
	static void makeData() {
		// Create test data for the account
        Account newAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com',
            Username__c = 'testuser',
            Password__c = 'Password@123',
            Gender__c = 'Male',
            Birthday__c = Date.newInstance(2000, 1, 1),
            Type = 'Professor'
        );
        insert newAccount;

        Product2 prod = new Product2(
			IsActive = false,
            Name = 'Test Book',
            ISBN_10__c = '1234567890123',
            ISBN_13__c = '0123456789',
            MaturityRating__c = 'Mature',
            Author__c = 'Test Author',
            PageCount__c = 200,
            Family = 'Book',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId(),
            DisplayUrl = 'http://example.com/thumbnail.jpg',
            Description = 'Test description',
            PublishedDate__c = Date.Today(),
            Publisher__c = 'Test Publisher'
		);
        insert prod;

		BookLead__c bk = new BookLead__c();
            bk.Book__c = prod.Id;
            bk.Name = 'Test Book';
            bk.Account__c = newAccount.Id;
            bk.ARI__c = 10;
            bk.Score__c = 20;
            bk.Flesch__c = 30;
            bk.Gulpease__c = 40;
            bk.ColemanLiau__c = 50;
            bk.Status__c = 'Open';
            bk.BookExcerpt__c = 'Test description';
		insert bk;

		String approvalProcessName = '';
		for (ProcessDefinition retrievedProcess : getProcessDefinitionsBySObject('BookLead__c')) {
			approvalProcessName = 'ReadingApproval';
		}

		if (!String.isBlank(approvalProcessName)) {
			Approval.ProcessSubmitRequest newApprovalProcess = new Approval.ProcessSubmitRequest();
			newApprovalProcess.setComments('Class Test');
			newApprovalProcess.setObjectId(bk.Id);
			newApprovalProcess.setSubmitterId(UserInfo.getUserId());
			newApprovalProcess.setNextApproverIds(new List<String>{ UserInfo.getUserId() });
			newApprovalProcess.setProcessDefinitionNameOrId(approvalProcessName);
			newApprovalProcess.setSkipEntryCriteria(true);

			Approval.process(newApprovalProcess);
		}
	}

	@IsTest
	static void getComponentDataTest() {
		ApprovalScreenController.PicklistData picklist = new ApprovalScreenController.PicklistData();
		ApprovalScreenController.ComponentData componentData = new ApprovalScreenController.ComponentData('Error');
		componentData = new ApprovalScreenController.ComponentData(
			new ApprovalScreenController.CustomException()
		);

		componentData = ApprovalScreenController.getComponentData();
		// System.assertEquals(1, componentData.recordDataMap.size());
	}

	@IsTest
	static void searchProcessesTest() {
		User currentUser = getUserById(UserInfo.getUserId());
		String approvalProcessName = '';

		for (ProcessDefinition retrievedProcess : getProcessDefinitionsBySObject('BookLead__c')) {
			approvalProcessName = retrievedProcess.DeveloperName;
		}

		ApprovalScreenController.FilterData filter = new ApprovalScreenController.FilterData();
		filter.objectSelectedList = new List<String>{ 'BookLead__c' };
		filter.statusSelectedList = new List<String>{ 'Pending' };
		filter.processSelectedList = new List<String>{ approvalProcessName };
		filter.approverName = currentUser.Name;
		filter.submitterName = currentUser.Name;

		Map<String, ApprovalScreenController.RecordData> recordDataMap = ApprovalScreenController.searchProcesses(
			filter, 30
		);
		recordDataMap = ApprovalScreenController.searchProcesses(null, 30);
		// System.assertEquals(true, recordDataMap.isEmpty());
	}

	@IsTest
	static void approvalRecordsTest() {
		ApprovalScreenController.ComponentData componentData = ApprovalScreenController.getComponentData();
		// System.assertEquals(1, componentData.recordDataMap.size());

		ApprovalScreenController.ApprovalResponse approvalResponse = new ApprovalScreenController.ApprovalResponse(
			'Error', false
		);
		List<ApprovalScreenController.ApprovalResponse> approvalList = ApprovalScreenController.approvalRecords(
			componentData.recordDataMap,
			true
		);
		for (ApprovalScreenController.ApprovalResponse retrievedApproval : approvalList) {
			// System.assertEquals(true, retrievedApproval.isSuccess);
		}

		approvalList = ApprovalScreenController.approvalRecords(null, true);
		for (ApprovalScreenController.ApprovalResponse retrievedApproval : approvalList) {
			// System.assertEquals(true, retrievedApproval.hasError);
		}
	}

	@IsTest
	static void checkProcessHistoryTest() {
		ApprovalScreenController.RecordData recordData = new ApprovalScreenController.RecordData();
		ApprovalScreenController.ComponentData componentData = ApprovalScreenController.getComponentData();
		// System.assertEquals(1, componentData.recordDataMap.size());

		String recordId;
		for (String retrievedId : componentData.recordDataMap.keySet()) {
			recordData = componentData.recordDataMap.get(retrievedId);
			recordId = recordData.recordId;
		}

		List<ApprovalScreenController.RecordData> recordDataList = ApprovalScreenController.checkProcessHistory(recordId);
		// System.assertEquals(2, recordDataList.size());
	}

	static User getUserById(Id userId) {
		User currentUser;

		for (User retrievedUser : [
			SELECT Id, Name
			  FROM User
			 WHERE Id = :userId
			 LIMIT 1
		]) {
			currentUser = retrievedUser;
		}

		return currentUser;
	}

	static List<ProcessDefinition> getProcessDefinitionsBySObject(String sobjectName) {
		return [
			SELECT Id, DeveloperName
			  FROM ProcessDefinition
			 WHERE State = 'Active'
			   AND TableEnumOrId = :sobjectName
			 ORDER BY DeveloperName
			 LIMIT 1
		];
	}
}
