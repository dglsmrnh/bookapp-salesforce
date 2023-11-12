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

            List<AccountRequestBody> requestBodyAsList = (List<AccountRequestBody>) JSON.deserialize(thisReq.requestBody.toString(), List<AccountRequestBody>.Class);

            List<Account> accountInsertList = new List<Account>();
            List<Asset> assetInsertList = new List<Asset>();

            for(AccountRequestBody bodyObj : requestBodyAsList) {
                Account newAccount = new Account();
                newAccount.Name = bodyObj.account.name;
                //newAccount.CharacterName__c = bodyObj.character.name;
                newAccount.Email__c = bodyObj.account.email;
                newAccount.Gender__c = bodyObj.account.genre;
                newAccount.Birthday__c = bodyObj.account.birthdate;
                newAccount.Username__c = bodyObj.account.username;
                newAccount.Password__c = bodyObj.account.password;
                accountInsertList.add(newAccount);

                if(String.isNotBlank(bodyObj.character.classId)) {
                    Asset classAsset = new Asset();
                    classAsset.Account = newAccount;
                    classAsset.RecordType = mapRecordTypeNameToInstance.containsKey(bodyObj.character.classId) ? mapRecordTypeNameToInstance.get(bodyObj.character.classId) : null;
                    assetInsertList.add(classAsset);
                }

                if(String.isNotBlank(bodyObj.character.raceId)) {
                    Asset raceAsset = new Asset();
                    raceAsset.Account = newAccount;
                    raceAsset.RecordType = mapRecordTypeNameToInstance.containsKey(bodyObj.character.raceId) ? mapRecordTypeNameToInstance.get(bodyObj.character.raceId) : null;
                    assetInsertList.add(raceAsset);
                }

                if(String.isNotBlank(bodyObj.character.colorId)) {
                    Asset colorAsset = new Asset();
                    colorAsset.Account = newAccount;
                    colorAsset.RecordType = mapRecordTypeNameToInstance.containsKey(bodyObj.character.colorId) ? mapRecordTypeNameToInstance.get(bodyObj.character.colorId) : null;
                    assetInsertList.add(colorAsset);
                }
            }

            Database.insert(accountInsertList, true);
            Database.insert(assetInsertList, true);

            for(Account acc : accountInsertList) {
                ResponseBodyObject newResponse = new ResponseBodyObject();
                if(acc.Id != null) {
                    newResponse.id = acc.Id;
                    newResponse.success = true;
                }
                else {
                    newResponse.success = false;
                    newResponse.message = 'An error ocurred while tring to insert the account with the name ' + acc.Name;
                }
                responseBody.add(newResponse);
            }

            return JSON.serialize(responseBody);
        }
        catch(Exception e) {
            List<ResponseBodyObject> responseBody = new List<ResponseBodyObject>();
            ResponseBodyObject errorResponseBody = new ResponseBodyObject();
            errorResponseBody.message = e.getMessage();
            errorResponseBody.success = false;
            responseBody.add(errorResponseBody);

            return JSON.serialize(responseBody);
        }
    }

    public class AccountRequestBody {
        public AccountDataObject account;
        public CharacterDataObject character;
    }

    public class AccountDataObject {
        public String name;
        public String email;
        public String username;
        public String password;
        public String genre;
        public Date birthdate;
    }

    public class CharacterDataObject {
        public String name;
        public String classId;
        public String raceId;
        public String colorId;
    }

    public class ResponseBodyObject {
        public Boolean success;
        public String message;
        public String id;
    }
}
