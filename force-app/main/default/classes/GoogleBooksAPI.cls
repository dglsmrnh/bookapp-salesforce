/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-13-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class GoogleBooksAPI {
  // Method to retrieve data from the Google Books API
  @AuraEnabled(cacheable=false)
  public static Response getBooksData(String queryString, Integer startIndex) {
    try {  
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
      params += '&maxResults=39';
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

      Response booksResponse;

      // Parse the response
      if (response.getStatusCode() == 200) {
          // Response is successful (status code 200)
          // Deserialize the JSON response into Response instance
          booksResponse = (Response) JSON.deserialize(response.getBody(), Response.class);
          booksResponse.setISBN();
          System.debug(booksResponse);

      } else {
          // Error handling if the response is not successful
          throw new CalloutException(response.getStatus());
      }

      return getProduct(booksResponse);

    }catch (Exception e) {
        // Exception handling
        throw new CalloutException('Exception occurred: ' + e.getMessage());
    }
  }

  public static Response getProduct(Response bookResponse) {
    System.debug('getProduct');
    Set<String> isbnSet = new Set<String>();
    Map<String, BookItem> itemMap = new Map<String, BookItem>();

    if(bookResponse.items != null) {
      for(BookItem item : bookResponse.items) {
        item.isProduct = false;
        if(item.isbn13 != null || item.isbn10 != null) {
          isbnSet.add((item.isbn13 == null ? item.isbn10 : item.isbn13));
          itemMap.put((item.isbn13 == null ? item.isbn10 : item.isbn13), item);
        }
      }

      if(!isbnSet.isEmpty()) {
        List<Product2> prdList = [SELECT Id, ISBN_13__c FROM Product2 WHERE ISBN_13__c IN: isbnSet];

        for(Product2 prd : prdList) {
          if(itemMap.containsKey(prd.ISBN_13__c.trim())) {
            itemMap.get(prd.ISBN_13__c.trim()).productId = prd.Id;
            itemMap.get(prd.ISBN_13__c.trim()).isProduct = true;
          }
        }
      }
    }
    return bookResponse;
  }

  public class Response {
    @AuraEnabled
    public String kind { get; set; }
    @AuraEnabled
    public Integer totalItems { get; set; }
    @AuraEnabled
    public List<BookItem> items { get; set; }

    public void setISBN() {
      if(this.items != null) {
        for(BookItem item : this.items) {
          if(item.volumeInfo.industryIdentifiers != null) {
            for(IndustryIdentifier ind : item.volumeInfo.industryIdentifiers) {
              if(ind.type == 'ISBN_10') {
                item.isbn10 = ind.identifier;

                if(item.isbn13 == null) {
                  item.isbn13 = ind.identifier;
                }
              }

              if(ind.type == 'ISBN_13') {
                item.isbn13 = ind.identifier;
              }
            }
          }
        }
      }
    }
  }

  public class BookItem {
    @AuraEnabled 
    public String kind { get; set; }
    @AuraEnabled 
    public String id { get; set; }
    @AuraEnabled 
    public String etag { get; set; }
    @AuraEnabled 
    public String selfLink { get; set; }
    @AuraEnabled 
    public VolumeInfo volumeInfo { get; set; }
    @AuraEnabled 
    public SaleInfo saleInfo { get; set; }
    @AuraEnabled 
    public AccessInfo accessInfo { get; set; }
    @AuraEnabled 
    public SearchInfo searchInfo { get; set; }
    @AuraEnabled
    public String productId { get; set; }
    @AuraEnabled
    public Boolean isProduct { get; set; }
    @AuraEnabled
    public String isbn10 { get; set; }
    @AuraEnabled
    public String isbn13 { get; set; }
  }

  public class VolumeInfo {
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public List<String> authors { get; set; }
    @AuraEnabled
    public String publisher { get; set; }
    @AuraEnabled
    public String publishedDate { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public List<IndustryIdentifier> industryIdentifiers { get; set; }
    @AuraEnabled
    public ReadingModes readingModes { get; set; }
    @AuraEnabled
    public Integer pageCount { get; set; }
    @AuraEnabled
    public String printType { get; set; }
    @AuraEnabled
    public List<String> categories { get; set; }
    @AuraEnabled
    public String maturityRating { get; set; }
    @AuraEnabled
    public Boolean allowAnonLogging { get; set; }
    @AuraEnabled
    public String contentVersion { get; set; }
    @AuraEnabled
    public PanelizationSummary panelizationSummary { get; set; }
    @AuraEnabled
    public ImageLinks imageLinks { get; set; }
    @AuraEnabled
    public String language { get; set; }
    @AuraEnabled
    public String previewLink { get; set; }
    @AuraEnabled
    public String infoLink { get; set; }
    @AuraEnabled
    public String canonicalVolumeLink { get; set; }
  }

  public class SaleInfo {
    @AuraEnabled
    public String country { get; set; }
    @AuraEnabled
    public String saleability { get; set; }
    @AuraEnabled
    public Boolean isEbook { get; set; }
    @AuraEnabled
    public ListPrice listPrice { get; set; }
    @AuraEnabled
    public RetailPrice retailPrice { get; set; }
    @AuraEnabled
    public String buyLink { get; set; }
    @AuraEnabled
    public List<Offer> offers { get; set; }
  }

  public class AccessInfo {
    @AuraEnabled
    public String country { get; set; }
    @AuraEnabled
    public String viewability { get; set; }
    @AuraEnabled
    public Boolean embeddable { get; set; }
    @AuraEnabled
    public Boolean publicDomain { get; set; }
    @AuraEnabled
    public String textToSpeechPermission { get; set; }
    @AuraEnabled
    public Epub epub { get; set; }
    @AuraEnabled
    public Pdf pdf { get; set; }
    @AuraEnabled
    public String webReaderLink { get; set; }
    @AuraEnabled
    public String accessViewStatus { get; set; }
    @AuraEnabled
    public Boolean quoteSharingAllowed { get; set; }
  }

  public class ReadingModes {
    @AuraEnabled
    public Boolean text { get; set; }
    @AuraEnabled
    public Boolean image { get; set; }
  }

  public class PanelizationSummary {
    @AuraEnabled
    public Boolean containsEpubBubbles { get; set; }
    @AuraEnabled
    public Boolean containsImageBubbles { get; set; }
  }

  public class ImageLinks {
    @AuraEnabled
    public String smallThumbnail { get; set; }
    @AuraEnabled
    public String thumbnail { get; set; }
  }

  public class IndustryIdentifier {
    @AuraEnabled
    public String type { get; set; }
    @AuraEnabled
    public String identifier { get; set; }
  }

  public class ListPrice {
    @AuraEnabled
    public Decimal amount { get; set; }
    @AuraEnabled
    public String currencyCode { get; set; }
  }

  public class RetailPrice {
    @AuraEnabled
    public Decimal amount { get; set; }
    @AuraEnabled
    public String currencyCode { get; set; }
  }

  public class Offer {
    @AuraEnabled
    public Integer finskyOfferType { get; set; }
    @AuraEnabled
    public ListPrice listPrice { get; set; }
    @AuraEnabled
    public RetailPrice retailPrice { get; set; }
    @AuraEnabled
    public Boolean giftable { get; set; }
  }

  public class Epub {
    @AuraEnabled
    public Boolean isAvailable { get; set; }
    @AuraEnabled
    public String acsTokenLink { get; set; }
  }

  public class Pdf {
    @AuraEnabled
    public Boolean isAvailable { get; set; }
    @AuraEnabled
    public String acsTokenLink { get; set; }
  }

  public class SearchInfo {
    @AuraEnabled
    public String textSnippet { get; set; }
  }    
}