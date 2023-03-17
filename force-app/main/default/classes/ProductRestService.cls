@RestResource(urlMapping='/Contact/*')
global with sharing class ProductRestService {

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