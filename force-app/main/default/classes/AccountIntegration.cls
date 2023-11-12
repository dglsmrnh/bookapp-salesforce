@RestResource(urlMapping='/accounts')
global with sharing class AccountIntegration {
    @HttpPost
    global static String postAccountWithCharacter() {
        try {
            List<RecordType> recordTypeList = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Asset'];
            Map<String, RecordType> mapRecordTypeNameToInstance = new Map<String, RecordType>();

            for(RecordType recType : recordTypeList) {
                mapRecordTypeNameToInstance.put(recType.DeveloperName, recType);
            }

            RestRequest thisReq = RestContext.request;
            List<ResponseBodyObject> responseBody = new List<ResponseBodyObject>();

            List<AccountRequestBody> requestBodyAsList = (List<AccountRequestBody>) JSON.deserialize(thisReq.requestBody, List<AccountRequestBody>.Class);

            List<Account> accountInsertList = new List<Account>();
            List<Asset> assetInsertList = new List<Asset>();

            for(AccountRequestBody bodyObj : requestBodyAsList) {
                Account newAccount = new Account();
                newAccount.Name = bodyObj.account.name;
                newAccount.Genre__c = bodyObj.account.genre;
                accountInsertList.add(newAccount);

                Asset classAsset = new Asset();
                classAsset.Account = newAccount;
                classAsset.RecordType = mapRecordTypeNameToInstance.get(bodyObj.character.classId);
                assetInsertList.add(classAsset);

                Asset raceAsset = new Asset();
                raceAsset.Account = newAccount;
                raceAsset.RecordType = mapRecordTypeNameToInstance.get(bodyObj.character.raceId);
                assetInsertList.add(raceAsset);

                Asset colorAsset = new Asset();
                colorAsset.Account = newAccount;
                colorAsset.RecordType = mapRecordTypeNameToInstance.get(bodyObj.character.colorId);
                assetInsertList.add(colorAsset);
            }

            Database.insert(accountInsertList, false);
            Database.insert(assetInsertList, false);

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
        String name;
        String email;
        String username;
        String password;
        String genre;
        Date birthdate;
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
