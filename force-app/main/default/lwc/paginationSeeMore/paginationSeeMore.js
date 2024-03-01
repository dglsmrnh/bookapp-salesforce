import { LightningElement, api } from 'lwc';

export default class PaginationSeeMore extends LightningElement {
	
	@api
	bookList = [];

	@api
	isShowSeeMoreButton = false;

	labels = {
		goToTopLabel: 'Voltar ao topo',
		seeMoreLabel: 'Ver mais',
		errorMessage: 'Erro!'
	};

	connectedCallback() {
	}

	onClickSearchMore() {
		const event = new CustomEvent('searchmore', {detail:{value:'searchmore'}})
	}

	onClickGoToTop() {
		window.scrollTo(0, 0);
	}
}
