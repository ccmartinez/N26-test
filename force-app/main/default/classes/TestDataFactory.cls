@isTest
public with sharing class TestDataFactory {
    public static Product2[] getProductList(Integer numberOfObjectsToCreate, Boolean doInsert){
        Product2[] listToReturn = new Product2[numberOfObjectsToCreate];
        for(Integer i = 0; i < numberOfObjectsToCreate; i++){
            listToReturn[i] = new Product2(Name = 'Product ' + i, IsActive = true);
        }

        if(doInsert){
            insert listToReturn;
        }

        return listToReturn;
    }

    public static Contact[] getContactList(Integer numberOfObjectsToCreate, Boolean doInsert){
        Contact[] listToReturn = new Contact[numberOfObjectsToCreate];

        for(Integer i = 0; i < numberOfObjectsToCreate; i++){
            listToReturn[i] = new Contact(LastName = 'LastName');
        }

        if(doInsert){
            insert listToReturn;
        }
        
        return listToReturn;
    }

    public static Pricebook2[] getPriceBookList(Integer numberOfObjectsToCreate, Boolean doInsert){
        Pricebook2[] listToReturn = new Pricebook2[numberOfObjectsToCreate];

        for(Integer i = 0; i < numberOfObjectsToCreate; i++){
            listToReturn[i] = new Pricebook2(Name = 'Name');
        }

        if(doInsert){
            insert listToReturn;
        }
        
        return listToReturn;
    }

    public static PricebookEntry[] getPriceBookEntryList(Integer numberOfObjectsToCreate, Boolean createParents, Boolean doInsert){
        PricebookEntry[] listToReturn = new PricebookEntry[numberOfObjectsToCreate];

        for(Integer i = 0; i < numberOfObjectsToCreate; i++){
            listToReturn[i] = new PricebookEntry(UnitPrice = i + 1);
        }

        if(createParents){
            Pricebook2[] priceBookList = getPriceBookList(numberOfObjectsToCreate, true);
            Product2[] productList = getProductList(numberOfObjectsToCreate, true);

            for(Integer i = 0; i < numberOfObjectsToCreate; i++){
                listToReturn[i].Pricebook2Id = priceBookList[i].Id;
                listToReturn[i].Product2Id = productList[i].Id;
            }
        }

        if(doInsert){
            insert listToReturn;
        }
        
        return listToReturn;
    }
}