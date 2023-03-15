public with sharing class CaseImportantInformationController {
    @AuraEnabled
    public static ContactWrapper[] getContactProductsImportantData(String[] caseIds){
        Case[] casesToProcess = [SELECT Contact.Product__c, Contact.Product__r.Name, Contact.Home_Country__c FROM Case WHERE Id IN :caseIds];
        ContactWrapper[] contactsToReturn = new ContactWrapper[0];

        for(Case caseToProcess: casesToProcess){
            contactsToReturn.add(new ContactWrapper(caseToProcess.Contact.Home_Country__c, caseToProcess.Contact.Product__r.Name));
        }

        return contactsToReturn;
    }

    public static ContactWrapper[] getProductsImportantData(String[] contactIds){
        Contact[] contactsToProcess = [SELECT Name, Home_Country__c FROM Contact WHERE Id IN :contactIds];
        ContactWrapper[] contactsToReturn = new ContactWrapper[0];

        for(Contact contactToProcess: contactsToProcess){
            contactsToReturn.add(new ContactWrapper(contactToProcess.Home_Country__c, contactToProcess.Product__r.Name));
        }

        return contactsToReturn;
    }

    public class ContactWrapper{
        @AuraEnabled
        public String contactHomeCountry, contactProductName;

        public ContactWrapper(String contactHomeCountry, String contactProductName){
            this.contactHomeCountry = contactHomeCountry;
            this.contactProductName = contactProductName;
        }
    }

        }
    }
}