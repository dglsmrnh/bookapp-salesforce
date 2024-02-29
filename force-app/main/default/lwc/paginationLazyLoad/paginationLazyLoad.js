import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getProducts from '@salesforce/apex/PaginationScreenController.getProducts';

export default class PaginationLazyLoad extends LightningElement {
	@track
	productList = [];

	isSearchMoreProducts = false;
	isDisableGetProducts = false;
	isShowLoading = true;

	labels = {
		goToTopLabel: 'Go to top',
		errorMessage: 'Error!'
	};

	connectedCallback() {
		window.addEventListener('scroll', this.handleScroll.bind(this));

		getProducts({ lastId: '' })
			.then(resolve => {
				this.productList = resolve;
			})
			.catch(error => {
				console.log('Catch Get Products =>', error);
				this.handlerDispatchToast('Error!', 'Failed to get products!', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}

	handleScroll(event) {
		if (this.isDisableGetProducts) return;

		const scrollTop = window.scrollY;
		const scrollHeight = document.documentElement.scrollHeight;
		const windowHeight = window.innerHeight;
		const scrollPercentage = (scrollTop + windowHeight) / scrollHeight;

		if (scrollPercentage >= 0.75 && !this.isSearchMoreProducts) {
			this.isSearchMoreProducts = true;
			this.searchMoreProducts();
		}
	}

	searchMoreProducts() {
		let lastProductId = '';
		let productListLength = this.productList.length;

		if (productListLength > 0) lastProductId = this.productList[productListLength - 1]?.productId;

		getProducts({ lastId: lastProductId }) // filterData: this.filterData,
			.then(resolve => {
				if (resolve.length > 0) {
					this.productList = [...this.productList, ...resolve];
				}
				else {
					this.isDisableGetProducts = true;
				}
			})
			.catch(error => {
				console.log('Error to see more products! =>', error);
				this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
			})
			.finally(() => this.isSearchMoreProducts = false);
	}

	onClickGoToTop() {
		window.scrollTo(0, 0);
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
