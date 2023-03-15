public with sharing class CaseImportantInformationController {
    @AuraEnabled
    public static ProductWrapper getContactProductImportantData(String caseId){
        Case caseToProcess = [SELECT Contact.Product__r.Name, Contact.Home_Country__c FROM Case WHERE Id = :caseId];

        String contactProductUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + caseToProcess.Contact.Product__c;

        return new ProductWrapper(caseToProcess.Contact.Home_Country__c, caseToProcess.Contact.Product__r.Name, contactProductUrl);
    }

    public class ProductWrapper{
        @AuraEnabled
        public String contactHomeCountry, contactProductName, contactProductUrl;

        public ProductWrapper(String contactHomeCountry, String contactProductName, String contactProductUrl){
            this.contactHomeCountry = contactHomeCountry;
            this.contactProductName = contactProductName;
            this.contactProductUrl = contactProductUrl;
        }
    }
}