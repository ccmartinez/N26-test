@isTest
public with sharing class ProductDataProcessorTest {
    @isTest static void buildParentProductWrappers(){
        Product2 product = TestDataFactory.getProductList(1, true)[0];

        Contact[] contacts = TestDataFactory.getContactList(2, false);
        for(Contact c: contacts){
            c.Product__c = product.Id;
        }
        
        contacts[0].MailingCountry = 'Spain';
        insert contacts;

        Case newCase = new Case(ContactId = contacts[0].Id);
        insert newCase;

        Id[] priceBookIdList = new Id[2];
        priceBookIdList[0] = Test.getStandardPricebookId();
        priceBookIdList[1] = TestDataFactory.getPriceBookList(1, true)[0].Id;

        PricebookEntry[] priceBookEntriesToCreate = TestDataFactory.getPriceBookEntryList(2, false, false);
        for(Integer i = 0; i < priceBookEntriesToCreate.size(); i++){
            priceBookEntriesToCreate[i].Pricebook2Id = priceBookIdList[i];
            priceBookEntriesToCreate[i].Product2Id = product.Id;
        }

        insert priceBookEntriesToCreate;
        
        CaseImportantInformationController.getProductsImportantDataBasedOnCases(new String[]{newCase.Id});
    }
}