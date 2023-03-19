public with sharing class CaseImportantInformationController {
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

    @AuraEnabled
    public static void upsertPriceBookList(String pricebookWrappersAsJson, Map<String, String> contactHomeCountriesToCurrencyIsoCodes){
        ProductDataProcessor.PriceBookWrapper[] pricebookWrappers = (ProductDataProcessor.PriceBookWrapper[]) JSON.deserialize(
            pricebookWrappersAsJson, ProductDataProcessor.PriceBookWrapper[].class
        );

        Set<String> currencyIsoCodes = new Set<String>();
        currencyIsoCodes.addAll(contactHomeCountriesToCurrencyIsoCodes.values());

        Map<String, CurrencyType> currencyCodeToCurrencyMap = ProductDataProcessor.getCurrencyCodeToCurrencyMap(currencyIsoCodes);
        Set<Id> entryIds = new Set<Id>();
        for(ProductDataProcessor.PriceBookWrapper pricebookWrapper: pricebookWrappers){
            entryIds.add(pricebookWrapper.id);
        }

        PricebookEntry[] entriesToUpsert = new PricebookEntry[0];
        Pricebook2[] priceBooksToUpsert = new Pricebook2[0];
        Map<Id, PricebookEntry> entryMap = new Map<Id, PricebookEntry>([SELECT Product2Id, Pricebook2.Id FROM PricebookEntry WHERE Id IN :entryIds]);

        for(ProductDataProcessor.PriceBookWrapper pricebookWrapper: pricebookWrappers){
            if((pricebookWrapper.name == null && pricebookWrapper.id == null) || pricebookWrapper.countryCodeToPriceMap == null){
                throw new CustomException('Required fields missing');
            }

            PricebookEntry entryToUpsert = entryMap.get(pricebookWrapper.id);

            if(entryToUpsert == null){
                entryToUpsert = new PricebookEntry();
                entryToUpsert.Pricebook2 = new Pricebook2();
                entryToUpsert.Product2Id = pricebookWrapper.productId;
            }

            if(pricebookWrapper.name != null){
                if(entryToUpsert.Pricebook2 == null){
                    entryToUpsert.Pricebook2 = new Pricebook2();
                }
                
                entryToUpsert.Pricebook2.Name = pricebookWrapper.name;
                priceBooksToUpsert.add(entryToUpsert.Pricebook2);
            }

            for(String countryCode: pricebookWrapper.countryCodeToPriceMap.keySet()){
                    Decimal originalUnitPriceSet = pricebookWrapper.countryCodeToPriceMap.get(countryCode);
                    String entryCurrencyIsoCode = contactHomeCountriesToCurrencyIsoCodes.get(countryCode);
                    Decimal unitPriceConversionRate = currencyCodeToCurrencyMap.get(entryCurrencyIsoCode).ConversionRate;
                    entryToUpsert.UnitPrice = originalUnitPriceSet / unitPriceConversionRate;
                    entriesToUpsert.add(entryToUpsert);
                    break;
            }
        }

        upsert priceBooksToUpsert;
        for(PricebookEntry entry: entriesToUpsert){
            if(entry.Id == null){
                entry.Pricebook2Id = entry.Pricebook2.Id;
            }
        }

        upsert entriesToUpsert;
    }

    public class CustomException extends Exception {
        
    }
}