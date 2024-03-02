/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-01-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class GoogleBooksAPI {
  // Method to retrieve data from the Google Books API
  @AuraEnabled(cacheable=false)
  public static GoogleBooksResponse getBooksData(String queryString, Integer startIndex) {
    try{  
      if(String.isEmpty(queryString)) {
        throw new CalloutException('query not informed');
      }

      if(startIndex == null) {
        startIndex = 0;
      }
      // Define the base URL for the Google Books API
      String apiUrl = Integration__mdt.getInstance('GoogleAPI').Endpoint__c;

      // Construct the query parameters
      String params = '?printType=books';
      params += '&langRestrict=pt-BR';
      params += '&maxResults=40';
      params += '&q=' + EncodingUtil.urlEncode(queryString.trim(), 'UTF-8');
      params += '&startIndex=' + String.valueOf(startIndex);
      System.debug(params);

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

      GoogleBooksResponse booksResponse;

      // Parse the response
      if (response.getStatusCode() == 200) {
          // Response is successful (status code 200)
          // Deserialize the JSON response into GoogleBooksResponse instance
          booksResponse = (GoogleBooksResponse) JSON.deserialize(response.getBody(), GoogleBooksResponse.class);
          System.debug(booksResponse);

      } else {
          // Error handling if the response is not successful
          throw new CalloutException(response.getStatus());
      }

      return booksResponse;

    }catch (Exception e) {
        // Exception handling
        System.debug('Exception occurred: ' + e.getMessage());
    }

    return null;
  }

  public class GoogleBooksResponse {
    @AuraEnabled
    public String kind;
    @AuraEnabled
    public Integer totalItems;
    @AuraEnabled
    public List<BookItem> items;
  }

  public class BookItem {
    @AuraEnabled 
    public String kind;
    @AuraEnabled 
    public String id;
    @AuraEnabled 
    public String etag;
    @AuraEnabled 
    public String selfLink;
    @AuraEnabled 
    public VolumeInfo volumeInfo;
    @AuraEnabled 
    public SaleInfo saleInfo;
    @AuraEnabled 
    public AccessInfo accessInfo;
    @AuraEnabled 
    public SearchInfo searchInfo;
  }

  public class VolumeInfo {
    @AuraEnabled
    public String title;
    @AuraEnabled
    public List<String> authors;
    @AuraEnabled
    public String publisher;
    @AuraEnabled
    public String publishedDate;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public List<IndustryIdentifier> industryIdentifiers;
    @AuraEnabled
    public ReadingModes readingModes;
    @AuraEnabled
    public Integer pageCount;
    @AuraEnabled
    public String printType;
    @AuraEnabled
    public List<String> categories;
    @AuraEnabled
    public String maturityRating;
    @AuraEnabled
    public Boolean allowAnonLogging;
    @AuraEnabled
    public String contentVersion;
    @AuraEnabled
    public PanelizationSummary panelizationSummary;
    @AuraEnabled
    public ImageLinks imageLinks;
    @AuraEnabled
    public String language;
    @AuraEnabled
    public String previewLink;
    @AuraEnabled
    public String infoLink;
    @AuraEnabled
    public String canonicalVolumeLink;
  }

  public class SaleInfo {
    @AuraEnabled
    public String country;
    @AuraEnabled
    public String saleability;
    @AuraEnabled
    public Boolean isEbook;
    @AuraEnabled
    public ListPrice listPrice;
    @AuraEnabled
    public RetailPrice retailPrice;
    @AuraEnabled
    public String buyLink;
    @AuraEnabled
    public List<Offer> offers;
  }

  public class AccessInfo {
    @AuraEnabled
    public String country;
    @AuraEnabled
    public String viewability;
    @AuraEnabled
    public Boolean embeddable;
    @AuraEnabled
    public Boolean publicDomain;
    @AuraEnabled
    public String textToSpeechPermission;
    @AuraEnabled
    public Epub epub;
    @AuraEnabled
    public Pdf pdf;
    @AuraEnabled
    public String webReaderLink;
    @AuraEnabled
    public String accessViewStatus;
    @AuraEnabled
    public Boolean quoteSharingAllowed;
  }

  public class ReadingModes {
    @AuraEnabled
    public Boolean text;
    @AuraEnabled
    public Boolean image;
  }

  public class PanelizationSummary {
    @AuraEnabled
    public Boolean containsEpubBubbles;
    @AuraEnabled
    public Boolean containsImageBubbles;
  }

  public class ImageLinks {
    @AuraEnabled
    public String smallThumbnail;
    @AuraEnabled
    public String thumbnail;
  }

  public class IndustryIdentifier {
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String identifier;
  }

  public class ListPrice {
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled
    public String currencyCode;
  }

  public class RetailPrice {
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled
    public String currencyCode;
  }

  public class Offer {
    @AuraEnabled
    public Integer finskyOfferType;
    @AuraEnabled
    public ListPrice listPrice;
    @AuraEnabled
    public RetailPrice retailPrice;
    @AuraEnabled
    public Boolean giftable;
  }

  public class Epub {
    @AuraEnabled
    public Boolean isAvailable;
    @AuraEnabled
    public String acsTokenLink;
  }

  public class Pdf {
    @AuraEnabled
    public Boolean isAvailable;
    @AuraEnabled
    public String acsTokenLink;
  }

  public class SearchInfo {
    @AuraEnabled
    public String textSnippet;
  }    
}