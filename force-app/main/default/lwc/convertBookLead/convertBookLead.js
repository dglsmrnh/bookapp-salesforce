import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/BookLead__c.Name";
import BOOK_FIELD from "@salesforce/schema/BookLead__c.Book__c";
import getMemoryGameData from '@salesforce/apex/ShadifyAPI.getMemoryGameData';
import getWordSearchGameData from '@salesforce/apex/ShadifyAPI.getWordSearchGameData';
import createGame from '@salesforce/apex/CreateGameController.createGame';
import getProductData from '@salesforce/apex/CreateGameController.getProductData';
import { RefreshEvent } from "lightning/refresh";

export default class ConvertBookLead extends LightningElement {
  @api recordId;
  @api objectApiName;
  @track currentStep = 1;
  @track currentCheckpoint = 0;

  isShowLoading = false

  @wire(getRecord, { recordId: "$recordId", fields: [NAME_FIELD, BOOK_FIELD] })
  bookLead;

  get name() {
    return getFieldValue(this.bookLead.data, NAME_FIELD);
  }

  @track bookData;
  @track checkpoints = [];

  @wire(getProductData, { bookLeadId: '$recordId' })
  wiredBookData({ error, data }) {
      if (data) {
          this.bookData = data;
      } else if (error) {
          console.error('Error to see book data! =>', error);
          this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
      }
  }

  get lastStep() {
    return this.currentStep == 2;
  }

  nextStep() {
    this.currentStep += 1;
  }

  prevStep() {
    this.currentStep -= 1;
  }

  selectedGameType = '';
  gameTypeOptions = [
      { label: 'Memoria', value: 'Memory' },
      { label: 'Caça-Palavra', value: 'WordSearch' },
      { label: 'Questionário', value: 'Questions' }
  ];

  get isMemoryGame() {
    return (this.selectedGameType == 'Memory' && ('Memory' in this.gameData));
  }

  get isWordSearchGame() {
    return (this.selectedGameType == 'WordSearch' && ('WordSearch' in this.gameData));
  }

  get isQuestionsGame() {
    return (this.selectedGameType == 'Questions' && ('Questions' in this.gameData));
  }

  gameData = {};

  totalPairs = 0;
  @track pairValues = [];
  fileContentVersionIds = new Map();
  
  labels = {
		errorMessage: 'Não foi possível completar a requisição.',
		saveMessage: 'Jogo cadastrado com sucesso.',
    header: 'Liberar o livro',
    steps: {
      step1: 'Escolher jogo',
      step2: 'Checkpoints'
    }
	}

  isFileUploaded(pairIndex) {
    return !this.fileContentVersionIds.has(pairIndex);
  }

  handleGameTypeChange(event) {
      this.selectedGameType = event.detail.value;
      console.log('selected data');

      if((this.selectedGameType in this.gameData)) {
        return;
      }

      if(this.selectedGameType == 'Memory') {
        this.isShowLoading = true;
        getMemoryGameData({type: this.selectedGameType})
          .then(resolve => {
            this.gameData['Memory'] = resolve;
            this.totalPairs = resolve.totalPairs;
            for(let i = 0; i < this.totalPairs; i++) {
              this.pairValues.push({ value: resolve.pairPositions[i].value, uploaded: false, img: '', contentVersionId: '' }); // Initialize uploaded status as false
            }
          })
          .catch(error => {
            console.log('Error to see game data! =>', error);
            this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
          })
          .finally(() => {
            this.isShowLoading = false;
        });
      }
      else if(this.selectedGameType == 'WordSearch') {
        this.isShowLoading = true;
        getWordSearchGameData({type: this.selectedGameType})
          .then(resolve => {
            this.gameData['WordSearch'] = resolve;
          })
          .catch(error => {
            console.log('Error to see game data! =>', error);
            this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
          })
          .finally(() => {
            this.isShowLoading = false;
        });
      }
  }

  handleChangeSearchGame(event) {
    const newWords = event.detail.value;
    this.gameData['WordSearch'].words = newWords;
    replaceWordsInGrid();
  }

  replaceWordsInGrid() {
    // Iterate through the words
    this.gameData['WordSearch'].words.forEach(wordObj => {
      const startRow = wordObj.position.start[1] - 1; // Adjusting to 0-based index
      const startCol = wordObj.position.start[0] - 1; // Adjusting to 0-based index
      const endRow = wordObj.position.endX[1] - 1; // Adjusting to 0-based index
      const endCol = wordObj.position.endX[0] - 1; // Adjusting to 0-based index
      const word = wordObj.word;

      // Check the direction of the word
      const vertical = startCol === endCol;

      let row = startRow;
      let col = startCol;

      // Replace characters in the grid with the characters of the word
      for (let i = 0; i < word.length; i++) {
        this.gameData['WordSearch'].grid[row][col] = word[i];
          // Move to the next position based on the direction
          if (vertical) {
              if (startRow < endRow) row++; // Move down
              else row--; // Move up
          } else {
              if (startCol < endCol) col++; // Move right
              else col--; // Move left
          }
      }
    });
  }

  handleSliderChange(event) {
    this.currentCheckpoint = event.detail.value;
  }

  handleAddCheckpoint() {
    if(this.currentCheckpoint > 0) {
      this.checkpoints.push(this.currentCheckpoint);
      this.currentCheckpoint = 0;
    }
  }

  handleRemoveCheckpoint(event) {
    event.preventDefault();
    const checkpoint = event.target.dataset.checkpoint;
    this.checkpoints = this.checkpoints.filter(item => item !== checkpoint);
  }

  handleSuccess(e) {
    this.isShowLoading = true;
    createGame({recordId: this.recordId, type: this.selectedGameType, gameData: this.gameData, images: this.pairValues, checkpoints: this.checkpoints })
      .then(resolve => {
        this.handlerDispatchToast(this.labels.saveMessage, '', 'success');
      })
      .catch(error => {
        console.log('Error to saving game data! =>', error);
        this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
      })
      .finally(() => {
        this.isShowLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    });   
  }

  handleUploadFinished(event) {
      console.log(event.detail);
      console.log(event.target.dataset);
      const uploadedFiles = event.detail.files;
      if(uploadedFiles && uploadedFiles.length > 0){
        const file = event.detail.files[0];
        console.log(file);
        const pairIndex = this.pairValues.findIndex(pair => pair.value === event.target.dataset.pair);
        if (pairIndex !== -1 && file) {
          console.log(pairIndex);
          this.fileContentVersionIds.set(event.target.dataset.pair, file.contentVersionId);
          this.pairValues[pairIndex].uploaded = true;
          this.pairValues[pairIndex].img = file.name;
          this.pairValues[pairIndex].contentVersionId = file.contentVersionId;
        }
      }
  }

  handlerDispatchToast(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant
			})
		);
	}

}