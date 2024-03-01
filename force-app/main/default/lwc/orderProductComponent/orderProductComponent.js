import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderProductComponent extends LightningElement {
	@api
	book = {};

	labels = {
		discountLabel: 'A',
		unitPriceLabel: 'A',
		quantityLabel: 'A',
		totalPriceLabel: 'A',
		listPriceLabel: 'A',
		totalListPriceLabel: 'A',
		invalidDiscountLabel: 'A',
		invalidUnitPriceLabel: 'A',
		invalidQuantityLabel: 'A',
		warningMessage: 'A'
	};
	
	get hasThumbnail() {
		return (this.book.volumeInfo.imageLinks != null) ? (this.book.volumeInfo.imageLinks.thumbnail != null ? true : false) : false;
	}

	onClickAddBook() {
		this.dispatchEvent(
			new CustomEvent('add', {
				detail: { book: this.book }
			})
		);
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
