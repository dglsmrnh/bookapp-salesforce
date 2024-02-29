import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderProductComponent extends LightningElement {
	@api
	product = {};
	@api
	disabled;

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

	onChangeProductData(event) {
		const { name, value } = event.target;

		let product = JSON.parse(JSON.stringify(this.product));
		product[name] = value;

		if (name === 'discount') {
			this.handleDiscount(product, value);
		}
		else if (name === 'unitPrice') {
			this.handleUnitPrice(product, value);
		}

		this.calculateTotals(product);

		this.product = product;

		if (this.product.isSelected) {
			if (!this.checkProduct()) {
				this.sendAddProduct();
			}
		}
	}

	onChangeQuantity(event) {
		const quantity = event.detail.quantity;

		let product = JSON.parse(JSON.stringify(this.product));
		product.quantity = quantity;

		this.calculateTotals(product);

		this.product = product;

		if (this.product.isSelected) {
			this.checkProduct();
			this.sendAddProduct();
		}
	}

	calculateTotals(product) {
		product.totalListPrice = product.listPrice * product.quantity;
		product.totalPrice = product.unitPrice * product.quantity;
	}

	handleDiscount(product, value) {
		if (value < 0) value = 0;
		else if (value > 100) value = 100;

		product.unitPrice = Number((product.listPrice - (product.listPrice * (value / 100))).toFixed(2));
	}

	handleUnitPrice(product, value) {
		if (value > product.listPrice) value = product.listPrice;

		product.discount = Number(((1 - (value / product.listPrice)) * 100).toFixed(2));
	}

	onClickAddProduct() {
		if (!this.checkProduct()) {
			let product = JSON.parse(JSON.stringify(this.product));

			product.isSelected = true;
			product.productClass = 'slds-card container__product-selected';

			this.product = product;

			this.sendAddProduct();
		}
	}

	sendAddProduct() {
		this.dispatchEvent(
			new CustomEvent('add', {
				detail: { product: this.product }
			})
		);
	}

	onClickRemoveProduct() {
		this.dispatchEvent(
			new CustomEvent('remove', {
				detail: { productId: this.product.productId }
			})
		);
	}

	checkProduct() {
		let hasError = false;

		if (this.product.discount < 0 || this.product.discount > 100) {
			this.handlerDispatchToast(this.labels.warningMessage, this.labels.invalidDiscountLabel, 'warning');
			hasError = true;
		}
		else if (this.product.unitPrice > this.product.listPrice || this.product.unitPrice < 0) {
			this.handlerDispatchToast(this.labels.warningMessage, this.labels.invalidUnitPriceLabel, 'warning');
			hasError = true;
		}
		else if (this.product.quantity <= 0) {
			this.handlerDispatchToast(this.labels.warningMessage, this.labels.invalidQuantityLabel, 'warning');
			hasError = true;
		}

		return hasError;
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
