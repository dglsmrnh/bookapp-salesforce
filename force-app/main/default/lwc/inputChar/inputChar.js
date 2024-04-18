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
            // Dispara um evento customizado com as palavras atualizadas
            const changeEvent = new CustomEvent('wordchange', {
                detail: {value: newValue, index: changedIndex, word: this.word }
            });
            this.dispatchEvent(changeEvent);
        }

        
    }
}