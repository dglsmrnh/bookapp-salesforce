import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBooksData from '@salesforce/apex/GoogleBooksAPI.getBooksData';

export default class PaginationScreen extends LightningElement {

	searchTerm = '';

	currentIndex = 0;

	labels = {
		errorMessage: 'Não foi possível continuar'
	}

	@track
	bookList = [];
	
	isShowLoading = false;

	@track
	isShowSeeMoreButton = false;

	getParentIdRecursive(element) {
		if (!element.dataset?.id) return this.getParentIdRecursive(element.parentElement);
		else return element.dataset.id;
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

	searchProducts(clear) {
		if(clear) {
			this.currentIndex = 0;
			this.bookList = [];

			if(this.searchTerm.length <= 0) {
				return;
			}
		} 
		else {
			console.log(this.bookList.length);
			this.currentIndex += this.bookList.length;
		}

		this.isShowLoading = true;

		getBooksData({ queryString: this.searchTerm, startIndex: this.currentIndex })
			.then(resolve => {
				if (resolve.totalItems > 0 && resolve.items != null ) {
					this.isShowSeeMoreButton = true;
					if(clear) {
						this.bookList = [...resolve.items];
					} 
					else {
						this.bookList = [...this.bookList, ...resolve.items];
					}

					if (resolve.totalItems < this.currentIndex + 1) {
						this.isShowSeeMoreButton = false;
					}
				}
				else {
					this.isShowSeeMoreButton = false;
				}
			})
			.catch(error => {
				console.log('Error to see more products! =>', error);
				this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
			})
			.finally(() => {
				this.isShowLoading = false
				console.log(this.bookList);
				console.log(this.isShowSeeMoreButton);
			});
	}

	handleKeyUp(event) {
		const isEnterKey = event.keyCode === 13;
		console.log(event.target.value);
		if (isEnterKey) {
			this.searchTerm = event.target.value;
			this.searchProducts(true);
		}
	}

	handleSearch(event) {
		this.searchProducts(true);
	}

	handleSearchMore() {
		if(this.searchTerm.length > 0) {
			this.searchProducts(false);
		}
	}
}
