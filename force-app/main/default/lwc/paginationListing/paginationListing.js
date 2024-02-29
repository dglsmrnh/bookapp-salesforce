import { LightningElement, track } from 'lwc';

import getProductSize from '@salesforce/apex/PaginationScreenController.getProductSize';
import getProductsToListing from '@salesforce/apex/PaginationScreenController.getProductsToListing';
import getNextOrPreviusProducts from '@salesforce/apex/PaginationScreenController.getNextOrPreviusProducts';
import getFirstOrLastProducts from '@salesforce/apex/PaginationScreenController.getFirstOrLastProducts';

export default class PaginationListing extends LightningElement {
	@track
	productList = [];
	@track
	paginationList = [];

	currentPage = 0;
	isShowPaginationNumbers = false;
	isShowLoading = true;

	labels = {
		previusPageLabel: 'Previous page',
		nextPageLabel: 'Next page',
		pageLabel: 'Page',
		errorMessage: 'Error!'
	};

	get isFirstPage() {
		if (this.paginationList.length <= 0) return true;

		return this.currentPage == 0;
	}

	get isLastPage() {
		let paginationLength = this.paginationList.length;

		if (paginationLength <= 0) return true;

		return this.currentPage == (paginationLength - 1);
	}

	get isShowFirstEllipsis() {
		return this.currentPage > 4;
	}

	get isShowLastEllipsis() {
		return this.currentPage < (this.paginationList.length - 5);
	}

	get showFirstPages() {
		return this.paginationList.filter((item, index) => index < 3);
	}

	get showLastPages() {
		return this.paginationList.filter((item, index) => index >= (this.paginationList.length - 3));
	}

	async connectedCallback() {
		window.addEventListener('resize', this.handleResizeScreen.bind(this));

		let productLength = await getProductSize();
		let productSize = Number((productLength / 5).toFixed(0));
		console.log('productSize =>', productSize);

		for (let i = 1; i <= productSize; i++) {
			this.paginationList.push(
				{
					id: i - 1,
					label: String(i),
					ariaLabel: this.labels.pageLabel + ' ' + String(i),
					isSelected: false,
					isShow: false,
					class: "button__page"
				}
			);
		}

		this.handleShowPaginations();
		this.isShowPaginationNumbers = true;

		getProductsToListing()
			.then(resolve => {
				this.productList = resolve ? resolve : [];
			})
			.catch(error => {
				console.log('Catch Get Products =>', error);
				this.handlerDispatchToast('Error!', 'Failed to get products!', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}

	handleResizeScreen(event) {
		const windowWidth = window.innerWidth;
		console.log('windowWidth =>', windowWidth);
	}

	onClickSelectPage(event) {
		this.isShowLoading = true;

		const id = Number(event.target.dataset.id);

		let isNext = this.currentPage < id;

		this.currentPage = id;
		this.handleShowPaginations();

		let pageSize = this.paginationList.length - 1;
		if (id == 0 || id == 1 || id == 2) {
			this.searchFirstData(this.currentPage);
		}
		else if (id == pageSize || id == pageSize - 1 || id == pageSize - 2) {
			this.searchLastData(this.currentPage);
		}
		else {
			this.searchNextOrPreviusData(isNext);
		}
	}

	onClickGoToFirstPage() {
		this.isShowLoading = true;

		this.currentPage = 0;
		this.handleShowPaginations();

		this.searchFirstData(0);
	}

	onClickGoToLastPage() {
		this.isShowLoading = true;

		this.currentPage = this.paginationList.length - 1;
		this.handleShowPaginations();

		this.searchLastData(this.currentPage);
	}

	// onClickPreviusPage() {
	// 	if (this.currentPage == 0) return;

	// 	this.currentPage--;
	// 	this.handleShowPaginations();
	// }

	// onClickNextPage() {
	// 	if (this.currentPage == this.paginationList.length - 1) return;

	// 	this.currentPage++;
	// 	this.handleShowPaginations();
	// }

	handleShowPaginations() {
		let pageSize = this.paginationList.length - 1;

		this.paginationList.forEach((item, index) => {
			if (index == this.currentPage) {
				item.isSelected = true;
				item.isShow = this.currentPage > 2 && this.currentPage < (this.paginationList.length - 3);
				item.class = "button__page current__page";
			}
			else if (
				!(index == 0 || index == 1 || index == pageSize || index == pageSize - 1)
				&& (
					(this.currentPage != 2 && index == this.currentPage - 1)
					|| (this.currentPage != this.paginationList.length - 3 && index == this.currentPage + 1)
					|| (this.currentPage == 0 && index == this.currentPage + 2)
					|| (this.currentPage == this.paginationList.length - 1 && index == this.currentPage - 2)
				)
			) {
				item.isSelected = false;
				item.isShow = index > 2 && index < (this.paginationList.length - 3);
				item.class = "button__page";
			}
			else {
				item.isSelected = false;
				item.isShow = false;
				item.class = "button__page";
			}
		});
	}

	searchNextOrPreviusData(isNext) {
		this.isShowLoading = true;

		let lastProductId = '';
		let productListLength = this.productList.length;

		if (isNext && productListLength > 0) lastProductId = this.productList[productListLength - 1]?.productId;
		else if (!isNext && productListLength > 0) lastProductId = this.productList[0].productId;

		getNextOrPreviusProducts({ lastId: lastProductId, isNext }) // filterData: this.filterData,
			.then(resolve => {
				this.productList = resolve ? resolve : [];
			})
			.catch(error => {
				console.log('Error to get next or previus products! =>', error);
				this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}

	searchFirstData(page) {
		this.isShowLoading = true;
		this.callGetFirstOrLastProducts(page, true);
	}

	searchLastData(page) {
		this.isShowLoading = true;
		this.callGetFirstOrLastProducts(this.paginationList.length - page - 1, false);
	}

	callGetFirstOrLastProducts(page, isFirstProducts) {
		getFirstOrLastProducts({ page, isFirstProducts }) // filterData: this.filterData,
			.then(resolve => {
				this.productList = resolve ? resolve : [];
			})
			.catch(error => {
				console.log('Error to get last products! =>', error);
				this.handlerDispatchToast(this.labels.errorMessage, '', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}
}
