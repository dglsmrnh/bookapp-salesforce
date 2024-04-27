/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : dglsmrnh
**/
@RestResource(urlMapping='/game')
global with sharing class GameIntegration {
    @HttpGet
    global static Response getGamesFromBook() {
        RestRequest req = RestContext.request;
        if(!req.params.containsKey('isbn')) {
            return new Response(false, 'Parameter missing: ISBN');
        }
        String isbnValue = req.params.get('isbn');

        List<Games__c> gameList = [SELECT Id, Payload__c, Type__c FROM Games__c WHERE Book__r.ISBN_10__c =: isbnValue OR Book__r.ISBN_13__c =: isbnValue];
        // List<String> games = new List<String>();
        // for(Games__c gam : gameList) {
        //     games.add(gam.Payload__c);
        // }

        return new Response(true, gameList);
    }

    global class Response {
        @AuraEnabled
        global Boolean success { get; set; }
        @AuraEnabled
        global String message {get; set; }
        @AuraEnabled
        global List<Games__c> games {get; set; }

        global Response(Boolean success, String message) {
            this.success = success;
            this.message = message;
            this.games = null;
        }

        global Response(Boolean success, List<Games__c> games) {
            this.success = success;
            this.message = null;
            this.games = games;
        }
    }
}