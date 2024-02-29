public with sharing class PaginationScreenController {
	@AuraEnabled
	public static Integer getProductSize() {
		return [SELECT COUNT() FROM Product2 WHERE IsActive = true];
	}

	@AuraEnabled
	public static List<ProductData> getNextOrPreviusProducts(String lastId, Boolean isNext) {
		if (String.isBlank(lastId)) lastId = '';

		List<ProductData> productList = new List<ProductData>();
		String query = fillProductQuery(lastId, isNext);

		for (Product2 retrievedProduct : Database.query(query)) {
			productList.add(new ProductData(retrievedProduct));
		}

		return productList;
	}

	public static String fillProductQuery(String lastId, Boolean isNext) {
		String query = '' +
			'SELECT Id, ' +
			'		Name, ' +
			'		( ' +
			'		 SELECT Id, ' +
			'				   UnitPrice ' +
			'		   FROM PricebookEntries ' +
			'		  WHERE IsActive = true ' +
			'			   AND Pricebook2.IsActive = true ' +
			'		    AND Pricebook2.IsStandard = true ' +
			'		  LIMIT 1 ' +
			'		) ' +
			'  FROM Product2 ' +
			' WHERE Id ' + (isNext ? '> ' : '< ') + '\'' + lastId + '\' ' +
			' ORDER BY Id ' + (isNext ? 'ASC ' : 'DESC ') +
			' LIMIT 5 ';

		return query;
	}

	@AuraEnabled
	public static List<ProductData> getFirstOrLastProducts(Integer page, Boolean isFirstProducts) {
		List<ProductData> productList = new List<ProductData>();

		String query = fillFirstOrLastProductQuery(page, isFirstProducts);

		for (Product2 retrievedProduct : Database.query(query)) {
			productList.add(new ProductData(retrievedProduct));
		}

		return productList;
	}

	public static String fillFirstOrLastProductQuery(Integer page, Boolean isFirst) {
		String query = '' +
			'SELECT Id, ' +
			'		Name, ' +
			'		( ' +
			'		 SELECT Id, ' +
			'				   UnitPrice ' +
			'		   FROM PricebookEntries ' +
			'		  WHERE IsActive = true ' +
			'			AND Pricebook2.IsActive = true ' +
			'		    AND Pricebook2.IsStandard = true ' +
			'		  LIMIT 1 ' +
			'		) ' +
			'  FROM Product2 ' +
			' ORDER BY Id ' + (isFirst ? 'ASC ' : 'DESC ') +
			' LIMIT 5 ' +
			' OFFSET ' + page * 5;

		return query;
	}

	@AuraEnabled
	public static List<ProductData> getProductsToListing() {
		List<ProductData> productList = new List<ProductData>();

		for (Product2 retrievedProduct : getProductsById('', 5)) {
			productList.add(new ProductData(retrievedProduct));
		}

		return productList;
	}

	@AuraEnabled
	public static List<ProductData> getProducts(String lastId) {
		if (String.isBlank(lastId)) lastId = '';

		List<ProductData> productList = new List<ProductData>();

		for (Product2 retrievedProduct : getProductsById(lastId, 10)) {
			productList.add(new ProductData(retrievedProduct));
		}

		return productList;
	}

	public static List<Product2> getProductsById(String lastId, Integer limitSize) {
		return [
			SELECT Id,
				   Name,
				   (
					SELECT Id,
						   UnitPrice
					  FROM PricebookEntries
					 WHERE IsActive = true
					   AND Pricebook2.IsActive = true
					   AND Pricebook2.IsStandard = true
					 LIMIT 1
				   )
			  FROM Product2
			 WHERE Id > :lastId
			 ORDER BY Id
			 LIMIT :limitSize
		];
	}

	public class ProductData {
		@AuraEnabled
		public String id {get; set;}
		@AuraEnabled
		public String productId {get; set;}
		@AuraEnabled
		public String productName {get; set;}
		@AuraEnabled
		public Decimal listPrice {get; set;}
		@AuraEnabled
		public Decimal unitPrice {get; set;}
		@AuraEnabled
		public Decimal quantity {get; set;}
		@AuraEnabled
		public Decimal discount {get; set;}
		@AuraEnabled
		public Decimal totalListPrice {get; set;}
		@AuraEnabled
		public Decimal totalPrice {get; set;}
		@AuraEnabled
		public Boolean isSelected {get; set;}
		@AuraEnabled
		public String productClass {get; set;}

		public ProductData() {
			this.id = null;

			this.productId = null;
			this.productName = '';
			this.listPrice = 0;
			this.unitPrice = 0;
			this.quantity = 0;
			this.discount = 0;
			this.totalListPrice = 0;
			this.totalPrice = 0;
			this.isSelected = false;
			this.productClass = 'slds-card container__product';
		}
		public ProductData(Product2 currentProduct) {
			PricebookEntry currentPrice;
			for (PricebookEntry retrievedPrice : currentProduct.PricebookEntries) {
				currentPrice = retrievedPrice;
			}

			this.id = null;

			this.productId = currentProduct.Id;
			this.productName = currentProduct.Name;
			this.listPrice = currentPrice != null ? currentPrice.UnitPrice : 0;
			this.unitPrice = currentPrice != null ? currentPrice.UnitPrice : 0;

			this.quantity = 0;
			this.discount = 0;
			this.totalListPrice = 0;
			this.totalPrice = 0;
			this.isSelected = false;
			this.productClass = 'slds-card container__product';
		}
	}
}
