/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : dglsmrnh
**/
@isTest
private class GoogleBooksAPITest {

    @isTest
    static void testGetBooksData() {
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new GoogleBooksAPITest.MockHttpResponseGenerator());
        
        // Call the method being tested
        Test.startTest();
        GoogleBooksAPI.Response result = GoogleBooksAPI.getBooksData('harry potter', 0);
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
            res.setBody('{"kind":"books#volumes","totalItems":461,"items":[{"kind":"books#volume","id":"11h7DwAAQBAJ","etag":"u7zF8NwbOM4","selfLink":"https://www.googleapis.com/books/v1/volumes/11h7DwAAQBAJ","volumeInfo":{"title":"Harry Potter e a Criança Amaldiçoada - Partes Um e Dois","subtitle":"Guião oficial da peça de teatro","authors":["J.K. Rowling","John Tiffany","Jack Thorne"],"publisher":"Pottermore Publishing","publishedDate":"2018-09-19","description":"Passaram dezanove anos desde que Harry Potter, Ron Weasley e Hermione Granger salvaram o mundo dos feiticeiros, e agora estão de volta numa aventura extraordinária, a que se junta uma corajosa nova geração que só agora chegou à Escola de Magia e Feitiçaria de Hogwarts. Enquanto Harry luta com um passado que se recusa a ficar onde pertence, o seu filho mais novo, Albus, luta com o peso de um legado familiar que nunca quis. À medida que o passado e o presente colidem, tanto o pai como o filho estão bloqueados numa corrida através do tempo enquanto lutam contra forças misteriosas, tudo isto enquanto o futuro está em jogo. Com base numa história original de J.K. Rowling, John Tiffany e Jack Thorne, Harry Potter e a Criança Amaldiçoada é o guião integral e completo da produção premiada do West End. Esta edição inclui o diálogo final e as direções de palco da peça original, em duas partes, uma peça de conversa entre o realizador John Tiffany e o dramaturgo Jack Thorne, a árvore genealógica dos Potter e uma cronologia de eventos-chave no mundo dos feiticeiros que conduzem a Harry Potter e a Criança Amaldiçoada.","industryIdentifiers":[{"type":"ISBN_13","identifier":"9781781105337"},{"type":"ISBN_10","identifier":"1781105332"}],"readingModes":{"text":true,"image":false},"pageCount":437,"printType":"BOOK","categories":["Drama"],"maturityRating":"NOT_MATURE","allowAnonLogging":true,"contentVersion":"1.5.5.0.preview.2","panelizationSummary":{"containsEpubBubbles":false,"containsImageBubbles":false},"imageLinks":{"smallThumbnail":"http://books.google.com/books/content?id=11h7DwAAQBAJ&printsec=frontcover&img=1&zoom=5&source=gbs_api","thumbnail":"http://books.google.com/books/content?id=11h7DwAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api"},"language":"pt","previewLink":"http://books.google.com.br/books?id=11h7DwAAQBAJ&dq=harry+potter&hl=&as_pt=BOOKS&cd=1&source=gbs_api","infoLink":"http://books.google.com.br/books?id=11h7DwAAQBAJ&dq=harry+potter&hl=&as_pt=BOOKS&source=gbs_api","canonicalVolumeLink":"https://books.google.com/books/about/Harry_Potter_e_a_Crian%C3%A7a_Amaldi%C3%A7oada_P.html?hl=&id=11h7DwAAQBAJ"},"saleInfo":{"country":"BR","saleability":"NOT_FOR_SALE","isEbook":false},"accessInfo":{"country":"BR","viewability":"NO_PAGES","embeddable":false,"publicDomain":false,"textToSpeechPermission":"ALLOWED","epub":{"isAvailable":true},"pdf":{"isAvailable":true},"webReaderLink":"http://play.google.com/books/reader?id=11h7DwAAQBAJ&hl=&as_pt=BOOKS&source=gbs_api","accessViewStatus":"NONE","quoteSharingAllowed":false},"searchInfo":{"textSnippet":"Esta edição inclui o diálogo final e as direções de palco da peça original, em duas partes, uma peça de conversa entre o realizador John Tiffany e o dramaturgo Jack Thorne, a árvore genealógica dos Potter e uma cronologia de ..."}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}
