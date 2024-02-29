import { LightningElement, api } from 'lwc';

export default class QuantityComponent extends LightningElement {
	@api
	quantityLabel = 'Quantity';
	@api
	maxQuantity;
	@api
	quantity = 0;
	@api
	isEnabledMaxQuantity = false;
	@api
	isDisabledQuantity = false;

	get isDisabledEditQuantity() {
		if (this.isDisabledQuantity) return true;
		else if (this.isEnabledMaxQuantity) {
			return this.maxQuantity == undefined || this.maxQuantity == null ? false : this.maxQuantity <= 0;
		}
		else {
			return false;
		}
	}

	onClickSubtractQuantity() {
		if (this.quantity <= 0) return;

		this.quantity = Number(this.quantity) - 1;

		this.sendQuantity();
	}

	onClickAddQuantity() {
		if (this.isDisabledEditQuantity || (this.isEnabledMaxQuantity && this.quantity >= this.maxQuantity)) {
			return;
		}

		this.quantity = Number(this.quantity) + 1;

		this.sendQuantity();
	}

	onChangeQuantity(event) {
		let value = event.target.value;
		value = value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '');

		if (!value) value = 0;
		this.quantity = Number(value);

		if (this.isEnabledMaxQuantity && this.quantity > this.maxQuantity) {
			this.quantity = this.maxQuantity;
		}
		else if (this.quantity <= 0) {
			this.quantity = 0;
		}

		this.sendQuantity();
	}

	sendQuantity() {
		this.dispatchEvent(new CustomEvent('changequantity', {
			detail: {
				quantity: this.quantity
			}
		}));
	}
}
