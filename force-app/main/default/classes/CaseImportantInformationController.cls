public with sharing class CaseImportantInformationController {
    /**
     * @author Carlos Cañizares
     * Retreives data from the server to be displayed in the table, in the format of a custom wrapper
     */
    @AuraEnabled
    public static ProductDataProcessor.ProductWrapper[] getProductsImportantDataBasedOnCases(String[] caseIds){
        Case[] casesToProcess = [SELECT Contact.Product__c, Contact.Product__r.Name FROM Case WHERE Id IN :caseIds];
        Set<Id> productIds = new Set<Id>();

        for(Case caseToProcess: casesToProcess){
            if(caseToProcess?.Contact?.Product__c != null){
                productIds.add(caseToProcess.Contact.Product__c);
            }
        }

        return ProductDataProcessor.buildParentProductWrappers(productIds);
    }

    /**
     * @author Carlos Cañizares
     * Applies the changes the user did in the table to the database
     */
    @AuraEnabled
    public static void upsertPriceBookList(String pricebookWrappersAsJson, Map<String, String> contactHomeCountriesToCurrencyIsoCodes){
        ProductDataProcessor.PriceBookWrapper[] pricebookWrappers = (ProductDataProcessor.PriceBookWrapper[]) JSON.deserialize(
            pricebookWrappersAsJson, ProductDataProcessor.PriceBookWrapper[].class
        );

        Set<String> currencyIsoCodes = new Set<String>();
        currencyIsoCodes.addAll(contactHomeCountriesToCurrencyIsoCodes.values());

        Map<String, CurrencyType> currencyCodeToCurrencyMap = ProductDataProcessor.getIsoCodeToCurrencyTypeMap(currencyIsoCodes);
        Set<Id> entryIds = new Set<Id>();
        for(ProductDataProcessor.PriceBookWrapper pricebookWrapper: pricebookWrappers){
            entryIds.add(pricebookWrapper.id);
        }

        PricebookEntry[] entriesToUpsert = new PricebookEntry[0];
        Pricebook2[] priceBooksToUpsert = new Pricebook2[0];
        Map<Id, PricebookEntry> entryMap = new Map<Id, PricebookEntry>([SELECT Product2Id, Product2.QuantityUnitOfMeasure, Pricebook2.Id FROM PricebookEntry 
            WHERE Id IN :entryIds
        ]);

        for(ProductDataProcessor.PriceBookWrapper pricebookWrapper: pricebookWrappers){
            if((pricebookWrapper.name == null && pricebookWrapper.id == null) || pricebookWrapper.countryCodeToPriceMap == null){
                throw new CustomException('Required fields missing');
            }

            PricebookEntry entryToUpsert = getEntry(entryMap, pricebookWrapper, priceBooksToUpsert);

            calculateUnitPriceForAnEntry(entryToUpsert, pricebookWrapper, contactHomeCountriesToCurrencyIsoCodes, currencyCodeToCurrencyMap);
            entriesToUpsert.add(entryToUpsert);
        }

        upsert priceBooksToUpsert;

        for(PricebookEntry entry: entriesToUpsert){
            if(entry.Id == null){
                entry.Pricebook2Id = entry.Pricebook2.Id; //Apply pricebook id just created above to it's related entries
            }
        }

        upsert entriesToUpsert;
    }

    private static void calculateUnitPriceForAnEntry(
        PricebookEntry entryToCalculate, ProductDataProcessor.PricebookWrapper pricebookWrapper, Map<String, String> contactHomeCountriesToCurrencyIsoCodes,
        Map<String, CurrencyType> currencyCodeToCurrencyMap
    ){
            String countryCode;
            for(String countryCodeInsideMap: pricebookWrapper.countryCodeToPriceMap.keySet()){ //We only need the first country code, changes in the currency will be automatically applied to the rest of currencies
                countryCode = countryCodeInsideMap;
                break;
            }

            Decimal originalUnitPriceSet = pricebookWrapper.countryCodeToPriceMap.get(countryCode);
            String entryCurrencyIsoCode = contactHomeCountriesToCurrencyIsoCodes.get(countryCode);
            Decimal unitPriceConversionRate = currencyCodeToCurrencyMap.get(entryCurrencyIsoCode).ConversionRate;

            entryToCalculate.UnitPrice = originalUnitPriceSet / unitPriceConversionRate;
            if(entryToCalculate.Product2?.QuantityUnitOfMeasure == 'Percent'){
                entryToCalculate.UnitPrice *= 100;
            }
    }

    /**
     * @author Carlos Cañizares
     * Searches for a price book that matches the given id, and if there is no entry found, a new one will be created, along with it's own price book
     */
    private static PricebookEntry getEntry(
        Map<Id, PricebookEntry> entryMap, ProductDataProcessor.PriceBookWrapper pricebookWrapper, Pricebook2[] pricebooksToUpsert
    ){
        PricebookEntry entry = entryMap.get(pricebookWrapper.id);

        if(entry == null){
            entry = new PricebookEntry();
            entry.Pricebook2 = new Pricebook2();
            entry.Product2Id = pricebookWrapper.productId;
        }

        if(pricebookWrapper.name != null){
            if(entry.Pricebook2 == null){
                entry.Pricebook2 = new Pricebook2();
            }
            
            entry.Pricebook2.Name = pricebookWrapper.name;
            priceBooksToUpsert.add(entry.Pricebook2);
        }

        return entry;
    }

    public class CustomException extends Exception {
        
    }
}