@isTest
public with sharing class ProductRestServiceTest {
    @isTest static void getContactProductImportantData(){
        TestDataFactory.getPriceBookEntryList(1, true, true);
        Contact c = TestDataFactory.getContactList(1, false)[0];
        c.Product__c = [SELECT Id FROM Product2 LIMIT 1].Id;
        insert c;

        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/Contact/' + c.UUID__c; 
        
        Test.startTest();
        Map<String, String> response = ProductRestService.getContactProductImportantData();
        Test.stopTest();

        String responseAsJson = response.get('Product Data');
        ProductDataProcessor.ProductWrapper[] responseWrapper = (ProductDataProcessor.ProductWrapper[]) JSON.deserialize(responseAsJson, ProductDataProcessor.ProductWrapper[].class);
        Assert.areEqual(c.Product__c, responseWrapper[0].id);
    }
}