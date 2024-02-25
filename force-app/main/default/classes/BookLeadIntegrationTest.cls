/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class BookLeadIntegrationTest {
    @isTest
    static void testBookLeadIntegration() {
        // Create test data for the account
        Account testAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com',
            Username__c = 'testuser',
            Password__c = 'Password@123',
            Gender__c = 'Male',
            Birthday__c = Date.newInstance(2000, 1, 1)
        );
        insert testAccount;

        // Create test data for the book lead integration
        BookLeadIntegration.Request request = new BookLeadIntegration.Request();
        request.accountId = testAccount.Id;
        request.book = new BookLeadIntegration.Book();
        request.book.name = 'Test Book';
        request.book.isbn13 = '1234567890123';
        request.book.isbn10 = '0123456789';
        request.book.author = 'Test Author';
        request.book.pageCount = 200;
        request.book.averageRating = 4.5;
        request.book.description = 'Test description';
        request.book.thumbnail = 'http://example.com/thumbnail.jpg';
        request.book.publisher = 'Test Publisher';
        request.book.publishDate = '2024-02-24';
        request.book.maturityRating = 'Mature';
        request.book.type = 'Fiction';
        request.book.categories = new List<BookLeadIntegration.Category>{new BookLeadIntegration.Category()};
        request.book.categories[0].name = 'Category 1';
        request.bookExcerpt = 'Test book excerpt';
        request.score = 90;
        request.ari = 5.5;
        request.colemanLiau = 8.2;
        request.flesch = 75.3;
        request.gulpease = 60.7;
        request.status = 'Open';

        Test.startTest();
        // Call the method to be tested
        BookLeadIntegration.Response response = BookLeadIntegration.BookLeadIntegration(request);
        Test.stopTest();

        // Assert the response
        System.assertEquals(true, response.success);
        System.assertEquals(null, response.message);

        // Retrieve and assert the inserted records if necessary
        List<Product2> insertedProducts = [SELECT Id, Name, ISBN_13__c, ISBN_10__c FROM Product2];
        System.assertEquals(1, insertedProducts.size());

        List<BookLead__c> insertedBookLeads = [SELECT Id, Name, Account__c FROM BookLead__c];
        System.assertEquals(1, insertedBookLeads.size());
        System.assertEquals('Test Book', insertedBookLeads[0].Name);
        System.assertEquals(testAccount.Id, insertedBookLeads[0].Account__c);
    }
}
