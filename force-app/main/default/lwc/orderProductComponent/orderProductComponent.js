import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import orderProductLeadModal from 'c/orderProductLeadModal';

export default class OrderProductComponent extends LightningElement {
	@api book = {};

	get hasThumbnail() {
		return (this.book.volumeInfo.imageLinks != null) ? (this.book.volumeInfo.imageLinks.thumbnail != null ? true : false) : false;
	}

	async onClickAddBook() {
		const result = await orderProductLeadModal.open({
			// `label` is not included here in this example.
			// it is set on lightning-modal-header instead
			size: 'large',
			description: 'Accessible description of modal\'s purpose',
			book: this.book,
		});
		// if modal closed with X button, promise returns result = 'undefined'
		// if modal closed with OK button, promise returns result = 'okay'
		console.log(result);
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
