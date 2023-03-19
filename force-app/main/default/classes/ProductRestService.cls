@RestResource(urlMapping='/Contact/*')
global with sharing class ProductRestService {

    /**
     * @author Carlos Cañizares
     * Takes the contact uuid passed as a parameter in the url and uses it to search the database for a matching contact, and returns a wrapper with all it's product data so
     * it can be displayed in a table
     */
    @HttpGet
    global static Map<String, String> getContactProductImportantData() {
        String contactUUID = RestContext.request.requestURI.split('/')[2];
        
        try{
            Contact contactToProcess = [SELECT Product__c FROM Contact WHERE UUID__c = :contactUUID];

            String response = JSON.serialize(ProductDataProcessor.buildParentProductWrappers(new Set<Id>{contactToProcess.Product__c}));
            System.debug(response);
            return new Map<String, String>{
                'Product Data' => response
            };
        }catch(QueryException e){
            return new Map<String, String>{
                'error' => 'The specified UUID is not related to any contact'
            };
        }
    }
}