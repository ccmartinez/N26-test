public with sharing class CaseImportantInformationController {
    public static ProductWrapper getContactProductImportantData(Id caseId){
        Case caseToProcess = [SELECT Contact.Product__c, Contact.Home_Country__c FROM Case WHERE Id = :caseId];

        return new ProductWrapper(caseToProcess.Contact.Product__c, caseToProcess.Contact.Home_Country__c);
    }

    public class ProductWrapper{
        String contactProduct, contactHomeCountry;

        public ProductWrapper(String contactProduct, String contactHomeCountry){
            this.contactProduct = contactProduct;
            this.contactHomeCountry = contactHomeCountry;
        }
    }
}