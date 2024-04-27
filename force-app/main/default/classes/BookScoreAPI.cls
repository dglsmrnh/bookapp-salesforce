/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-05-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class BookScoreAPI {

	@AuraEnabled(cacheable=false)
	public static Response getBookScore(String excerpt) {
		try {
			if(String.isEmpty(excerpt)) {
				throw new CalloutException('Nenhum valor informado.');
			}

			Request requestObj = new Request();
			requestObj.excerpt = excerpt;
			
			String jsonRequest = JSON.serialize(requestObj);

			String apiUrl = Integration__mdt.getInstance('LEIAScore').Endpoint__c;

			HttpRequest req = new HttpRequest();
			req.setEndpoint(apiUrl);
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			req.setBody(jsonRequest);
			
			Http http = new Http();
			HttpResponse res = http.send(req);

			Response response;
			
			if (res.getStatusCode() == 200) {
				response = (Response)JSON.deserialize(res.getBody(), Response.class);
			} else {
				throw new CalloutException('Error: ' + res.getStatus());
			}

			return response;
			
		} catch (Exception e) {
			throw new CalloutException('Exception: ' + e.getMessage());
		}
	}
	
	public class Request {
			public String excerpt { get; set; }
	}

	public class Response {    
			@AuraEnabled
			public Features features { get; set; }        
			@AuraEnabled
			public Decimal probability { get; set; }
	}

	public class Features {
			@AuraEnabled
			public Decimal ari { get; set; }            
			@AuraEnabled
			public Decimal colemanLiau { get; set; }            
			@AuraEnabled
			public Decimal flesch { get; set; }
			@AuraEnabled
			public Decimal gulpease { get; set; }
	}
}