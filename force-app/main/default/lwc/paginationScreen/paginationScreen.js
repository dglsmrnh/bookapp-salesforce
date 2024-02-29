import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PaginationScreen extends LightningElement {
	@track
	tabList = [
		{
			id: 'tabSeeMore',
			label: 'Procurar livro',
			class: "slds-tabs_default__item slds-is-active",
			isSelected: true,
			tabDefaultId: 'tab-default-1',
			tabId: 'tab-default-1__item'
		}
	];
	@track
	tabBodyMap = {
		tabSeeMore: true,
		tabLazyLoad: false,
		itemThreeClass: false,
	};

	isShowLoading = false;

	connectedCallback() {
	}

	onClickSelectTab(event) {
		const tabId = this.getParentIdRecursive(event.target);

		this.tabList.forEach(item => {
			if (item.id === tabId) {
				item.isSelected = true;
				item.class = "slds-tabs_default__item slds-is-active";
				this.tabBodyMap[item.id] = true;
			}
			else {
				item.isSelected = false;
				item.class = "slds-tabs_default__item";
				this.tabBodyMap[item.id] = false;
			}
		});
	}

	getParentIdRecursive(element) {
		if (!element.dataset?.id) return this.getParentIdRecursive(element.parentElement);
		else return element.dataset.id;
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
