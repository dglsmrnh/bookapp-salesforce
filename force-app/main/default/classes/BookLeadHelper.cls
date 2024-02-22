/**
 * @description       : 
 * @author            : dglrmnh
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class BookLeadHelper {

	public static void createApprovalProcess(Map<Id, BookLead__c> newMap) {
		
	}

	public static void convertLead(Map<Id, BookLead__c> oldMap, Map<Id, BookLead__c> newMap) {
		Set<Id> productIdList = new Set<Id>();
		List<Product2> productList = new List<Product2>();

		for(BookLead__c bk: newMap) {
			if(bk.Status__c == 'Closed - Converted' && oldMap.get(bk.Id).Status__c != 'Closed - Converted') {
				productIdList.add(bk.Book__c);
			}
		}

		for(Id productId: productIdList) {
			productList.add(new Product2(Id = productId, IsActive = true));
		}
		
	}
}