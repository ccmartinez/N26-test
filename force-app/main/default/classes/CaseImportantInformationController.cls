public with sharing class CaseImportantInformationController {
    @AuraEnabled
    public static ProductWrapper getContactProductImportantData(String caseId){
        Case caseToProcess = [SELECT Contact.Product__c, Contact.Home_Country__c FROM Case WHERE Id = :caseId];

        ProductWrapper wrapperToReturn = new ProductWrapper(caseToProcess.Contact.Product__c, caseToProcess.Contact.Home_Country__c);
        System.debug(wrapperToReturn);
        return wrapperToReturn;
    }

    public class ProductWrapper{
        @AuraEnabled
        public String contactProduct, contactHomeCountry;

        public ProductWrapper(String contactProduct, String contactHomeCountry){
            this.contactProduct = contactProduct;
            this.contactHomeCountry = contactHomeCountry;
        }
    }
}