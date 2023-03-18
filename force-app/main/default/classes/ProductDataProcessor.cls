public with sharing class ProductDataProcessor {
    public static ProductWrapper[] buildParentProductWrappers(Set<Id> productIds){
        ProductWrapper[] wrappersToReturn = new ProductWrapper[0];
        Map<Id, Contact[]> productIdToContactsMap = new Map<Id, Contact[]>();
        Map<Id, PricebookEntry[]> productIdToPriceBookEntriesMap = new Map<Id, PricebookEntry[]>();

        Contact[] parentProductsContacts = [
            SELECT CurrencyIsoCode, Home_Country__c, Product__c, Product__r.Name, Product__r.QuantityUnitOfMeasure FROM Contact 
            WHERE Product__c IN :productIds AND Product__r.isActive = true
        ];

        PricebookEntry[] productsPriceBookEntries = [
            SELECT Location__c, Pricebook2.Name, Product2Id, Product2.CurrencyIsoCode, Product2.Name, Product2.QuantityUnitOfMeasure, UnitPrice 
            FROM PricebookEntry WHERE Product2Id IN :productIds AND Product2.isActive = true
        ];

        for(Contact c: parentProductsContacts){
            if(productIdToContactsMap.containsKey(c.Product__c)){
                productIdToContactsMap.get(c.Product__c).add(c);
            }
            else{
                productIdToContactsMap.put(c.Product__c, new Contact[]{c});
            }
        }

        Map<String, CurrencyType> currencyCodeToCurrencyMap = getCurrencyCodeToCurrencyMap(parentProductsContacts);

        for(PricebookEntry productPriceBookEntry: productsPriceBookEntries){
            if(productIdToPriceBookEntriesMap.containsKey(productPriceBookEntry.Product2Id)){
                productIdToPriceBookEntriesMap.get(productPriceBookEntry.Product2Id).add(productPriceBookEntry);
            }
            else{
                productIdToPriceBookEntriesMap.put(productPriceBookEntry.Product2Id, new PricebookEntry[]{productPriceBookEntry});
            }
        }

        for(Id productId: productIds){
            Contact[] parentProductContacts = productIdToContactsMap.get(productId);

            if(parentProductContacts != null && !parentProductContacts.isEmpty()){
                Boolean priceInPercent = (parentProductContacts[0].Product__r.QuantityUnitOfMeasure == 'Percent');
                PricebookEntry[] productPricebookEntries = productIdToPriceBookEntriesMap.get(productId);
                wrappersToReturn.add(new ProductWrapper(
                    currencyCodeToCurrencyMap, priceInPercent, parentProductContacts, productPricebookEntries
                ));
            }
        }

        return wrappersToReturn;
    }

    private static Map<String, CurrencyType> getCurrencyCodeToCurrencyMap(Contact[] contactsToProcess){
        Set<String> contactsCurrencies = getContactCurrencyCodes(contactsToProcess);
        
        return getCurrencyCodeToCurrencyMap(contactsCurrencies);
    }

    public static Map<String, CurrencyType> getCurrencyCodeToCurrencyMap(Set<String> currencyIsoCodes){
        Map<String, CurrencyType> currencyCodeToCurrencyMap = new Map<String, CurrencyType>();
        CurrencyType[] currenciesToProcess = [SELECT ConversionRate, IsoCode, IsCorporate FROM CurrencyType WHERE IsCorporate = true OR IsoCode IN :currencyIsoCodes];

        for(CurrencyType contactCurrency: currenciesToProcess){
            currencyCodeToCurrencyMap.put(contactCurrency.IsoCode, contactCurrency);

            if(contactCurrency.IsCorporate){
                currencyCodeToCurrencyMap.put('Standard', contactCurrency);
            }
        }

        return currencyCodeToCurrencyMap;
    }

    private static Set<String> getContactCurrencyCodes(Contact[] parentProductsContacts){
        Set<String> contactHomeCountries = new Set<String>();
        for(Contact c: parentProductsContacts){
            contactHomeCountries.add(c.CurrencyIsoCode);
        }

        return contactHomeCountries;
    }

    public class ProductWrapper{
        @AuraEnabled
        public String name, id;
        @AuraEnabled
        public Boolean priceInPercent;
        @AuraEnabled
        public Map<String, String> contactHomeCountriesToCurrencyIsoCodes;
        @AuraEnabled
        public PriceBookWrapper[] productPriceBooks;

        public ProductWrapper(
            Map<String, CurrencyType> currencyCodeToCurrencyMap, Boolean priceInPercent, Contact[] contactList, PricebookEntry[] priceBookEntryList
        ){
            if(priceBookEntryList != null && !priceBookEntryList.isEmpty()){
                String productCountryCode = priceBookEntryList[0].Product2.CurrencyIsoCode;
                this.name = priceBookEntryList[0].Product2.Name;
                this.priceInPercent = priceInPercent;
                id = priceBookEntryList[0].Product2Id;
                contactHomeCountriesToCurrencyIsoCodes = new Map<String, String>();
                productPriceBooks = new PriceBookWrapper[0];
                
                for(Contact c: contactList){
                    if(c.Home_Country__c == null){
                        contactHomeCountriesToCurrencyIsoCodes.put('Standard', currencyCodeToCurrencyMap.get('Standard').IsoCode);
                    }
                    else{
                        contactHomeCountriesToCurrencyIsoCodes.put(c.Home_Country__c, c.CurrencyIsoCode);
                    }
                }

            
                for(PricebookEntry priceBookEntry: priceBookEntryList){
                    productPriceBooks.add(new PriceBookWrapper(priceBookEntry, currencyCodeToCurrencyMap, contactHomeCountriesToCurrencyIsoCodes.values()));
                }
            }
        }
    }

    public class PriceBookWrapper{
        @AuraEnabled
        public String id, productId, name;
        @AuraEnabled
        public Map<String, Decimal> countryCodeToPriceMap;
        
        public PriceBookWrapper(
            PricebookEntry priceBookEntry, Map<String, CurrencyType> currencyCodeToCurrencyMap, String[] currencyIsoCodes
        ){
            id = priceBookEntry.Id;
            productId = priceBookEntry.Product2Id;
            name = priceBookEntry.Pricebook2.Name;
            initCountryCodeToPriceMap(currencyCodeToCurrencyMap, currencyIsoCodes, priceBookEntry.UnitPrice);
        }

        private void initCountryCodeToPriceMap(Map<String, CurrencyType> currencyCodeToCurrencyMap, String[] currencyIsoCodes, Decimal unitPrice){
            countryCodeToPriceMap = new Map<String, Decimal>();


            for(String countryCode: currencyIsoCodes){
                CurrencyType isoCodeCurrency = currencyCodeToCurrencyMap.get(countryCode);
                if(isoCodeCurrency == null){
                    isoCodeCurrency = currencyCodeToCurrencyMap.get('Standard');
                }
                
                Decimal priceToAdd = unitPrice * isoCodeCurrency.ConversionRate;

                countryCodeToPriceMap.put(countryCode, priceToAdd);
            }
        }
    }
}