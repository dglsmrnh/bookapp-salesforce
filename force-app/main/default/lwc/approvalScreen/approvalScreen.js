import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor'
import LightningConfirm from 'lightning/confirm';

import getComponentData from '@salesforce/apex/ApprovalScreenController.getComponentData';
import searchProcesses from '@salesforce/apex/ApprovalScreenController.searchProcesses';
import sendApprovalRecords from '@salesforce/apex/ApprovalScreenController.approvalRecords';
import checkProcessHistory from '@salesforce/apex/ApprovalScreenController.checkProcessHistory';

// import label from '@salesforce/label/c.label';

export default class ApprovalScreen extends NavigationMixin(LightningElement) {
	@track
	approvalRecordMap = {};
	@track
	selectedRecordIdList = [];
	@track
	filterData = {
		objectSelectedList: [],
		statusSelectedList: [],
		processSelectedList: [],
		approverName: '',
		submitterName: ''
	};
	@track
	processHistoryList = [];

	@track
	detailData;

	@track
	selectedId;

	objectOptionList = [];
	statusOptionList = [];
	processOptionList = [];
	delayFilterData;

	currentSelectedIdList = [];
	modalConfirmMessage = '';
	isOpenModalConfirm = false;

	isShowLoading = true;
	
	@track
	isMobile = false;

	isDesktop = false;
	isShowSeeMoreButton = true;
	isShowMultiPicklists = false;
	isShowDatatable = false;
	isOpenCheckHistory = false;
	isOpenDetailContract = false;
	isOpenDetailOrder = false;
	headerClass = "slds-var-m-vertical_x-small slds-var-p-horizontal_medium slds-var-p-vertical_small container__header";
	menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click";

	sortedBy = 'createdDate';
	sortedDirection = 'desc';

	get sortedBySelectedOptions() {
        return [
            { label: 'Data', value: 'createdDate' },
			{ label: 'Objeto', value: 'sobjectLabel' },
            { label: 'Nome do processo', value: 'processName' },
			{ label: 'Solicitante', value: 'submitterName' },
        ];
    }

	get sortedDirectionSelectedOptions() {
        return [
            { label: 'Decrescente', value: 'desc' },
            { label: 'Crescente', value: 'asc' }
        ];
	}

	actionList = [
		{ label: 'Histórico', name: 'history' },
		{ label: 'Rejeitar', name: 'reject' },
		{ label: 'Aprovar', name: 'approve' }
	];
	tableColumns = [
		{
			label: 'Detalhes',
            type: 'button-icon',
			initialWidth: 40,
            typeAttributes: { 	
				name: 'view_details',
				iconName: 'utility:preview',
				title: 'Detalhes do registro',
				variant: 'border-filled',
				alternativeText: 'Detalhes do registro'				
			}
        },
		{
			label: 'Nome',
			type: 'button',
			typeAttributes: {
				name: 'redirectRecord',
				label: {
					fieldName: 'sobjectName'
				},
				variant: 'base'
			}
		},
		{ label: 'Data', fieldName: 'createdDate', sortable: false },
		{ label: 'Objeto', fieldName: 'sobjectLabel', sortable: false },
		// { label: 'Objeto', fieldName: 'sobjectType', sortable: true },
		{ label: 'Status', fieldName: 'statusLabel', sortable: false },
		{ label: 'Nome do processo', fieldName: 'processName', sortable: false },
		//{ label: 'Aprovador', fieldName: 'actorName', sortable: true },
		{ label: 'Solicitante', fieldName: 'submitterName', sortable: false },
		{ label: 'Comentário', fieldName: 'comment' },
		{ label: 'Comentário da aprovação', fieldName: 'approvalComment', editable: true },
		{ type: 'action', typeAttributes: { rowActions: this.actionList } }
	];

