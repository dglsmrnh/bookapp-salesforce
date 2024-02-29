import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor'

export default class ApprovalRecordComponent extends NavigationMixin(LightningElement) {
	@api
	record = {};

	detailObjects = ['ItemContrato__c','Order'];

	isMobile = false;
	isDesktop = false;

	get isOrder() {
		return this.record && this.record.orderInfo && this.record.sobjectType === 'Order';
	}

	get isDetailsAvailable() {
		return this.record && this.record.orderInfo && this.detailObjects.includes(this.record.sobjectType);
	}

	labels = {
		objectNameLabel: 'Objeto',
		nameLabel: 'Nome',
		statusLabel: 'Status',
		processNameLabel: 'Nome do processo',
		submitterNameLabel: 'Nome do remetente',
		approverNameLabel: 'Nome do aprovador',
		checkHistoryLabel: 'Ver histórico',
		checkDetailsLabel: 'Ver detalhes',
		commentLabel: 'Comentário',
		approvalCommentLabel: 'Comentário para aprovação',
		commentPlaceholder: 'Insira um comentário aqui.',
		commentHelpText: 'Máximo de caracteres: 4000',
		createdDateLabel: 'Data',
		accountLabel: 'Conta',
		totalAmountLabel: 'Total do pedido',
		scoreLabel: 'Score',
		margemLabel: 'Margem',
		margemAlvoLabel: 'Margem alvo',
		orderTypeLabel: 'Tipo de pedido'
	};

	get cardClass() {
		return this.record.isSelected ? "slds-card container__card-selected" : "slds-card container__card";
	}

	get headerClass() {
		return this.record.isSelected ?
			"slds-card__header slds-grid container__header-record-selected" :
			"slds-card__header slds-grid container__header-record";
	}

	connectedCallback() {
		switch (FORM_FACTOR) {
			case 'Small':
				this.isMobile = true;
				break;
			default:
				this.isDesktop = true;
				break;
		}
	}

	onClickOpenRecord() {
		if (this.isMobile) {
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: this.record.recordId,
					actionName: 'view',
				}
			});
		}
		else {
			this[NavigationMixin.GenerateUrl](
				{
					type: 'standard__recordPage',
					attributes: {
						recordId: this.record.recordId,
						actionName: 'view'
					}
				}
			).then(url => {
				window.open(url, '_blank');
			});
		}
	}

	onClickCheckHistory() {
		this.dispatchEvent(
			new CustomEvent('checkhistory', {
				detail: {
					id: this.record.recordId
				}
			})
		);
	}

	onClickCheckDetail() {
		this.dispatchEvent(
			new CustomEvent('checkdetail', {
				detail: {
					id: this.record.recordId,
					type: this.record.sobjectType
				}
			})
		);
	}

	onChangeData(event) {
		const { name, value } = event.target;

		this.dispatchEvent(
			new CustomEvent('changedata', {
				detail: {
					id: this.record.id,
					field: name,
					value
				}
			})
		);
	}

	onClickSelectRecord() {
		this.dispatchEvent(
			new CustomEvent('select', {
				detail: {
					id: this.record.id
				}
			})
		);
	}

	onClickRejectRecord(event) {
		event.preventDefault();

		this.dispatchEvent(
			new CustomEvent('reject', {
				detail: {
					id: this.record.id
				}
			})
		);
	}

	onClickApproveRecord(event) {
		event.preventDefault();

		this.dispatchEvent(
			new CustomEvent('approve', {
				detail: {
					id: this.record.id
				}
			})
		);
	}
}
