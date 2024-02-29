public with sharing class GoogleBooksAPI {
    // Method to retrieve data from the Google Books API
    public static void retrieveBooksData(String queryString, Integer startIndex) {
        // Define the base URL for the Google Books API
        String apiUrl = 'https://www.googleapis.com/books/v1/volumes';

        // Construct the query parameters
        String params = '?printType=books';
        params += '&langRestrict=pt-BR';
        params += '&maxResults=40';
        params += '&q=' + EncodingUtil.urlEncode(queryString, 'UTF-8');
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

        // Parse the response
        if (response.getStatusCode() == 200) {
            // Response is successful (status code 200)
            String responseBody = response.getBody();
            // You can parse the responseBody JSON and process it accordingly
            // Example: System.debug(responseBody);
        } else {
            // Error handling if the response is not successful
            System.debug('HTTP request failed with status code: ' + response.getStatusCode());
            System.debug('Error message: ' + response.getStatus());
        }
    }
}