	labels = {
		emptyApprovalRecordLabel: 'Não há registro de aprovação!',
		approvalScreenLabel: 'Aprovação em massa',
		refreshLabel: 'Atualizar',
		refreshDataLabel: 'Atualizar dados',
		clearLabel: 'Limpar',
		rejectLabel: 'Rejeitar',
		approveLabel: 'Aprovar',
		moreOptionsLabel: 'Mais opções',
		showMoreLabel: 'Mostrar mais',
		showInTableLabel: 'Mostrar na tabela',
		showInCardLabel: 'Mostrar no cartão',
		objectNameLabel: 'Nome do objeto',
		statusLabel: 'Status',
		approvalProcessNameLabel: 'Nome do processo de aprovação',
		submitterNameLabel: 'Nome do aprovador',
		submitterNamePlaceholder: 'Pesquisar aprovador...',
		contactAdminMessage: 'Entre em contato com um administrador!',
		noRecordsFoundMessage: 'Nenhum registro encontrado!',
		hasNoHistoryMessage: 'Este processo não tem histórico',
		rejectRecordMessage: 'Você deseja rejeitar este registro?',
		approveRecordMessage: 'Você deseja aprovar este registro?',
		rejectAllRecordsMessage: 'Você deseja rejeitar todos os registros selecionados?',
		approveAllRecordsMessage: 'Você deseja aprovar todos os registros selecionados?',
		detailNotAvailableMessage: 'Recurso indisponível para esse tipo de registro.',
		warningLabel: 'Aviso!',
		errorLabel: 'Erro!',
		successLabel: 'Sucesso!',
		sortedByNameLabel: 'Ordernar por campo',
		sortedDirectionNameLabel: 'Em ordem'
	};

	get approvalRecords() {
		return Object.values(this.approvalRecordMap);
	}

	get isDisabledHeaderButton() {
		return this.selectedRecordIdList.length <= 0;
	}

	get isApprovalRecordsEmpty() {
		return Object.values(this.approvalRecordMap).length <= 0;
	}

