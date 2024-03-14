import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/BookLead__c.Name";
import getMemoryGameData from '@salesforce/apex/ShadifyAPI.getMemoryGameData';
import createGameMemory from '@salesforce/apex/CreateGameController.createGameMemory';
import { RefreshEvent } from "lightning/refresh";

export default class ConvertBookLead extends LightningElement {
  @api recordId;
  @api objectApiName;

  isShowLoading = false

  @wire(getRecord, { recordId: "$recordId", fields: [NAME_FIELD] })
  bookLead;

  get name() {
    return getFieldValue(this.contbookLeadact.data, NAME_FIELD);
  }

  selectedGameType = '';
  gameTypeOptions = [
      { label: 'Memoria', value: 'Memory' },
      { label: 'Caça-Palavra', value: 'WordSearch' }
  ];

  gameData = {};

  totalPairs = 0;
  @track pairValues = [];
  fileContentVersionIds = new Map();
  
  labels = {
		errorMessage: 'Não foi possível completar a requisição.',
		saveMessage: 'Jogo cadastrado com sucesso.'
	}

  connectedCallback() {
    
  }

  isFileUploaded(pairIndex) {
    return !this.fileContentVersionIds.has(pairIndex);
  }

  handleGameTypeChange(event) {
      this.selectedGameType = event.detail.value;
      console.log('selected data');

      if(this.selectedGameType == 'Memory') {
        this.isShowLoading = true;
        getMemoryGameData({type: this.selectedGameType})
          .then(resolve => {
            this.gameData = resolve;
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
  }

  handleSuccess(e) {
    this.isShowLoading = true;
    if(this.selectedGameType == 'Memory') {
      createGameMemory({recordId: this.recordId, type: this.selectedGameType, gameData: this.gameData, images: this.pairValues })
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