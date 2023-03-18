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
    public static void updatePriceBookList(String pricebookWrappersAsJson, Map<String, String> contactHomeCountriesToCurrencyIsoCodes){
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

        SObject[] recordsToUpdate = new SObject[0];
        Map<Id, PricebookEntry> entryMap = new Map<Id, PricebookEntry>([SELECT Product2Id, Pricebook2.Id FROM PricebookEntry WHERE Id IN :entryIds]);
        System.debug('entryids:' + entryIds);
        System.debug('entrymap:' + entryMap);

        for(ProductDataProcessor.PriceBookWrapper pricebookWrapper: pricebookWrappers){
            PricebookEntry entryToUpdate = entryMap.get(pricebookWrapper.id);

            if(entryToUpdate != null){
                if(pricebookWrapper.name != null){
                    entryToUpdate.Pricebook2.Name = pricebookWrapper.name;
                    recordsToUpdate.add(entryToUpdate.Pricebook2);
                }

                if(pricebookWrapper.countryCodeToPriceMap != null){
                    for(String countryCode: pricebookWrapper.countryCodeToPriceMap.keySet()){
                        Decimal originalUnitPriceSet = pricebookWrapper.countryCodeToPriceMap.get(countryCode);
                        String entryCurrencyIsoCode = contactHomeCountriesToCurrencyIsoCodes.get(countryCode);
                        Decimal unitPriceConversionRate = currencyCodeToCurrencyMap.get(entryCurrencyIsoCode).ConversionRate;
                        entryToUpdate.UnitPrice = originalUnitPriceSet / unitPriceConversionRate;
                        recordsToUpdate.add(entryToUpdate);
                        break;
                    }
                }
            }
        }

        update recordsToUpdate;
    }
}