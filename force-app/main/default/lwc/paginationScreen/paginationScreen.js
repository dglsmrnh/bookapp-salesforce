import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBooksData from '@salesforce/apex/GoogleBooksAPI.getBooksData';

export default class PaginationScreen extends LightningElement {

	@track 
	searchTerm = '';

	currentIndex = 0;

	@track
	bookList = [];
	
	isShowLoading = false;

	@track
	isShowSeeMoreButton = false;

	connectedCallback() {
	}

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

	handleChange(event) {
		this.searchTerm = event.target.value;
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
			this.currentIndex += bookList.length;
		}

		getBooksData({ queryString: this.searchTerm, startIndex: this.currentIndex })
			.then(resolve => {
				if (resolve.totalItems > 0) {
					this.isShowSeeMoreButton = true;
					if(clear) {
						this.bookList = resolve.items;
					} 
					else {
						this.bookList = [...this.bookList, ...resolve.items];
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
			.finally(() => this.isShowLoading = false);
	}

	handleKeyDown(event) {
		if (event.key === 'Enter') {
			this.searchProducts(true);
		}
	}

	handleSearchMore(event) {
		if(this.searchTerm.length > 0) {
			this.searchProducts(false);
		}
	}
}
