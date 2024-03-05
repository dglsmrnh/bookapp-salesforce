import { LightningElement, api } from 'lwc';

export default class PaginationSeeMore extends LightningElement {
	
	@api bookList = [];

	get isEmpty() {
		return this.bookList.length > 0 ? false : true; 
	}

	@api isShowSeeMoreButton = false;

	labels = {
		goToTopLabel: 'Voltar ao topo',
		seeMoreLabel: 'Ver mais',
		errorMessage: 'Erro!'
	};

	onClickSearchMore() {
		console.log('search more');
		const event = new CustomEvent('searchmore');

		this.dispatchEvent(event);
	}

	onClickGoToTop() {
		window.scrollTo(0, 0);
	}
}
