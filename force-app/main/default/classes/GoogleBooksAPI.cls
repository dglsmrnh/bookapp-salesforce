/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-29-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class GoogleBooksAPI {
  // Method to retrieve data from the Google Books API
  @AuraEnabled
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
    public String kind;
    public Integer totalItems;
    public List<BookItem> items;
  }

  public class BookItem {
    public String kind;
    public String id;
    public String etag;
    public String selfLink;
    public VolumeInfo volumeInfo;
    public SaleInfo saleInfo;
    public AccessInfo accessInfo;
    public SearchInfo searchInfo;
  }

  public class VolumeInfo {
    public String title;
    public List<String> authors;
    public String publisher;
    public String publishedDate;
    public String description;
    public List<IndustryIdentifier> industryIdentifiers;
    public ReadingModes readingModes;
    public Integer pageCount;
    public String printType;
    public List<String> categories;
    public String maturityRating;
    public Boolean allowAnonLogging;
    public String contentVersion;
    public PanelizationSummary panelizationSummary;
    public ImageLinks imageLinks;
    public String language;
    public String previewLink;
    public String infoLink;
    public String canonicalVolumeLink;
  }

  public class SaleInfo {
    public String country;
    public String saleability;
    public Boolean isEbook;
    public ListPrice listPrice;
    public RetailPrice retailPrice;
    public String buyLink;
    public List<Offer> offers;
  }

  public class AccessInfo {
    public String country;
    public String viewability;
    public Boolean embeddable;
    public Boolean publicDomain;
    public String textToSpeechPermission;
    public Epub epub;
    public Pdf pdf;
    public String webReaderLink;
    public String accessViewStatus;
    public Boolean quoteSharingAllowed;
  }

  public class ReadingModes {
    public Boolean text;
    public Boolean image;
  }

  public class PanelizationSummary {
    public Boolean containsEpubBubbles;
    public Boolean containsImageBubbles;
  }

  public class ImageLinks {
    public String smallThumbnail;
    public String thumbnail;
  }

  public class IndustryIdentifier {
    public String type;
    public String identifier;
  }

  public class ListPrice {
    public Decimal amount;
    public String currencyCode;
  }

  public class RetailPrice {
    public Decimal amount;
    public String currencyCode;
  }

  public class Offer {
    public Integer finskyOfferType;
    public ListPrice listPrice;
    public RetailPrice retailPrice;
    public Boolean giftable;
  }

  public class Epub {
    public Boolean isAvailable;
    public String acsTokenLink;
  }

  public class Pdf {
    public Boolean isAvailable;
    public String acsTokenLink;
  }

  public class SearchInfo {
    public String textSnippet;
  }    
}