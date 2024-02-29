import { LightningElement, api } from 'lwc';

export default class ApprovalHistoryComponent extends LightningElement {
	@api
	processHistoryList = [];

	labels = {
		closeLabel: 'Fechar',
		approvalProcessHistoryLabel: 'Histórico do processo',
		dateLabel: 'Data',
		statusLabel: 'Status',
		assignedToLabel: 'Atribuído a',
		actualApproverLabel: 'Aprovador real',
		commentsLabel: 'Comentários'
	};

	onClickCloseHistoryPopup() {
		this.dispatchEvent(new CustomEvent('close'));
	}
}
