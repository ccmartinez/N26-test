@isTest
public with sharing class ProductDataProcessorTest {
    @isTest static void buildParentProductWrappers(){
        Product2 product = TestDataFactory.getProductList(1, true)[0];

        Contact[] contacts = TestDataFactory.getContactList(2, false);
        for(Contact c: contacts){
            c.Product__c = product.Id;
        }
        
        CurrencyType corporateCurrency = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true];
        if(corporateCurrency.IsoCode == 'EUR'){
            contacts[0].MailingCountryCode = 'US';
            contacts[0].CurrencyIsoCode = 'USD';    
        }
        else{
            contacts[0].MailingCountryCode = 'ES';
            contacts[0].CurrencyIsoCode = 'EUR';    
        }
        
        insert contacts;

        Id[] priceBookIdList = new Id[2];
        priceBookIdList[0] = Test.getStandardPricebookId();
        priceBookIdList[1] = TestDataFactory.getPriceBookList(1, true)[0].Id;

        PricebookEntry[] priceBookEntriesToCreate = TestDataFactory.getPriceBookEntryList(2, false, false);
        for(Integer i = 0; i < priceBookEntriesToCreate.size(); i++){
            priceBookEntriesToCreate[i].Pricebook2Id = priceBookIdList[i];
            priceBookEntriesToCreate[i].Product2Id = product.Id;
        }

        insert priceBookEntriesToCreate;
        
        Test.startTest();
        ProductDataProcessor.ProductWrapper wrapper = ProductDataProcessor.buildParentProductWrappers(new Set<Id>{product.Id})[0];
        Test.stopTest();        

        Set<String> pricebookIsoCodes = wrapper.productPriceBooks[0].countryCodeToPriceMap.keySet();
        Map<String, CurrencyType> isoCodeToCurrencyTypeMap = new Map<String, CurrencyType>();
        CurrencyType[] currencyTypes = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode IN :pricebookIsoCodes];

        Assert.areEqual(contacts.size(), currencyTypes.size(), 'One currency type should be implemented for every contact');
    }

    @isTest static void initCountryCodeToPriceMapCurrencyNotFound(){
        Integer unitPrice = 5;
        CurrencyType corporateCurrency = [SELECT ConversionRate FROM CurrencyType WHERE IsCorporate = true];
        Test.startTest();
        ProductDataProcessor.PricebookWrapper wrapper = new ProductDataProcessor.PricebookWrapper(new PricebookEntry(UnitPrice = unitPrice), new Map<String, CurrencyType>{
            'Standard' => corporateCurrency
            }, new String[]{'Iso code not found'}
        );
        Test.stopTest();
        Assert.areEqual(unitPrice / corporateCurrency.ConversionRate, wrapper.countryCodeToPriceMap.get('Standard'));
    }
}