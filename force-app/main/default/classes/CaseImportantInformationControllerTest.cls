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

    @isTest static void upsertPriceBookListInsert(){
        CurrencyType currencyToUse = getCurrencyToUse();
        PricebookEntry entryToInsert = TestDataFactory.getPriceBookEntryList(1, true, false)[0];
        insert new PricebookEntry(Product2Id = entryToInsert.Product2Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 5); //Avoid missing standard pricebook error

        upsertPriceBookList(entryToInsert, currencyToUse);
        Assert.isTrue(![SELECT Id FROM PriceBookEntry].isEmpty());
    }

    @isTest static void upsertPriceBookListUpdate(){
        CurrencyType currencyToUse = getCurrencyToUse();
        PricebookEntry entryToUpdate = TestDataFactory.getPriceBookEntryList(1, true, false)[0];
        entryToUpdate.UnitPrice = 5;
        insert entryToUpdate;

        upsertPriceBookList(entryToUpdate, currencyToUse);
    }

    @isTest static void upsertPriceBookListErrorMessage(){
        Boolean exceptionCaught = false;
        ProductDataProcessor.PriceBookWrapper[] pricebookWrappers = new ProductDataProcessor.PriceBookWrapper[1];
        pricebookWrappers[0] = new ProductDataProcessor.PriceBookWrapper(
            new PricebookEntry(), new Map<String, CurrencyType>(), new String[0], false
        );

        Test.startTest();
        try{
            CaseImportantInformationController.upsertPriceBookList(JSON.serialize(pricebookWrappers), new Map<String, String>());
        }catch(CaseImportantInformationController.CustomException e){
            exceptionCaught = true;
        }

        Assert.isTrue(exceptionCaught);
    }

    private static CurrencyType getCurrencyToUse(){
        CurrencyType currencyToUse = [SELECT ConversionRate, IsoCode FROM CurrencyType WHERE IsoCode = 'GBP'];
        Assert.areNotEqual(1, currencyToUse.ConversionRate, 'Please select a more complex rate for proper currency conversion testing');
        
        return currencyToUse;
    }

    private static void upsertPriceBookList(PricebookEntry entryToUpsert, CurrencyType currencyToUse){
        entryToUpsert.Pricebook2 = new Pricebook2();
        Map<String, String> contactHomeCountriesToCurrencyIsoCodes = new Map<String, String>{
            'Standard' => currencyToUse.IsoCode
        };
        Map<String, CurrencyType> currencyCodeToCurrencyMap = new Map<String, CurrencyType>{
            'EUR' => currencyToUse
        };
        String[] currencyCodes = new String[0];
        currencyCodes.addAll(currencyCodeToCurrencyMap.keySet());

        ProductDataProcessor.PriceBookWrapper[] pricebookWrappers = new ProductDataProcessor.PriceBookWrapper[1];
        pricebookWrappers[0] = new ProductDataProcessor.PriceBookWrapper(
            entryToUpsert, currencyCodeToCurrencyMap, currencyCodes, false
        );

        pricebookWrappers[0].id = entryToUpsert.Id;
        pricebookWrappers[0].productId = entryToUpsert.Product2Id;
        pricebookWrappers[0].name = 'Pricebook name';
        pricebookWrappers[0].countryCodeToPriceMap = new Map<String, Decimal>{'Standard' => currencyToUse.ConversionRate};

        Test.startTest();
        CaseImportantInformationController.upsertPriceBookList(JSON.serialize(pricebookWrappers), contactHomeCountriesToCurrencyIsoCodes);
        Test.stopTest();

        PriceBookEntry[] entriesInDb = [SELECT Pricebook2.Name, UnitPrice FROM PriceBookEntry WHERE Id = :entryToUpsert.Id]; 
        if(entriesInDb.isEmpty()){
            entriesInDb = [SELECT Pricebook2.Name, UnitPrice FROM PriceBookEntry WHERE Pricebook2.Name = :pricebookWrappers[0].name]; //common sense tells us to use a single query with 2 conditions, but apex does not seem to follow it here, since joining these two queries into a single one sometimes does not return any record, feel free to test it by yourself
        }

        Assert.isTrue(!entriesInDb.isEmpty(), 'No entries were created for the given product and pricebook');
        Assert.areEqual(1, entriesInDb[0].UnitPrice);
    }
}