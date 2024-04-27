/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class PaginationScreenControllerTest {

    @isTest
    static void testAddBook() {
        // Mocking GoogleBooksAPI response
        GoogleBooksAPI.Response googleBooksResponse = new GoogleBooksAPI.Response();
        googleBooksResponse.items = new List<GoogleBooksAPI.BookItem>();
        // Populate googleBooksResponse with necessary data
        
        // Mocking BookScoreAPI response
        BookScoreAPI.Response bookScoreResponse = new BookScoreAPI.Response();
        bookScoreResponse.probability = 0.9;
        bookScoreResponse.features = new BookScoreAPI.Features();
        bookScoreResponse.features.ari = 0.5;
        bookScoreResponse.features.colemanLiau = 0.6;
        bookScoreResponse.features.flesch = 0.7;
        bookScoreResponse.features.gulpease = 0.8;
        
        Test.startTest();
        // Call the method being tested
        PaginationScreenController.addBook(googleBooksResponse.items[0], 'book excerpt', bookScoreResponse);
        Test.stopTest();
        
        // Add assertions to validate the result
        // Example: System.assertEquals(expectedValue, actualValue);
    }

    @isTest
    static void testConvertBookItemToRequest() {
        // Mocking GoogleBooksAPI response
        GoogleBooksAPI.BookItem bookItem = new GoogleBooksAPI.BookItem();
        // Populate bookItem with necessary data
        
        // Mocking BookScoreAPI response
        BookScoreAPI.Response bookScoreResponse = new BookScoreAPI.Response();
        bookScoreResponse.probability = 0.9;
        bookScoreResponse.features = new BookScoreAPI.Features();
        bookScoreResponse.features.ari = 0.5;
        bookScoreResponse.features.colemanLiau = 0.6;
        bookScoreResponse.features.flesch = 0.7;
        bookScoreResponse.features.gulpease = 0.8;
        
        Test.startTest();
        // Call the method being tested
        PaginationScreenController.convertBookItemToRequest(bookItem, 'book excerpt', bookScoreResponse);
        Test.stopTest();
        
        // Add assertions to validate the result
        // Example: System.assertEquals(expectedValue, actualValue);
    }

    // Mock HTTP response generator
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"features":{"ari":0.5,"colemanLiau":0.6,"flesch":0.7,"gulpease":0.8},"probability":0.9}');
            res.setStatusCode(200);
            return res;
        }
    }
}
