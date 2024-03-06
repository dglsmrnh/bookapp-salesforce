/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-05-2024
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
    public String kind;
    @AuraEnabled
    public Integer totalItems;
    @AuraEnabled
    public List<BookItem> items;

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
    @AuraEnabled
    public String productId;
    @AuraEnabled
    public Boolean isProduct;
    @AuraEnabled
    public String isbn10;
    @AuraEnabled
    public String isbn13;
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