public with sharing class CaseImportantInformationController {
    @AuraEnabled
    public static ProductWrapper[] getProductsImportantData(String[] caseIds){
        Case[] casesToProcess = [SELECT Contact.Product__c, Contact.Product__r.Name FROM Case WHERE Id IN :caseIds];
        Set<Id> productIds = new Set<Id>();

        for(Case caseToProcess: casesToProcess){
            productIds.add(caseToProcess.Contact.Product__c);
        }

        return buildParentProductWrappers(productIds);
    }

    private static ProductWrapper[] buildParentProductWrappers(Set<Id> productIds){
        ProductWrapper[] wrappersToReturn = new ProductWrapper[0];
        Map<Id, Contact[]> productIdToContactsMap = new Map<Id, Contact[]>();
        Map<Id, PricebookEntry[]> productIdToPriceBookEntriesMap = new Map<Id, PricebookEntry[]>();

        Contact[] parentProductsContacts = [SELECT Home_Country__c, Product__c, Product__r.Name FROM Contact WHERE Product__c IN :productIds];
        PricebookEntry[] productsPriceBookEntries = [
            SELECT CurrencyIsoCode, Location__c, Pricebook2.Name, Product2.Parent_Product__c, Product2.Parent_Product__r.QuantityUnitOfMeasure, UnitPrice 
            FROM PricebookEntry WHERE Product2.Parent_Product__c IN :productIds
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
            if(productIdToPriceBookEntriesMap.containsKey(productPriceBookEntry.Product2.Parent_Product__c)){
                productIdToPriceBookEntriesMap.get(productPriceBookEntry.Product2.Parent_Product__c).add(productPriceBookEntry);
            }
            else{
                productIdToPriceBookEntriesMap.put(productPriceBookEntry.Product2.Parent_Product__c, new PricebookEntry[]{productPriceBookEntry});
            }
        }

        for(Id productId: productIds){
            Contact[] parentProductContacts = productIdToContactsMap.get(productId);

            if(!parentProductContacts.isEmpty()){
                PricebookEntry[] productPricebookEntries = productIdToPriceBookEntriesMap.get(productId);
                wrappersToReturn.add(new ProductWrapper(parentProductContacts[0].Product__r.Name, parentProductContacts, productPricebookEntries));
            }
        }
        
        return wrappersToReturn;
    }

    public class ProductWrapper{
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public String[] contactHomeCountries;
        @AuraEnabled
        public PriceBookWrapper[] productPriceBooks;

        public ProductWrapper(){}
        public ProductWrapper(String productName, Contact[] contactList, PricebookEntry[] priceBookEntryList){
            this.productName = productName;
            contactHomeCountries = new String[0];
            Set<String> contactHomeCountriesAsSet = new Set<String>();
            
            Map<String, PricebookEntry[]> priceBookIdToEntriesMap = new Map<String, PricebookEntry[]>();

            for(Contact c: contactList){
                contactHomeCountriesAsSet.add(c.Home_Country__c);
            }

            contactHomeCountries.addAll(contactHomeCountriesAsSet);

            for(PricebookEntry priceBookEntry: priceBookEntryList){
                if(priceBookIdToEntriesMap.containsKey(priceBookEntry.Pricebook2Id)){
                    priceBookIdToEntriesMap.get(priceBookEntry.Pricebook2Id).add(priceBookEntry);
                }
                else{
                    priceBookIdToEntriesMap.put(priceBookEntry.Pricebook2Id, new PricebookEntry[]{priceBookEntry});
                }
            }

            for(PricebookEntry[] entriesOfAPriceBook: priceBookIdToEntriesMap.values()){
                productPriceBooks.add(new PriceBookWrapper(entriesOfAPriceBook, contactHomeCountriesAsSet));
            }
        }
    }

    public class PriceBookWrapper{
        @AuraEnabled
        public String priceBookName;
        @AuraEnabled
        public PriceWrapper[] priceBookPrices;
        
        public PriceBookWrapper(PricebookEntry[] priceBookEntryList, Set<String> countryCodes){
            priceBookPrices = new PriceWrapper[0];

            Map<String, PricebookEntry> countryCodeToPriceBookEntryMap = new Map<String, PricebookEntry>();

            for(PricebookEntry entry: priceBookEntryList){
                countryCodeToPriceBookEntryMap.put(entry.Location__c.getCountryCode(), entry);
            }
            for(String countryCode: countryCodes){
                PricebookEntry countryCodeEntry = countryCodeToPriceBookEntryMap.get(countryCode);
                priceBookPrices.add(new PriceWrapper(countryCodeEntry));
            }
        }
    }

    public class PriceWrapper{
        @AuraEnabled
        public Decimal priceBookPrice;
        @AuraEnabled
        public String currencyType;

        public PriceWrapper(PricebookEntry entry){
            priceBookPrice = entry.UnitPrice;

            if(entry.Product2.Parent_Product__r.QuantityUnitOfMeasure == 'Percentage'){{
                currencyType = '%';
            }}
            else{
                currencyType = entry.CurrencyIsoCode;
            }
        }
    }
}