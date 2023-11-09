@RestResource(urlMapping='/accounts')
global with sharing class AccountIntegration {
    @HttpPost
    global static String postAccountWithCharacter() {
        try {
            RestRequest thisReq = RestContext.request;
            List<ResponseBodyObject> responseBody = new List<ResponseBodyObject>();

            List<AccountRequestBody> requestBodyAsList = (List<AccountRequestBody>) JSON.deserialize(thisReq.requestBody, List<AccountRequestBody>.Class);

            for(AccountRequestBody bodyObj : requestBodyAsList) {
                
            }

            return JSON.serialize(responseBody);
        }
        catch(Exception e) {
            List<ResponseBodyObject> responseBody = new List<ResponseBodyObject>();
            ResponseBodyObject errorResponseBody = new ResponseBodyObject(e.getMessage());

            return JSON.serialize(responseBody);
        }
    }

    private class AccountRequestBody {
        AccountDataObject account;
        CharacterDataObject character;
    }

    private class AccountDataObject {
        String email;
        String username;
        String password;
        String genre;
        Date birthdate;
        String name;
    }

    private class CharacterDataObject {
        String name;
        String classId;
        String raceId;
        String colorId;
    }

    private class ResponseBodyObject {
        Boolean success;
        String message;
        String id;

        private ResponseBodyObject(String message) {
            this.success = false;
            this.id = null;
            this.message = message;
        }
    }
}
