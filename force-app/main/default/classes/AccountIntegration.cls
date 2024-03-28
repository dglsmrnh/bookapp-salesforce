/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 02-25-2024
 * @last modified by  : dglsmrnh
**/
@RestResource(urlMapping='/account')
global with sharing class AccountIntegration {

    global static final Id ASSET_CLASS_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id PRODUCT_CLASS_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Class').getRecordTypeId();
    global static final Id ASSET_COLOR_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Color').getRecordTypeId();
    global static final Id PRODUCT_COLOR_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Color').getRecordTypeId();
    global static final Id ASSET_RACE_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id PRODUCT_RACE_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Race').getRecordTypeId();
    global static final Id ASSET_ATTRIBUTE_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id PRODUCT_ATTRIBUTE_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Attribute').getRecordTypeId();
    global static final Id ASSET_BOOK_RECORDTYPE = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Book').getRecordTypeId();
    global static final Id PRODUCT_BOOK_RECORDTYPE = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Book').getRecordTypeId();

    @HttpPost
    global static PostResponseBodyObject postAccountWithCharacter(PostRequestBody request) {
        try {
            Set<String> productCodeList = new Set<String>();            
            productCodeList.add(request.character.classId);
            productCodeList.add(request.character.raceId);
            productCodeList.add(request.character.colorId);

            Account newAccount = request.account.serializeAccount();
            Database.upsert(newAccount, Account.Username__c);

            Map<String, Asset> assetInsertMap = request.character.serializeAssets(newAccount, request.account.username);
            Database.UpsertResult[] resultList = Database.upsert(assetInsertMap.values(), Asset.ExternalId__c);

            newAccount.DefaultClass__c = assetInsertMap.get('Class').Id;
            newAccount.DefaultRace__c = assetInsertMap.get('Race').Id;
            newAccount.DefaultColor__c = assetInsertMap.get('Color').Id;
            update newAccount;
            
            PostResponseBodyObject newResponse = new PostResponseBodyObject();
            newResponse.id = newAccount.Id;            

            return newResponse;
        }
        catch(Exception e) {
            return new PostResponseBodyObject(e.getMessage());
        }
    }

    @Httpget
    global static GetResponseBodyObject getAccountAndCharacter() {
        try {
            GetResponseBodyObject responseBody = new GetResponseBodyObject();
            RestRequest thisReq = RestContext.request;
            Map<String, String> requestParams = thisReq.params;
            
            if(!requestParams.containsKey('username')) {
                throw new CalloutException('The parameter "username" could not be found on your request.');
            }
            
            String username = requestParams.get('username');
            String fields = String.join(IntegrationUtils.getFields('Account'), ', ');
            String query = 'SELECT ' + fields + ' FROM Account WHERE Username__c =: username';            
            List<Account> accountList = Database.query(query);

            if(accountList.size() <= 0) {
                throw new CalloutException('No account with the username ' + username + ' could be found.');
            }

            String assetFields = String.join(IntegrationUtils.getFields('Asset'), ', ');
            String assetQuery = 'SELECT ' + assetFields + ' FROM Asset WHERE Account.Username__c = \'' + username + '\'';
            List<Asset> assetList = Database.query(assetQuery);

            Map<Id, Asset> assetMap = new Map<Id, Asset>();

            for(Asset asset : assetList) {
                assetMap.put(asset.Product2Id, asset);
            }

            String productFields = String.join(IntegrationUtils.getFields('Product2'), ', ');
            String productQuery = 'SELECT ' + productFields + ' FROM Product2 WHERE Id IN (SELECT Product2Id FROM Asset WHERE Account.Username__c = \'' + username + '\')';
            List<Product2> productList = Database.query(productQuery);

            List<AssetData> questList = new List<AssetData>();
            List<AssetData> attrList = new List<AssetData>();
            Map<Id, AssetData> assetDataMap = new Map<Id, AssetData>();

            for(Product2 prd : productList) {
                assetDataMap.put(assetMap.get(prd.Id).Id, new AssetData(assetMap.get(prd.Id), prd));

                if(prd.RecordTypeId == PRODUCT_BOOK_RECORDTYPE) {
                    questList.add(new AssetData(assetMap.get(prd.Id), prd));
                }

                if(prd.RecordTypeId == PRODUCT_ATTRIBUTE_RECORDTYPE) {
                    attrList.add(new AssetData(assetMap.get(prd.Id), prd));
                }
            }

            String inventoryFields = String.join(IntegrationUtils.getFields('Inventory__c'), ', ');
            String inventoryQuery = 'SELECT ' + inventoryFields + ' FROM Inventory__c WHERE Account__r.Username__c = \'' + username + '\'';
            List<Inventory__c> inventoryList = Database.query(inventoryQuery);

            String inventoryItemFields = String.join(IntegrationUtils.getFields('InventoryItem__c'), ', ');
            String inventoryItemQuery = 'SELECT ' + inventoryItemFields + ' FROM InventoryItem__c WHERE Inventory__c IN: inventoryList';
            List<InventoryItem__c> inventoryItemList = Database.query(inventoryItemQuery);
            
            InventoryData invData = new InventoryData();
            if(inventoryList.size() > 0) {
                Inventory__c firstReturned = inventoryList[0];
                invData.coins = Integer.valueOf(firstReturned.Coins__c);
                invData.id = firstReturned.Id;
                for(InventoryItem__c item : inventoryItemList) {
                    InventoryItemData itemData = new InventoryItemData();
                    itemData.color = item.Color__c;
                    itemData.id = item.Id;
                    itemData.quantity = Integer.valueOf(item.Quantity__c);
                    invdata.items.add(itemData);
                }
            }

            for(Account acc : accountList) {
                responseBody.account.serializeAccountData(acc);
                responseBody.character.serializeAssetData(acc, assetDataMap, questList, attrList, invData);
            }

            return responseBody;
        }
        catch (Exception e) {
            return new GetResponseBodyObject(e.getMessage());
        }
    }

    global class AccountDataObject {
        global String name;
        global String email;
        global String username;
        global String password;
        global String gender;
        global Date birthdate;

        public Account serializeAccount() {
            Account newAccount = new Account();
            newAccount.Name = this.name;
            //newAccount.CharacterName__c = request.character.name;
            newAccount.Email__c = this.email;
            newAccount.Gender__c = this.gender;
            newAccount.Birthday__c = this.birthdate;
            newAccount.Username__c = this.username;
            newAccount.Password__c = this.password;

            return newAccount;
        }

        public void serializeAccountData(Account acc) {
            this.name = acc.Name;
            this.email = acc.Email__c;
            this.username = acc.Username__c;
            this.password = acc.Password__c;
            this.gender = acc.Gender__c;
            this.birthdate = acc.Birthday__c;
        }
    }

    global class AssetData {
        global String id;
        global Asset asset;
        global Product2 product;

        public AssetData(Asset asset, Product2 product) {
            this.id = asset.Id;
            this.asset = asset;
            this.product = product;
        }
    }

    global class CharacterDataObject {
        global String name;
        global String classId;
        global String raceId;
        global String colorId;
        global Integer level;
        global Boolean levelUp;
        global Integer xp;
        global Integer bonusXp;
        global Integer lostXp;
        global Integer level_cap;
        global Integer coins;
        global Integer attribute_points;
        global AssetData c_class;
        global AssetData race;
        global AssetData color;
        global List<AssetData> attributes;
        global InventoryData inventory;
        global List<AssetData> quests;

        public Map<String, Asset> serializeAssets(Account newAccount, String username) {
            Map<String, Asset> assetInsertMap = new  Map<String, Asset>();

            if(String.isNotBlank(this.classId)) {
                Asset classAsset = new Asset();
                classAsset.AccountId = newAccount.Id;
                classAsset.Name = this.classId + username;
                classAsset.Product2Id = Id.valueOf(this.classId);
                classAsset.ExternalId__c = this.classId + username;
                classAsset.RecordTypeId = ASSET_CLASS_RECORDTYPE;
                assetInsertMap.put('Class', classAsset);
            }

            if(String.isNotBlank(this.raceId)) {
                Asset raceAsset = new Asset();
                raceAsset.AccountId = newAccount.Id;
                raceAsset.Name = this.classId + username;
                raceAsset.Product2Id = Id.valueOf(this.raceId);
                raceAsset.ExternalId__c = this.raceId + username;
                raceAsset.RecordTypeId = ASSET_RACE_RECORDTYPE;
                assetInsertMap.put('Race', raceAsset);
            }

            if(String.isNotBlank(this.colorId)) {
                Asset colorAsset = new Asset();
                colorAsset.AccountId = newAccount.Id;
                colorAsset.Name = this.classId + username;
                colorAsset.Product2Id = Id.valueOf(this.colorId);
                colorAsset.ExternalId__c = this.colorId + username;
                colorAsset.RecordTypeId = ASSET_COLOR_RECORDTYPE;
                assetInsertMap.put('Color', colorAsset);
            }

            return assetInsertMap;
        }

        public void serializeAssetData(Account acc, Map<Id, AssetData> assetDataMap, List<AssetData> questList, List<AssetData> attrList, InventoryData inv) {
            this.c_class = acc.DefaultClass__c != null ? assetDataMap.get(acc.DefaultClass__c) : null;
            this.race = acc.DefaultRace__c != null ? assetDataMap.get(acc.DefaultRace__c) : null;
            this.color = acc.DefaultColor__c != null ? assetDataMap.get(acc.DefaultColor__c) : null;
            this.inventory = inv;
            this.attributes = questList.size() > 0 ? questList : null;
            this.quests = attrList.size() > 0 ? attrList : null;
        }
    }

    global class PostRequestBody {
        global AccountDataObject account;
        global CharacterDataObject character;
    } 

    global class PostResponseBodyObject {
        global Boolean success;
        global String message;
        global String id;

        global PostResponseBodyObject() {
            this.success = true;
        }
        
        global PostResponseBodyObject(String message) {
            this.success = false;
            this.message = message;
        }
    }

    global class GetResponseBodyObject {
        global Boolean success;
        global String message;
        global AccountDataObject account = new AccountDataObject();
        global CharacterDataObject character = new CharacterDataObject();

        global GetResponseBodyObject() {
            this.success = true;
        }

        global GetResponseBodyObject(String message) {
            this.success = false;
            this.message = message;
        }
    }

    global class InventoryData {
        global String id;
        global Integer coins;
        global List<InventoryItemData> items = new List<InventoryItemData>();
    }

    global class InventoryItemData {
        global String id;
        global Integer quantity;
        global String color;
    }

    private class AccountException extends Exception {
    }
}