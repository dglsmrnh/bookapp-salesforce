/**
 * @description       : 
 * @author            : douglas.marinho@globant.com
 * @group             : 
 * @last modified on  : 03-14-2024
 * @last modified by  : douglas.marinho@globant.com
**/
public with sharing class ShadifyAPI {

  @AuraEnabled(cacheable=false)
  public static MemoryGameResponse getMemoryGameData(String type) {
    try {  
      // Define the base URL for the Google Books API
      String apiUrl = Integration__mdt.getInstance('ShadifyMemory').Endpoint__c;

      // Construct the query parameters
      String params = '?pair-size=3';

      // Append parameters to the URL
      String fullUrl = apiUrl + params;

      // Define the HTTP request
      HttpRequest request = new HttpRequest();
      request.setEndpoint(fullUrl);
      request.setMethod('GET');

      // Create a new HTTP object to send the request
      Http http = new Http();
      
      // Send the HTTP request and get the response
      HttpResponse response = http.send(request);

      MemoryGameResponse gameResponse;

      // Parse the response
      if (response.getStatusCode() == 200) {
        // Response is successful (status code 200)
        // Deserialize the JSON response into Response instance
        gameResponse = (MemoryGameResponse) JSON.deserialize(response.getBody(), MemoryGameResponse.class);

      } else {
        // Error handling if the response is not successful
        throw new CalloutException(response.getStatus());
      }

      return gameResponse;

    }catch (Exception e) {
      // Exception handling
      throw new CalloutException('Exception occurred: ' + e.getMessage());
    }
  }

  @AuraEnabled(cacheable=false)
  public static WordSearchResponse getWordSearchGameData() {
    try {  
      // Define the base URL for the Google Books API
      String apiUrl = Integration__mdt.getInstance('ShadifyWordSearch').Endpoint__c;

      // Construct the query parameters
      String params = '?width=5&height=5';

      // Append parameters to the URL
      String fullUrl = apiUrl + params;

      // Define the HTTP request
      HttpRequest request = new HttpRequest();
      request.setEndpoint(fullUrl);
      request.setMethod('GET');

      // Create a new HTTP object to send the request
      Http http = new Http();
      
      // Send the HTTP request and get the response
      HttpResponse response = http.send(request);

      WordSearchResponse gameResponse;

      // Parse the response
      if (response.getStatusCode() == 200) {
        // Response is successful (status code 200)
        // Deserialize the JSON response into Response instance
        String responseString = response.getBody();
        responseString.replace('"end":', '"end_x":');
        gameResponse = (WordSearchResponse) JSON.deserialize(responseString, WordSearchResponse.class);

      } else {
        // Error handling if the response is not successful
        throw new CalloutException(response.getStatus());
      }

      return gameResponse;

    }catch (Exception e) {
      // Exception handling
      throw new CalloutException('Exception occurred: ' + e.getMessage());
    }
  }

  public class MemoryGameResponse {
  
    // JSON structure parameters
    @AuraEnabled
    public Integer width {get;set;}
    @AuraEnabled
    public Integer height {get;set;}
    @AuraEnabled
    public Integer pairSize {get;set;}
    @AuraEnabled
    public Integer totalPairs {get;set;}
    @AuraEnabled
    public List<List<String>> grid {get;set;}
    @AuraEnabled
    public List<PairPosition> pairPositions {get;set;}
  }

  public class PairPosition {
    @AuraEnabled
    public String value {get;set;}
    @AuraEnabled
    public String contentVersionId {get;set;}
    @AuraEnabled
    public String contentUrl {get;set;}
    @AuraEnabled
    public List<List<Integer>> positions {get;set;}
  }

  public class WordSearchResponse {
  
    // JSON structure parameters
    @AuraEnabled
    public Integer width {get;set;}
    @AuraEnabled
    public Integer height {get;set;}
    @AuraEnabled
    public Integer wordsCount {get;set;}
    @AuraEnabled
    public List<List<String>> grid {get;set;}
    @AuraEnabled
    public List<Word> words {get;set;}
  }

  // Inner class for words
  public class Word {
    @AuraEnabled
    public String word {get;set;}
    @AuraEnabled
    public Position position {get;set;}
  }

  // Inner class for position
  public class Position {
      @AuraEnabled
      public List<Integer> start {get;set;}
      @AuraEnabled
      public List<Integer> end_x {get;set;}
  }
    
}