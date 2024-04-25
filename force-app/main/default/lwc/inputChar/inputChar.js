import { LightningElement, api } from 'lwc';

export default class InputChar extends LightningElement {
    @api word;

    get charWord() {
        // Converte a palavra em uma matriz de caracteres, cada um com um índice associado
        return this.word.split('').map((char, index) => ({ value: char, index }));
    }

    handleChange(event) {
        const changedIndex = event.target.dataset.index;
        const newValue = event.target.value;

        if(newValue != null && newValue != '') {
            let oldWord = this.word;
            const splitWord = this.word.split('').map((char, index) => ({ value: char, index }));
            splitWord[changedIndex].value = newValue;
            this.word = splitWord.map(char => char.value).join('');
            // Dispara um evento customizado com as palavras atualizadas
            const changeEvent = new CustomEvent('wordchange', {
                detail: {value: newValue, index: changedIndex, word: this.word, oldWord: oldWord }
            });
            this.dispatchEvent(changeEvent);
        }

        
    }
}