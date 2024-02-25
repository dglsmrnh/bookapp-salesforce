/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@RestResource(urlMapping='/recommendation')
global with sharing class BookLeadIntegration {

    global static final Id PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId();
    // https://github.com/gazzola/corpus_readability_nlp_portuguese/tree/master?tab=readme-ov-file
    @HttpPost
    global static Response BookLeadIntegration(Request request) {
        try {
            if([SELECT Id FROM Product2 WHERE ISBN_13__c =: request.book.isbn13 OR ISBN_10__c =: request.book.isbn10].size() <= 0) {
            //     throw new RecommendationException('Desculpe, esse livro já foi recomendado.');
            // }
                Product2 prd = request.book.serializeProduct();
                insert prd;

                BookLead__c bk = request.serializeLead(prd.Id);
                insert bk;

                linkCategories(request.book.categories, prd.Id);
            }
            return new Response();

        } catch(Exception e) {
            return new Response(e.getMessage());
        }
    }

    global class Book {
        global String id { get; set; }
        global String name { get; set; }
        global String isbn13 { get; set; }
        global String isbn10 { get; set; }
        global String author { get; set; }
        global Integer pageCount { get; set; }
        global Decimal averageRating { get; set; }
        global String description { get; set; }
        global String thumbnail { get; set; }
        global String publisher { get; set; }
        global String publishDate { get; set; }
        global String maturityRating { get; set; }
        global String type { get; set; }
        global List<Category> categories { get; set; }

        public Product2 serializeProduct() {
            Product2 prd = new Product2();

            prd.IsActive = false;
            prd.Name = this.name.left(255);
            prd.ISBN_10__c = this.isbn10;
            prd.ISBN_13__c = this.isbn13;
            prd.MaturityRating__c = this.maturityRating;
            prd.Author__c = this.author.left(255);
            prd.PageCount__c = this.pageCount;
            prd.Family = 'Book';
            prd.RecordTypeId = PRODUCT_RECORDTYPE;
            prd.DisplayUrl = this.thumbnail;
            prd.Description = this.description.left(4000);
            prd.PublishedDate__c = this.publishDate != null ? Date.valueOf(this.publishDate) : null;
            prd.Publisher__c = this.publisher;

            return prd;
        }
    }
    
    global class Category {
        global String name { get; set; }
    }
    
    global class Request {
        global String accountId { get; set; }
        global Book book { get; set; }
        global String bookExcerpt { get; set; }
        global Integer score { get; set; }
        global Decimal ari { get; set; }
        global Decimal colemanLiau { get; set; }
        global Decimal flesch { get; set; }
        global Decimal gulpease { get; set; }
        global String status { get; set; }

        public BookLead__c serializeLead(Id productId) {
            BookLead__c bk = new BookLead__c();
            bk.Book__c = productId;
            bk.Name = this.book.name.left(80);
            bk.Account__c = this.accountId;
            bk.ARI__c = this.ari;
            bk.Score__c = this.score;
            bk.Flesch__c = this.flesch;
            bk.Gulpease__c = this.gulpease;
            bk.ColemanLiau__c = this.colemanLiau;
            bk.Status__c = 'Open';
            bk.BookExcerpt__c = this.bookExcerpt;

            return bk;
        }
    }

    global class Response {
        global Boolean success { get; set; }
        global String message {get; set; }

        global Response() {
            this.success = true;
        }

        global Response(String message) {
            this.success = false;
            this.message = message;
        }
    }

    private static void linkCategories(List<Category> categories, Id productId) {

        // Get default catalog id to product type
        DefaultCatalog__mdt defaultCatalog = DefaultCatalog__mdt.getInstance('Book');

        Id catalogId;
        List<ProductCatalog> catalogList = [SELECT Id FROM ProductCatalog WHERE Name =: defaultCatalog.MasterLabel LIMIT 1];
        if(catalogList.isEmpty()) {
            ProductCatalog catalog = new ProductCatalog(Name = defaultCatalog.MasterLabel);
            insert catalog;
            catalogId = catalog.Id;
        }
        else {
            catalogId = catalogList[0].Id;
        }

        // save categories
        List<ProductCategory> categoryList = new List<ProductCategory>();

        for(Category category : categories) {
            categoryList.add(new ProductCategory(Name = category.name, CatalogId = catalogId, ExternalId__c = category.name));
        }

        if(!categoryList.IsEmpty()) {
            Database.upsert(categoryList, ProductCategory.ExternalId__c, true);
        }

        List<ProductCategoryProduct> prdCategoryList = new List<ProductCategoryProduct>();

        for(ProductCategory category : categoryList) {
            prdCategoryList.add(new ProductCategoryProduct(ProductCategoryId = category.Id, ProductId = productId));
        }

        if(!prdCategoryList.IsEmpty()) {
            insert prdCategoryList;
        }
    }

    private class RecommendationException extends Exception {
    }
    
}