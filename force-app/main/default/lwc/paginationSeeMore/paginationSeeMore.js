import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getProducts from '@salesforce/apex/PaginationScreenController.getProducts';
import getProducts from '@salesforce/apex/PaginationScreenController.getProducts';

export default class PaginationSeeMore extends LightningElement {
	@track
	productList = [];

	isShowLoading = true;
	isShowSeeMoreButton = true;

	labels = {
		goToTopLabel: 'Voltar ao topo',
		seeMoreLabel: 'Ver mais',
		errorMessage: 'Erro!'
	};

	connectedCallback() {
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

	onClickSearchMore() {
		this.isShowLoading = true;

		let lastProductId = '';
		let productListLength = this.productList.length;

		if (productListLength > 0) lastProductId = this.productList[productListLength - 1]?.productId;

		getProducts({ lastId: lastProductId }) // filterData: this.filterData,
			.then(resolve => {
				if (resolve.length > 0) {
					this.productList = [...this.productList, ...resolve];
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
