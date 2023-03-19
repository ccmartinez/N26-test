In order for the components and classes contained in this repository to be deployed and work as expected, the following manual settings are required:
-Go to the "state and country/territory picklists" option in the setup menu and follow the steps to enable the country picklists for address fields (the disabled button), wait for it to finish before proceeding
-Go to "company information" in the setup menu and click on the "activate multiple currencies" checkbox
-Set up the currencies to be used by clicking on the "Setup currencies" button
-deploy the home country and product custom fields (Contact.Product__c, Contact.Home_Country__c and Contact.UUID__c)
-modify the existing page layouts to add the new custom fields
-modify the existing profiles for proper access to the new custom fields
-deploy the rest of the components
-edit the case page layout to display the lightning web component there (it should appear in the custom components section of the lightning app builder menu)