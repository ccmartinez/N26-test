public with sharing class ProductDataProcessor {
    public static ProductWrapper[] buildParentProductWrappers(Set<Id> productIds){
        ProductWrapper[] wrappersToReturn = new ProductWrapper[0];
        Map<Id, Contact[]> productIdToContactsMap = new Map<Id, Contact[]>();
        Map<Id, PricebookEntry[]> productIdToPriceBookEntriesMap = new Map<Id, PricebookEntry[]>();
        String defaultCurrencyCode = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true].IsoCode;

        Contact[] parentProductsContacts = [
            SELECT CurrencyIsoCode, Home_Country__c, Product__c, Product__r.Name, Product__r.QuantityUnitOfMeasure FROM Contact 
            WHERE Product__c IN :productIds AND Product__r.isActive = true
        ];
        PricebookEntry[] productsPriceBookEntries = [
            SELECT Location__c, Pricebook2.Name, Product2Id, Product2.QuantityUnitOfMeasure, UnitPrice 
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
                System.debug(parentProductContacts[0].Product__r.QuantityUnitOfMeasure);
                Boolean priceInPercent = (parentProductContacts[0].Product__r.QuantityUnitOfMeasure == 'Percent');
                System.debug(priceInPercent);
                PricebookEntry[] productPricebookEntries = productIdToPriceBookEntriesMap.get(productId);
                wrappersToReturn.add(new ProductWrapper(
                    defaultCurrencyCode, priceInPercent, 
                    parentProductContacts[0].Product__r.Name, parentProductContacts, productPricebookEntries
                ));
            }
        }
        
        System.debug(wrappersToReturn);
        return wrappersToReturn;
    }

    public class ProductWrapper{
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Boolean priceInPercent;
        @AuraEnabled
        public Map<String, String> contactHomeCountriesToCurrencyIsoCodes;
        @AuraEnabled
        public PriceBookWrapper[] productPriceBooks;

        public ProductWrapper(String defaultCurrencyCode, Boolean priceInPercent, String productName, Contact[] contactList, PricebookEntry[] priceBookEntryList){
            this.productName = productName;
            this.priceInPercent = priceInPercent;
            contactHomeCountriesToCurrencyIsoCodes = new Map<String, String>();
            productPriceBooks = new PriceBookWrapper[0];
            
            Map<String, PricebookEntry> priceBookIdToEntryMap = new Map<String, PricebookEntry>();

            for(Contact c: contactList){
                if(c.Home_Country__c == null){
                    contactHomeCountriesToCurrencyIsoCodes.put('Standard', defaultCurrencyCode);
                }
                else{
                    contactHomeCountriesToCurrencyIsoCodes.put(c.Home_Country__c, c.CurrencyIsoCode);
                }
            }

            if(priceBookEntryList != null){
                for(PricebookEntry priceBookEntry: priceBookEntryList){
                    priceBookIdToEntryMap.put(priceBookEntry.Pricebook2Id, priceBookEntry);
                }
    
                for(PricebookEntry entry: priceBookIdToEntryMap.values()){
                    productPriceBooks.add(new PriceBookWrapper(entry));
                }
            }
        }
    }

    public class PriceBookWrapper{
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Decimal price;
        
        public PriceBookWrapper(PricebookEntry priceBookEntry){
            name = priceBookEntry.Pricebook2.Name;
            price = priceBookEntry.UnitPrice;
        }
    }
}