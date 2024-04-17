/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 04-16-2024
 * @last modified by  : dglsmrnh
**/
@RestResource(urlMapping='/predict')
global with sharing class ScoreIntegration {

    global class Request {
        global String excerpt;
    }

    global class Response {
        global Decimal probability { get; set; }
        global Features features { get; set; }
   
        global Response(Decimal probability, Decimal flesch, Decimal gulpease, Decimal colemanLiau, Decimal ari) {
            this.probability = probability;
            this.features = new Features(flesch, gulpease, colemanLiau, ari);
        }
    }

    global class Features {
        global Decimal flesch { get; set; }
        global Decimal gulpease { get; set; }
        global Decimal colemanLiau { get; set; }
        global Decimal ari { get; set; }
    
        global Features(Decimal flesch, Decimal gulpease, Decimal colemanLiau, Decimal ari) {
            this.flesch = flesch;
            this.gulpease = gulpease;
            this.colemanLiau = colemanLiau;
            this.ari = ari;
        }
    }
    
   
    private static Integer countCharacters(String text) {
        Integer numCharacters = 0;
        
        // Define valid characters
        String validCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789!@#$%^&*()_+={[}]|\\:;\'<,>.?/';
        
        for (Integer i = 0; i < text.length(); i++) {
            // Check if the character is a valid character
            if (validCharacters.contains(text.substring(i, i+1))) {
                // Increment the count for each valid character
                numCharacters++;
            }
        }
        
        return numCharacters;
    }
    
    private static Integer countWords(String text) {
        Integer numWords = 0;
        
        // Define word delimiters
        String[] wordDelimiters = new String[] {' ', '\n'};
        
        for (Integer i = 0; i < text.length(); i++) {
            // Increment the count if the current character is a word delimiter and the previous character is not a delimiter or a hyphen
            if (wordDelimiters.contains(text.substring(i, i+1)) && !wordDelimiters.contains(text.substring(Math.max(i - 1, 0), i)) && text.substring(Math.max(i - 1, 0), i) != '-') {
                numWords++;
            }
        }
        
        // Increment the count for the last word if the text doesn't end with a delimiter
        if (!wordDelimiters.contains(text.substring(text.length() - 1))) {
            numWords++;
        }
        
        return numWords;
    }
    
    private static Integer countSentences(String text) {
        Integer numSentences = 0;
        
        // Define sentence delimiters
        String[] sentenceDelimiters = new String[] {'.', '!', '?', ';'};
        
        for (Integer i = 0; i < text.length(); i++) {
            // Increment the count if the current character is a sentence delimiter and the previous character is not a sentence delimiter
            if (sentenceDelimiters.contains(text.substring(i, i+1)) && !sentenceDelimiters.contains(text.substring(Math.max(i - 1, 0), i))) {
                numSentences++;
            }
        }
        
        return numSentences;
    }
    
    private static Integer countSyllables(String word) {
        Integer numSyllables = 0;
        
        // Define vowels, diphthongs, and triphthongs in Portuguese
        Set<String> vowels = new Set<String>{'a', 'ã', 'â', 'á', 'à', 'e', 'é', 'ê', 'i', 'í', 'o', 'ô', 'õ', 'ó', 'u', 'ú'};
        Set<String> diphthongs = new Set<String>{'ãe', 'ai', 'ão', 'au', 'ei', 'eu', 'éu', 'ia', 'ie', 'io', 'iu', 'õe', 'oi', 'ói', 'ou', 'ua', 'ue', 'uê', 'ui'};
        Set<String> triphthongs = new Set<String>{'uai', 'uei', 'uão', 'uõe', 'uiu', 'uou'};
        
        // Convert word to lowercase for easier comparison
        word = word.toLowerCase();
        
        // Counting syllables
        for (Integer i = 0; i < word.length(); i++) {
            String charAtIndex = String.valueOf(word.substring(i, i+1));
            if (vowels.contains(charAtIndex)) {
                // Increment syllable count only if it's the first vowel in a sequence
                if (i == 0 || !vowels.contains(String.valueOf(word.substring(i - 1, i)))) {
                    numSyllables++;
                }
            }
            
            // Handling diphthongs
            if (i > 0 && diphthongs.contains(word.substring(Math.max(i - 1, 0), i + 1))) {
                numSyllables--;
            }
            
            // Handling triphthongs
            if (i > 1 && triphthongs.contains(word.substring(Math.max(i - 2, 0), i + 1))) {
                numSyllables--;
            }
        }
        
        // A syllable should always have at least one vowel
        return Math.max(numSyllables, 1);
    }
    
    private static Decimal fleschReadingEase(Integer numWords, Integer numSentences, Integer numSyllables) {
        // Flesch-Kincaid
        Decimal score = (0.36 * (numWords / numSentences)) + (10.4 * (numSyllables / numWords)) - 18;
        return score;
    }
    
    private static Decimal indiceGulpease(Integer numChars, Integer numWords, Integer numSentences) {
        Decimal indice = 89 + (300 * (numSentences / numWords)) - (10 * (numChars / numWords));
        return indice;
    }
    
    private static Decimal colemanLiau(Integer numChars, Integer numWords, Integer numSentences) {
        // Coleman-Liau index formula
        Decimal index = 5.4 * (numChars / numWords) - 21 * (numSentences / numWords) - 14;
        return index;
    }
    
    private static Decimal automatedReadabilityIndex(Integer numChars, Integer numWords, Integer numSentences) {
        // Calculate ARI formula
        Decimal ari = 0.44 * (numWords / numSentences) + 4.6 * (numChars / numWords) - 20;
        return ari;
    }  
    
    @HttpPost
    global static Response predict(String excerpt) {

        String text = excerpt;
       
        // Calculate readability features from the text
        Integer numChars = countCharacters(text);
        Integer numWords = countWords(text);
        Integer numSentences = countSentences(text);
        Integer numSyllables = countSyllables(text);
        Decimal flesch = fleschReadingEase(numWords, numSentences, numSyllables);
        Decimal gulpease = indiceGulpease(numChars, numWords, numSentences);
        Decimal colemanliau = colemanLiau(numChars, numWords, numSentences);
        Decimal ari = automatedReadabilityIndex(numChars, numWords, numSentences);

        Decimal probability = (flesch + ari + colemanliau) / 3;
        
        // Create a TextAnalyzerResponse object
        Response response = new Response(probability, flesch, gulpease, colemanliau, ari);
        
        // Return the response as JSON
        return response;
    }
}