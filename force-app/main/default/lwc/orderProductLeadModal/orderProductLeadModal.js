import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBookScore from '@salesforce/apex/BookScoreAPI.getBookScore';
import addBook from '@salesforce/apex/PaginationScreenController.addBook';

export default class OrderProductLeadModal extends LightningModal {
  @api book;
  @track excerpt;

  @track score;

	isShowLoading = false;

  labels = {
		errorMessage: 'Não foi possível completar a requisição.',
		saveMessage: 'Livro salvo com sucesso.'
	}

  handleOkay() {
		this.isShowLoading = true;
		console.log(this.book);
		addBook({ bookItem: this.book, bookExcerpt: this.excerpt, score: this.score })
			.then(resolve => {
				if(resolve.success == true) {
					this.handlerDispatchToast(this.labels.saveMessage, '', 'success');
					this.close('okay');
				}
				else {
					this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
				}
			})
			.catch(error => {
				console.log('Error to save book! =>', error);
				this.handlerDispatchToast(error.body.message, '', 'error');
			})
			.finally(() => {
				this.isShowLoading = false;
			});
  }

  handleSearch() {
		this.isShowLoading = true;
    getBookScore({ excerpt: this.excerpt })
			.then(resolve => {
				console.log(resolve);
				this.score = resolve;
			})
			.catch(error => {
				console.log('Error to see score! =>', error);
				this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
			})
			.finally(() => {
				this.isShowLoading = false;
			});
  }

	handleTextAreaChange(event) {
		this.excerpt = event.detail.value;
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