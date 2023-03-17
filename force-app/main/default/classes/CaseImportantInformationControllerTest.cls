@isTest
public with sharing class CaseImportantInformationControllerTest {
    @isTest static void getProductsImportantDataBasedOnCases(){
        Product2 product = TestDataFactory.getProductList(1, true)[0];
        Contact contact = TestDataFactory.getContactList(1, false)[0];
        contact.Product__c = product.Id;
        insert contact;
        Case newCase = new Case(ContactId = contact.Id);
        insert newCase;

        CaseImportantInformationController.getProductsImportantDataBasedOnCases(new String[]{newCase.Id});
    }
}