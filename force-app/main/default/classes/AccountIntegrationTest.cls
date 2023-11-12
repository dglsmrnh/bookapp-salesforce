@isTest
public with sharing class AccountIntegrationTest {
    @isTest
    public static void testPostAccount() {
        RestRequest testReq = new RestRequest();
        
        Map<String,Id> recTypeMap = new Map<String,Id>();
        for(RecordType recType : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Asset']) {
            recTypeMap.put(recType.Name, recType.Id);
        }

        AccountIntegration.AccountDataObject acc = new AccountIntegration.AccountDataObject();
        acc.birthdate = Date.today();
        acc.email = 'Example@Example.invalid';
        acc.name = 'Carlos';
        acc.username = 'gordox';
        acc.password = 'coxinha123';
        acc.genre = 'Male';
        
        AccountIntegration.CharacterDataObject charac = new AccountIntegration.CharacterDataObject();
        charac.name = 'Amumu';
        charac.classId = 'Class';
        charac.raceId = 'Race';
        charac.colorId = 'Color';

        AccountIntegration.AccountRequestBody reqBodySingle = new AccountIntegration.AccountRequestBody();
        reqBodySingle.account = acc;
        reqBodySingle.character = charac;

        Blob reqBodyRaw = EncodingUtil.base64Decode(JSON.serialize(new List<AccountIntegration.AccountRequestBody>{reqBodySingle}));
        
        testReq.requestBody = reqBodyRaw;
        RestContext.request = testReq;
        String prodResponse = AccountIntegration.postAccountWithCharacter();
    }
}