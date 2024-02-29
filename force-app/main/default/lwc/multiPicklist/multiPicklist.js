import { LightningElement, track, api } from 'lwc';

export default class MultiPicklist extends LightningElement {
	@api
	name = '';
	@api
	optionList = [];
	@api
	selectedValueList = [];
	@api
	selectedValue;
	@api
	label = '';
	@api
	placeholder = 'Selecione uma opção';
	@api
	selectedLabel = 'opções escolhidas';
	@api
	noRecordFoundLabel = 'Nenhum resultado encontrado';
	@api
	disabled = false;
	@api
	multiSelect = false;

	@track
	value;
	@track
	valueList = [];
	@track
	optionData;
	@track
	searchString;
	@track
	noResultMessage;
	@track
	isShowDropdown = false;

	connectedCallback() {
		this.isShowDropdown = false;
		var optionData = this.optionList ? (JSON.parse(JSON.stringify(this.optionList))) : null;
		var value = this.selectedValue ? this.selectedValue : null;
		var valueList = this.selectedValueList ? (JSON.parse(JSON.stringify(this.selectedValueList))) : null;

		if (value || valueList) {
			var searchString;
			var count = 0;

			for (var i = 0; i < optionData.length; i++) {
				if (this.multiSelect) {
					if (valueList.includes(optionData[i].value)) {
						optionData[i].selected = true;
						count++;
					}
				}
				else {
					if (optionData[i].value == value) {
						searchString = optionData[i].label;
					}
				}
			}

			if (this.multiSelect) {
				this.searchString = count + ' ' + this.selectedLabel;
			}
			else {
				this.searchString = searchString;
			}
		}

		this.value = value;
		this.valueList = valueList;
		this.optionData = optionData;
	}

	filterOptions(event) {
		this.searchString = event.target.value;

		if (this.searchString && this.searchString.length > 0) {
			this.noResultMessage = '';

			if (this.searchString.length >= 2) {
				var flag = true;
				for (var i = 0; i < this.optionData.length; i++) {
					if (this.optionData[i].label.toLowerCase().trim().startsWith(this.searchString.toLowerCase().trim())) {
						this.optionData[i].isVisible = true;
						flag = false;
					}
					else {
						this.optionData[i].isVisible = false;
					}
				}

				if (flag) {
					this.noResultMessage = this.noRecordFoundLabel + ' "' + this.searchString + '"';
				}
			}

			this.isShowDropdown = true;
		}
		else {
			this.isShowDropdown = false;
		}
	}

	selectItem(event) {
		var selectedVal = event.currentTarget.dataset.id;

		if (selectedVal) {
			var count = 0;
			var options = JSON.parse(JSON.stringify(this.optionData));

			for (var i = 0; i < options.length; i++) {
				if (options[i].value === selectedVal) {
					if (this.multiSelect) {
						if (this.valueList.includes(options[i].value)) {
							this.valueList.splice(this.valueList.indexOf(options[i].value), 1);
						}
						else {
							this.valueList.push(options[i].value);
						}

						options[i].selected = options[i].selected ? false : true;
					}
					else {
						this.value = options[i].value;
						this.searchString = options[i].label;
					}
				}

				if (options[i].selected) {
					count++;
				}
			}

			this.optionData = options;

			if (this.multiSelect) {
				this.searchString = count + ' ' + this.selectedLabel;

				this.dispatchSelectedValueList();
			}


			if (!this.multiSelect) {
				this.dispatchSelectedValueList();
			}

			if (this.multiSelect) {
				event.preventDefault();
			}
			else {
				this.isShowDropdown = false;
			}
		}
	}

	showOptions() {
		if (this.disabled == false && this.optionList) {
			this.noResultMessage = '';
			this.searchString = '';
			var options = JSON.parse(JSON.stringify(this.optionData));

			for (var i = 0; i < options.length; i++) {
				options[i].isVisible = true;
			}

			if (options.length > 0) {
				this.isShowDropdown = true;
			}

			this.optionData = options;
		}
	}

	closePill(event) {
		var value = event.currentTarget.name;
		var count = 0;
		var options = JSON.parse(JSON.stringify(this.optionData));

		for (var i = 0; i < options.length; i++) {
			if(options[i].value === value) {
				options[i].selected = false;
				this.valueList.splice(this.valueList.indexOf(options[i].value), 1);
			}
			if(options[i].selected) {
				count++;
			}
		}

		this.optionData = options;

		if (this.multiSelect) {
			this.searchString = count + ' ' + this.selectedLabel;

			this.dispatchSelectedValueList();
		}
	}

	handleBlur() {
		var previousLabel;
		var count = 0;

		for (var i = 0; i < this.optionData.length; i++) {
			if (this.optionData[i].value === this.value) {
				previousLabel = this.optionData[i].label;
			}

			if (this.optionData[i].selected) {
				count++;
			}
		}

		if (this.multiSelect) {
			this.searchString = count + ' ' + this.selectedLabel;
		}
		else {
			this.searchString = previousLabel;
		}

		this.isShowDropdown = false;
	}

	@api
	clearAll() {
		var optionList = JSON.parse(JSON.stringify(this.optionData));

		optionList.forEach(item => item.selected = false);

		this.optionData = optionList;
		this.valueList = [];

		this.searchString = '0 ' + this.selectedLabel;
	}

	dispatchSelectedValueList() {
		this.dispatchEvent(
			new CustomEvent(
				'selectoption',
				{
					detail: {
						selectedValueList: this.valueList,
						name: this.name
					}
				}
			)
		);
	}

	handleMouseOut() {
		this.isShowDropdown = false;
	}

	handleMouseIn() {
		this.isShowDropdown = true;
	}
}
