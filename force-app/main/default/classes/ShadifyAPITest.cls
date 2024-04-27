/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class ShadifyAPITest {
    
    // Test method for getMemoryGameData
    @isTest
    static void testGetMemoryGameData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ShadifyAPI.MemoryGameResponse response = ShadifyAPI.getMemoryGameData('Memory');
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(3, response.width, 'Width should be 3');
        System.assertEquals(3, response.height, 'Height should be 3');
        // Add more assertions for other response attributes
    }
    
    // Test method for getWordSearchGameData
    @isTest
    static void testGetWordSearchGameData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ShadifyAPI.WordSearchResponse response = ShadifyAPI.getWordSearchGameData();
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(5, response.width, 'Width should be 5');
        System.assertEquals(5, response.height, 'Height should be 5');
        // Add more assertions for other response attributes
    }
    
    // Mock HttpResponse generator class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement the respond method
        public HTTPResponse respond(HTTPRequest request) {
            // Create a new HTTPResponse object
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            
            // Mock data for getMemoryGameData
            if (request.getEndpoint().contains('memory')) {
                response.setBody('{"width": 3, "height": 3, "pairSize": 2, "totalPairs": 3, "grid": [["A","B","C"],["D","E","F"]], "pairPositions": [{"value": "A", "contentVersionId": "123", "positions": [[1,1],[2,2]]}]}');
            }
            // Mock data for getWordSearchGameData
            else if (request.getEndpoint().contains('wordsearch')) {
                response.setBody('{"width": 5, "height": 5, "wordsCount": 2, "grid": [["A","B","C","D","E"],["F","G","H","I","J"],["K","L","M","N","O"],["P","Q","R","S","T"],["U","V","W","X","Y"]], "words": [{"word": "HELLO", "position": {"start": [0,0], "end_x": [4,4]}},{"word": "WORLD", "position": {"start": [4,0], "end": [0,4]}}]}');
            }
            
            response.setStatusCode(200);
            return response;
        }
    }
}
