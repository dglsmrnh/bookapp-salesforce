/**
 * @description       : 
 * @author            : douglas.marinho@globant.com
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : dglsmrnh
**/
public with sharing class CreateGameController {
    @AuraEnabled
    public static Boolean createGameMemory(String recordId, ShadifyAPI.MemoryGameResponse gameData, List<PairValues> images, List<String> checkpoints){
        
        try {
            if(gameData.totalPairs != images.size()) {
                throw new AuraHandledException('Não foram informadas todas as imagens.');
            }

            // if(checkpoints.isEmpty()) {
            //     throw new AuraHandledException('Não foram informados os checkpoints.');
            // }

            for(ShadifyAPI.PairPosition pair : gameData.pairPositions) {
                for(PairValues pairValue : images) {
                    if(pairValue.value == pair.value) {
                        pair.contentVersionId = pairValue.contentVersionId;
                    }
                }
            }

            BookLead__c bk = [SELECT Id, Book__c, isAvailableToPublish__c FROM BookLead__c WHERE Id =: recordId LIMIT 1];
            String jsonString = JSON.serialize(gameData);
            Games__c game = new Games__c();
            game.BookLead__c = bk.Id;
            game.Book__c = bk.Book__c;
            game.Payload__c = jsonString;
            game.Type__c = 'Memory';
            
            insert game;

            if(bk.isAvailableToPublish__c != true) {
                bk.isAvailableToPublish__c = true;
                update bk;
            }

            List<BookCheckpoint__c> bookCheckList = new List<BookCheckpoint__c>();

            for(String checkpoint : checkpoints) {
                BookCheckpoint__c bookCheck = new BookCheckpoint__c();
                bookCheck.Book__c = bk.Book__c;
                bookCheck.Page__c = Integer.valueOf(checkpoint);

                bookCheckList.add(bookCheck);
            }

            if(!bookCheckList.isEmpty()) {
                insert bookCheckList;
            }

            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class PairValues {
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public Boolean uploaded {get;set;}
        @AuraEnabled
        public String img {get;set;}
        @AuraEnabled
        public String contentVersionId {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static Product2 getProductData(String bookLeadId) {
        BookLead__c bk = [SELECT Id, Book__c FROM BookLead__c WHERE Id =: bookLeadId];
        Product2 product = [SELECT Id, PageCount__c FROM Product2 WHERE Id =: bk.Book__c];
        return product;
    }
}