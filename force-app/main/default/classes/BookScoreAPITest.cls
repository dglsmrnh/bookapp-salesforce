/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class BookScoreAPITest {

    @isTest
    static void testGetBookScore() {
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new BookScoreAPITest.MockHttpResponseGenerator());
        
        // Call the method being tested
        Test.startTest();
        BookScoreAPI.Response result = BookScoreAPI.getBookScore('Some excerpt');
        Test.stopTest();
        
        // Add assertions to validate the result
        System.assertNotEquals(null, result);
        // Add more assertions as needed
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
