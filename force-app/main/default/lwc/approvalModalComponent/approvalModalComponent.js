import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalModalComponent extends LightningElement {
	@api
	title = 'Confirme a ação';
	@api
	message = '';
	@api
	isApprove = false;

	labels = {
		closeLabel: 'Fechar',
		cancelLabel: 'Cancelar',
		acceptLabel: 'OK'
	};

	onClickCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	onClickAccept() {
		this.dispatchEvent(
			new CustomEvent(
				'action',
				{
					detail: {
						isApprove: this.isApprove
					}
				}
			)
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
