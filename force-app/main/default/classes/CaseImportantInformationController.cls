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
}