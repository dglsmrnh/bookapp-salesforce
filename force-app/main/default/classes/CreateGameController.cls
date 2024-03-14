/**
 * @description       : 
 * @author            : douglas.marinho@globant.com
 * @group             : 
 * @last modified on  : 03-14-2024
 * @last modified by  : douglas.marinho@globant.com
**/
public with sharing class CreateGameController {
    @AuraEnabled
    public static Boolean createGameMemory(String recordId, ShadifyAPI.MemoryGameResponse gameData, List<PairValues> images){
        
        try {
            if(gameData.totalPairs != images.size()) {
                throw new AuraHandledException('Não foram informadas todas as imagens.');
            }

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
}