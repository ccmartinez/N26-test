@isTest
public with sharing class CaseImportantInformationControllerTest {
    @isTest static void getProductsImportantDataBasedOnCases(){
        Product2 product = new Product2(Name = 'Product name', isActive = true);
        insert product;

        Contact contactConnectedToCase = new Contact(LastName = 'LastName',Product__c = product.Id);
        Contact contactNotConnectedToCase = new Contact(LastName = 'LastName',Product__c = product.Id);
        insert new Contact[]{contactConnectedToCase, contactNotConnectedToCase};

        Case newCase = new Case(ContactId = contactConnectedToCase.Id);
        insert newCase;

        Id standardPricebookId = Test.getStandardPricebookId();
        Pricebook2 testPriceBook = new Pricebook2(Name = 'Test price book');
        insert testPriceBook;
        Id[] priceBookIdList = new Id[2];
        priceBookIdList[0] = standardPricebookId;
        priceBookIdList[1] = testPriceBook.Id;

        Integer numberOfPricebookEntriesToCreate = 2;
        PricebookEntry[] priceBookEntriesToCreate = new PricebookEntry[numberOfPricebookEntriesToCreate];
        for(Integer i = 0; i < numberOfPricebookEntriesToCreate; i++){
            priceBookEntriesToCreate[i] = new PricebookEntry(Pricebook2Id = priceBookIdList[i], Product2Id = product.Id, UnitPrice = i);
        }

        insert priceBookEntriesToCreate;
        
        CaseImportantInformationController.getProductsImportantDataBasedOnCases(new String[]{newCase.Id});
    }
}