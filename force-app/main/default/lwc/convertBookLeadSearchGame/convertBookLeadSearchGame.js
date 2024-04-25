import { LightningElement, api } from 'lwc';

export default class ConvertBookLeadSearchGame extends LightningElement {
    @api gameData;
    
    get words() {
        return this.gameData['WordSearch'].words;
    }

    handleChange(event) {
        const changedIndex = event.detail.index;
        const newValue = event.detail.value;
        const oldWord = event.detail.oldWord;
        const newWord = event.detail.word;

        let words = [];
        // Atualiza o valor do caractere correspondente na palavra correta no array words
        try {
            this.gameData['WordSearch'].words.forEach((wordObj, index) => {

                // If the word matches the old word, update it with the new word
                if (wordObj.word === oldWord) {
                    words.push({ index: index, word: newWord });
                }
            });
        } catch (error) {
            console.error('An error occurred while updating the word:', error.message);
        }

        //Dispara um evento customizado com as palavras atualizadas
        const changeEvent = new CustomEvent('wordsearchchange', {
            detail: {words: words }
        });
        this.dispatchEvent(changeEvent);
    }
}