	connectedCallback() {
		switch (FORM_FACTOR) {
			case 'Small':
				this.headerClass = "slds-var-m-vertical_x-small slds-var-p-horizontal_medium slds-var-p-vertical_small container__header-mobile";
				this.isMobile = true;
				break;
			default:
				this.headerClass = "slds-var-m-vertical_x-small slds-var-p-horizontal_medium slds-var-p-vertical_small container__header";
				this.isDesktop = true;
				break;
		}

		getComponentData()
			.then(resolve => {
				if (resolve.hasError) {
					console.log('Get Component Data Fail =>', resolve.errorMessage);
					this.handlerDispatchToast(this.labels.warningLabel, resolve.errorMessage, 'warning');
				}
				else {
					this.approvalRecordMap = resolve.recordDataMap;

					this.objectOptionList = resolve.sobjectOptionList;
					this.statusOptionList = resolve.statusOptionList;
					this.processOptionList = resolve.processOptionList;
				}
			})
			.catch(error => {
				console.log('Get Component Data Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => {
				this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
				this.isShowMultiPicklists = true;
				this.isShowLoading = false;
			});
	}

	onClickRefreshData() {
		this.isShowLoading = true;

		this.onClickClearAll();

		this.template.querySelectorAll('c-multi-picklist').forEach(item => item.clearAll());

		this.filterData.objectSelectedList = [];
		this.filterData.statusSelectedList = [];
		this.filterData.processSelectedList = [];

		getComponentData()
			.then(resolve => {
				if (resolve.hasError) {
					console.log('Refresh Component Data Fail =>', errorMessage);
					this.handlerDispatchToast(this.labels.warningLabel, resolve.errorMessage, 'warning');
				}
				else {
					this.approvalRecordMap = resolve.recordDataMap;
				}
			})
			.catch(error => {
				console.log('Refresh Component Data Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => {
				this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
				this.isShowMultiPicklists = true;
				this.isShowLoading = false;
			});

		this.menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click";
	}

	onClickMenuDropdownHandler() {
		if (this.menuDropdownClass == "slds-dropdown-trigger slds-dropdown-trigger_click") {
			this.menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open";
		}
		else {
			this.menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click";
		}
	}

	onClickChangeDisplayRecord(event) {
		if (this.isMobile) return;

		const name = event.target.dataset.name;

		if (name == 'table') this.isShowDatatable = true;
		else this.isShowDatatable = false;

		this.menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click";
	}

	onClickSortHandler(event) {
		const { fieldName, sortDirection } = event.detail;

		this.sortApprovalRecordMap(fieldName, sortDirection);

		this.sortedBy = fieldName;
		this.sortedDirection = sortDirection;
	}

	onClickRowActionHandler(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;

		const detailObjects = ['ItemContrato__c','Order'];

		switch (actionName) {
			case 'history':
				this.handleCheckHistory({ detail: { id: row.recordId } });
				break;
			case 'reject':
				this.handleRejectRecord({ detail: { id: row.id } });
				break;
			case 'approve':
				this.handleApproveRecord({ detail: { id: row.id } });
				break;
			case 'redirectRecord':
				this.openRecord(row.recordId);
				break;
			case 'view_details':
				if(detailObjects.includes(row.sobjectType)) {
					this.handleOpenDetail({ detail: { id: row.recordId, type: row.sobjectType } });
				}else {
					this.handlerDispatchToast(this.labels.warningLabel, this.labels.detailNotAvailableMessage, 'warning');
				}
				break;

			default:
		}
	}

	handleOpenDetail(event) {
		const recordId = event.detail.id;
		const type = event.detail.type;

		this.handlerDispatchToast(this.labels.warningLabel, this.labels.detailNotAvailableMessage, 'warning');
		// this.isShowLoading = true;
		// if(type == 'ItemContrato__c') {
		// 	getContractItem({ recordId: recordId })
		// 		.then(data => {
		// 			if (!data) {
		// 				this.handlerDispatchToast(this.labels.warningLabel, this.labels.detailNotAvailableMessage, 'warning');
		// 			}
		// 			else {
		// 				this.detailData = data;

		// 				if (this.isMobile) window.scrollTo(0, 0);
		// 				this.isOpenDetailContract = true;
		// 			}
		// 		})
		// 		.catch(error => {
		// 			console.log('Get Data Error =>', error);
		// 			this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
		// 		})
		// 		.finally(() => this.isShowLoading = false);
		// }
		// else if(type == 'Order') {
		// 	getOrder({ recordId: recordId })
		// 	.then(data => {
		// 		if (!data) {
		// 			this.handlerDispatchToast(this.labels.warningLabel, this.labels.detailNotAvailableMessage, 'warning');
		// 		}
		// 		else {
		// 			this.detailData = data;

		// 			if (this.isMobile) window.scrollTo(0, 0);
		// 			this.isOpenDetailOrder = true;
		// 		}
		// 	})
		// 	.catch(error => {
		// 		console.log('Get Data Error =>', error);
		// 		this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
		// 	})
		// 	.finally(() => this.isShowLoading = false);
		// }
	}

	openRecord(recordId) {
		if (this.isMobile) {
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: recordId,
					actionName: 'view',
				}
			});
		}
		else {
			this[NavigationMixin.GenerateUrl](
				{
					type: 'standard__recordPage',
					attributes: {
						recordId: recordId,
						actionName: 'view'
					}
				}
			).then(url => {
				window.open(url, '_blank');
			});
		}
	}

	onClickRowDatatableHandler(event) {
		const { config } = event.detail;
		const { action, value } = config;

		switch (action) {
			case 'rowSelect':
				this.approvalRecordMap[value].isSelected = true;
				this.selectedRecordIdList.push(value);
				break;

			case 'rowDeselect':
				this.approvalRecordMap[value].isSelected = false;
				this.selectedRecordIdList = this.selectedRecordIdList.filter(item => item != value);
				break;

			case 'deselectAllRows':
				this.selectedRecordIdList = [];
				Object.values(this.approvalRecordMap).forEach(item => item.isSelected = false);
				break;

			case 'selectAllRows':
				this.selectedRecordIdList = [];
				Object.values(this.approvalRecordMap).forEach(item => {
					item.isSelected = true;
					this.selectedRecordIdList.push(item.id);
				});
				break;

			default:
				break;
		}
	}

	onChangeFilterData(event) {
		const { name, value } = event.target;

		clearTimeout(this.delayFilterData);
		this.delayFilterData = setTimeout(() => {
			this.filterData[name] = value;
			this.serchProcessByFilters();
		}, 1000);
	}

	handleSelectOptionList(event) {
		const { selectedValueList, name } = event.detail;

		if (!name) return;

		this.filterData[name] = selectedValueList;

		this.serchProcessByFilters();
	}

	onChangeRowData(event) {
		event.detail.draftValues.forEach(item => {
			const { id, approvalComment } = item;

			if (approvalComment) {
				this.approvalRecordMap[id].approvalComment = approvalComment;
			}
		});
	}

	onClickClearFilters() {
		this.template.querySelectorAll('c-multi-picklist').forEach(item => item.clearAll());

		this.filterData.objectSelectedList = [];
		this.filterData.statusSelectedList = [];
		this.filterData.processSelectedList = [];

		this.serchProcessByFilters();
	}

	handleApprovalRecordData(event) {
		const { id, field, value } = event.detail;
		this.approvalRecordMap[id][field] = value;
	}

	handleCheckHistory(event) {
		const recordId = event.detail.id;

		this.isShowLoading = true;

		checkProcessHistory({ recordId })
			.then(resolveList => {
				if (!resolveList || resolveList.length == 0) {
					this.handlerDispatchToast(this.labels.warningLabel, this.labels.hasNoHistoryMessage, 'warning');
				}
				else {
					this.processHistoryList = resolveList;

					if (this.isMobile) window.scrollTo(0, 0);
					this.isOpenCheckHistory = true;
				}
			})
			.catch(error => {
				console.log('Get History Data Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}

	closeHistoryPopup() {
		this.isOpenCheckHistory = false;
		this.processHistoryList = [];
	}

	closeDetailPopup() {
		this.isOpenDetailContract = false;
		this.isOpenDetailOrder = false;
	}

	handleSelectRecord(event) {
		const id = event.detail.id;

		this.approvalRecordMap[id].isSelected = !this.approvalRecordMap[id].isSelected;

		this.fillSelectedRecords();
	}

	onClickClearAll() {
		Object.values(this.approvalRecordMap).forEach(item => item.isSelected = false );
		this.selectedRecordIdList = [];

		if (this.isMobile) {
			this.menuDropdownClass = "slds-dropdown-trigger slds-dropdown-trigger_click";
		}
	}

	handleRejectRecord(event) {
		const id = event.detail.id;

		this.currentSelectedIdList = [id];
		this.modalConfirmMessage = this.labels.rejectRecordMessage;
		this.isApproveModal = false;

		if (this.isMobile) window.scrollTo(0, 0);
		this.isOpenModalConfirm = true;
	}

	handleApproveRecord(event) {
		const id = event.detail.id;

		this.currentSelectedIdList = [id];
		this.modalConfirmMessage = this.labels.approveRecordMessage;
		this.isApproveModal = true;

		if (this.isMobile) window.scrollTo(0, 0);
		this.isOpenModalConfirm = true;
	}

	onClickRejectAll() {
		this.currentSelectedIdList = [...this.selectedRecordIdList];
		this.modalConfirmMessage = this.labels.rejectAllRecordsMessage;
		this.isApproveModal = false;

		if (this.isMobile) window.scrollTo(0, 0);
		this.isOpenModalConfirm = true;
	}

	onClickApproveAll() {
		this.currentSelectedIdList = [...this.selectedRecordIdList];
		this.modalConfirmMessage = this.labels.approveAllRecordsMessage;
		this.isApproveModal = true;

		if (this.isMobile) window.scrollTo(0, 0);
		this.isOpenModalConfirm = true;
	}

	handleCancelApprovalAction() {
		this.currentSelectedIdList = [];
		this.isOpenModalConfirm = false;
	}

	handleApprovalAction(event) {
		if (this.currentSelectedIdList.length > 0) {
			this.sendToApproval(this.currentSelectedIdList, event.detail.isApprove);
		}

		this.currentSelectedIdList = [];
		this.isOpenModalConfirm = false;
	}

	sendToApproval(sendToApprovalList, isApproval) {
		if (sendToApprovalList.length <= 0) {
			this.isShowLoading = false;
			return;
		}

		this.isShowLoading = true;

		let approvalRecordMap = {};
		sendToApprovalList.forEach(key => approvalRecordMap[key] = this.approvalRecordMap[key]);

		sendApprovalRecords({ recordDataMap: approvalRecordMap, isApproval })
			.then(resolveList => {
				if (resolveList.length <= 0) {
					this.handlerDispatchToast(this.labels.warningLabel, this.labels.noRecordsFoundMessage, 'warning');
				}
				else {
					let hasError = false;
					let errorMessage = '';

					resolveList.forEach(resolve => {
						if (!resolve.hasError) {
							if (this.approvalRecordMap[resolve.id]) {
								delete this.approvalRecordMap[resolve.id];
							}
						}
						else {
							hasError = true;

							if (resolve.errorMessage) {
								if (errorMessage) errorMessage += '\n';
								errorMessage += resolve.errorMessage;
								console.log('Error Approval Record =>', resolve.errorMessage);
							}
							else {
								console.log('Exception Approval Record =>', resolve.exceptionMessage);
							}
						}
					});

					this.fillSelectedRecords();

					if (errorMessage) {
						this.handlerDispatchToast(this.labels.warningLabel, errorMessage, 'warning');
					}
					else if (hasError) {
						this.handlerDispatchToast(this.labels.errorLabel, this.labels.contactAdminMessage, 'error');
					}
					else {
						this.handlerDispatchToast(this.labels.successLabel, '', 'success');
					}
				}
			})
			.catch(error => {
				console.log('Send To Approval Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => this.isShowLoading = false);
	}

	onClickSearchMore() {
		this.isShowLoading = true;

		searchProcesses({ filter: this.filterData, workitemSize: this.approvalRecords.length })
			.then(resolve => {
				this.approvalRecordMap = { ...resolve, ...this.approvalRecordMap };
			})
			.catch(error => {
				console.log('See More Data Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => {
				this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
				this.isShowLoading = false;
			});
	}

	serchProcessByFilters() {
		this.isShowLoading = true;

		searchProcesses({ filter: this.filterData, workitemSize: 0 })
			.then(resolve => {
				let selectedRecordMap = {};
				this.selectedRecordIdList.forEach(key => selectedRecordMap[key] = this.approvalRecordMap[key]);

				this.approvalRecordMap = { ...resolve, ...selectedRecordMap };
			})
			.catch(error => {
				console.log('Search Process Data Error =>', error);
				this.handlerDispatchToast(this.labels.errorLabel, '', 'error');
			})
			.finally(() => {
				this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
				this.isShowLoading = false;
			});
	}

	sortApprovalRecordMap(fieldName, sortDirection) {
		let cloneApprovalRecordMap = JSON.parse(JSON.stringify(this.approvalRecords));

		this.approvalRecordMap = {};
		cloneApprovalRecordMap.sort((a, b) => {
			if (sortDirection === 'asc') {
				if (a[fieldName] < b[fieldName]) return -1;
				if (a[fieldName] > b[fieldName]) return 1;
				return 0;
			}
			else {
				if (a[fieldName] > b[fieldName]) return -1;
				if (b[fieldName] > a[fieldName]) return 1;
				return 0;
			}
		});

		cloneApprovalRecordMap.forEach(item => {
			this.approvalRecordMap[item.id] = item;
		});
	}

	fillSelectedRecords() {
		this.selectedRecordIdList = Object.values(this.approvalRecordMap).filter(item => item.isSelected).map(item => item.id);
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

	handlerSortedByChange(event) {
		this.sortedBy = event.detail.value;
		this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
	}

	handlerSortedDirectionChange(event) {
		this.sortedDirection = event.detail.value;
		this.sortApprovalRecordMap(this.sortedBy, this.sortedDirection);
	}
}
