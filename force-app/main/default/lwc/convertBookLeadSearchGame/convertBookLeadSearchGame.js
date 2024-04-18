import { LightningElement, api } from 'lwc';

export default class ConvertBookLeadSearchGame extends LightningElement {
    @api gameData;
    
    get words() {
        return this.gameData['WordSearch'].words;
    }

    handleChange(event) {
        const changedIndex = event.detail.index;
        const newValue = event.detail.value;
        const oldWord = event.detail.word;

        // Atualiza o valor do caractere correspondente na palavra correta no array words
        let words = this.gameData['WordSearch'].words.map(wordObj => {
            if(wordObj.word == oldWord) {
                const splitWord = wordObj.word.split('').map((char, index) => ({ value: char, index }));
                splitWord[changedIndex].value = newValue;
                console.log('wordObj1=>', wordObj);
                return { ...wordObj, word: splitWord.map(char => char.value).join('') };
            } else {
                console.log('wordObj2=>', wordObj);
                return { ...wordObj };
            }
        });

        // Dispara um evento customizado com as palavras atualizadas
        const changeEvent = new CustomEvent('wordsearchchange', {
            detail: {value: words }
        });
        this.dispatchEvent(changeEvent);
    }
}