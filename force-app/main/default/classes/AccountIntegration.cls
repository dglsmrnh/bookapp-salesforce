@RestResource(urlMapping='/account')
global with sharing class AccountIntegration {
    global static final Id ATTRIBUTE_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id ATTRIBUTE_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id BOOK_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Book').getRecordTypeId();
    global static final Id BOOK_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId();
    global static final Id CLASS_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id CLASS_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id DEVICE_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Device').getRecordTypeId();
    global static final Id DEVICE_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Device').getRecordTypeId();
    global static final Id RACE_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id RACE_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id SKILL_ASSET_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Skill').getRecordTypeId();
    global static final Id SKILL_PRODUCT_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Skill').getRecordTypeId();
    global static final String assetFields = String.join(IntegrationUtils.getFields('Asset'), ', ');

    @HttpGet
    global static RestResponse getAccounts() {
        RestRequest req = RestContext.request;

        if(!req.params.containsKey('username')) {
            throw new CharacClassException('username parameter not found.');
        }
        String username = req.params.get('username');

        if([SELECT Id FROM Account WHERE Username__c =: username].size() < 1) {
            throw new CharacClassException('username\'s account not found.');
        }

        String accFields = String.join(IntegrationUtils.getFields('Account'), ', ');
        String accQuery = 'SELECT ' + accFields + ' FROM Account WHERE isActive = true AND Username__c =: username';
        Account acc = Database.query(accQuery)[0];
        ReqAccount accReq = new ReqAccount(acc);

        String raceQuery = 'SELECT ' + assetFields + ' FROM Asset WHERE RecordTypeId =: RACE_ASSET_RECORDTYPE AND Product2.RecordTypeId =: RACE_PRODUCT_RECORDTYPE AND IsActive = true AND AccountId =: acc.Id';
        List<Asset> raceList = Database.query(raceQuery);
        ReqRace race = new ReqRace();
        if(raceList.size() > 0) {
            race.id = raceList[0].Id;
            race.name = raceList[0].Product2.Name;
        }

        String classQuery = 'SELECT ' + assetFields + ' FROM Asset WHERE RecordTypeId =: CLASS_ASSET_RECORDTYPE AND Product2.RecordTypeId =: CLASS_PRODUCT_RECORDTYPE AND IsActive = true AND AccountId =: acc.Id';
        List<Asset> classList = Database.query(classQuery);
        ReqClass classR = new ReqClass();
        if(classList.size() > 0) {
            classR.id = classList[0].Id;
            classR.name = classList[0].Product2.Name;
        }

        List<ReqQuest> questList = new List<ReqQuest>();
        String questQuery = 'SELECT ' + assetFields + ' FROM Asset WHERE RecordTypeId =: BOOK_ASSET_RECORDTYPE AND RecordTypeId =: BOOK_PRODUCT_RECORDTYPE AND IsActive = true AND AccountId =: acc.Id';
        for(Asset asst : Database.query(questQuery)) {
            ReqQuest quest = new ReqQuest();
            quest.id = classList[0].Id;
            quest.name = classList[0].Product2.Name;
            questList.add(quest);
        }

        String attrQuery = 'SELECT ' + assetFields + ' FROM Asset WHERE RecordTypeId =: ATTRIBUTE_ASSET_RECORDTYPE AND RecordTypeId =: ATTRIBUTE_PRODUCT_RECORDTYPE AND IsActive = true AND AccountId =: acc.Id';
        List<ReqAttribute> attrList = new List<ReqAttribute>();
        for(Asset asst : Database.query(attrQuery)) {
            ReqAttribute attr = new ReqAttribute();
            attr.id = attrList[0].Id;
            attr.name = attrList[0].Product2.Name;
            attrList.add(attr);
        }

        String charFields = String.join(IntegrationUtils.getFields('Character__c'), ', ');
        String charQuery = 'SELECT ' + charFields + ' FROM Character__c WHERE isActive = true AND Account__c =: acc.Id';
        List<Character__c> charList = Database.query(charQuery);
        ReqCharacter charR;

        if(charList.size() > 0) {
            charR = new ReqCharacter(charList[0], classR, race, new ReqColor(), attrList, new List<ReqInventory>(), questList);
        }
        else {
            charR = new ReqCharacter();
        }

        PostRes respns = new PostRes(accReq, charR);
        return respns;
    }

    @HttpPost
    global static RestResponse saveInfoFromAccountAndCharacter() {
        PostReq requestBody = (PostReq)JSON.deserialize(RestContext.request.requestBody, requestBody);

        
    }

    public class PostRes{
        public boolean success;
        public String message;
        public ReqAccount account;
        public ReqCharacter character;

        public PostRes(ReqAccount acc, ReqCharacter char) {
            this.success = true;
            this.message = 'The account was created successfuly.';
            this.account = acc;
            this.character = char;
        }
    }

    public class PostReq{
        public ReqAccount account;
        public ReqCharacter character;
    }

    public class ReqAccount{
        public String email;
        public String username;
        public String password;
        public String genre;
        public String birthdate;
        public String name;

        public ReqAccount(Account acc) {
            this.email = acc.Email__c;
            this.username = acc.Username__c;
            this.password = acc.Password__c;
            this.genre = acc.Gender__c;
            this.birthdate = acc.Birthday__c;
            this.name = acc.Name;
        }
    }
    
    public class ReqCharacter{
        public String name;
        public ReqClass myclass;
        public ReqRace race;
        public ReqColor color;
        public String level;
        public String levelUp;
        public String xp;
        public String bonusXp;
        public String lostXp;
        public String level_cap;
        public String coins;
        public String attribute_points;
        public List<ReqAttribute> attributes = new List<ReqAttribute>();
        public List<ReqInventory> inventory = new List<ReqInventory>();
        public List<ReqQuest> quests = new List<ReqQuest>();

        public ReqCharacter(Character__c charR, ReqClass classR, ReqRace race, 
                            ReqColor color, List<ReqAttribute> attributes, 
                            List<ReqInventory> inventory, List<ReqQuest> quests) {
            this.name = charR.Name;
            this.class = classR;
            this.race = race;
            this.color = color;
            this.level = charR.Level__c;
            //this.levelUp = charR.LevelUp__c;
            //this.xp = charR.Xp__c;
            //this.bonusXp = charR.bonusXp;
            //this.lostXp = charR.lostXp;
            //this.level_cap = charR.level_cap;
            //this.coins = charR.coins;
            //this.attribute_points = charR.attribute_points;
            this.attributes = attributes;
            this.inventory = inventory;
            this.quests = quests;
        }

        public ReqCharacter() {}
    }
    
    public class ReqClass{
        public String id;
        public String name;
    }

    public class ReqRace{
        public String id;
        public String name;
    }
    
    public class ReqColor{
        public String id;
        public String name;
    }

    public class ReqAttribute{
        public String id;
        public String name;
    }
    
    public class ReqInventory{
        public String id;
        public String name;
    }
    
    public class ReqQuest{
        public String id;
        public String name;
    }
}

/*
{
    "success": true,
    "message": "<string>",
    "account": {
        "email": "<string>",
        "username": "<string>",
        "password": "<string>",
        "genre": "<string>",
        "birthdate": "<string>",
        "name": "<string>"
    },
    "character": {
        "name": "<string>",
        "class": {
        "id": "<string>",
        "product": {
            "id": "<string>"
        }
        },
        "race": {
        "id": "<string>",
        "product": {
            "id": "<string>"
        }
        },
        "color": {
        "id": "<string>",
        "product": {
            "id": "<string>"
        }
        },
        "level": "<integer>",
        "levelUp": "<boolean>",
        "xp": "<integer>",
        "bonusXp": "<integer>",
        "lostXp": "<integer>",
        "level_cap": "<integer>",
        "coins": "<integer>",
        "attribute_points": "<integer>",
        "attributes": [
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        },
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        }
        ],
        "inventory": [
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        },
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        }
        ],
        "quests": [
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        },
        {
            "id": "<string>",
            "product": {
            "id": "<string>"
            }
        }
        ]
    }
}
*/