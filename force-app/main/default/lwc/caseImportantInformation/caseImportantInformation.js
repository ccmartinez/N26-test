import { LightningElement, track, api} from 'lwc';
import getProductsImportantDataBasedOnCases from '@salesforce/apex/CaseImportantInformationController.getProductsImportantDataBasedOnCases';
import { updateRecord } from 'lightning/uiRecordApi';

export default class CaseImportantInformation extends LightningElement {
    @api recordId;
    @track contactProductHyperLink = null;
    @track contactHomeCountry = null;
    @track showSpinner = true;
    @track showError = false;
    @track errorCode = null;
    @track errorCodePopulated = false;
    @track errorMessage = null;
    data = [];
    columns = [];
    draftValues = [];
    alreadyRendered = false;

    setErrorCode(val){
        this.errorCodePopulated = true;
        this.errorCode = val;
    }

    renderedCallback(){
        if(!this.alreadyRendered){
            this.alreadyRendered = true;
            this.retreiveData();
        }
    }

    retreiveData(){
        getProductsImportantDataBasedOnCases({caseIds: [this.recordId]}).then(productWrappers => {
            try{
                productWrappers.forEach(productWrapper => {
                    this.columns.push({editable: true, label: productWrapper.productName, fieldName: 'priceBookName'});
                    if(Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).includes('Standard')){ //Standard value should always be displayed first
                        this.addCountryCodeColumnToTable('Standard', productWrapper);
                    }

                    Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).forEach(contactHomeCountry => {
                        if(contactHomeCountry != 'Standard'){
                            this.addCountryCodeColumnToTable(contactHomeCountry, productWrapper);
                        }
                    })
    
                    productWrapper.productPriceBooks.forEach(priceBook => {
                        let priceBookWrapper = {};
                        priceBookWrapper.Id = priceBook.Id;
                        priceBookWrapper.priceBookName = priceBook.name;
                        
                        Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).forEach(contactHomeCountry => {
                            let currencyIsoCode = productWrapper.contactHomeCountriesToCurrencyIsoCodes[contactHomeCountry];
                            priceBookWrapper[contactHomeCountry] = priceBook.countryCodeToPriceMap[currencyIsoCode];
                        })
                        this.data.push(priceBookWrapper);
                    })
                });
                this.showSpinner = false;
            }catch(error){
                this.processError(error)
            }
             
        }).catch(error => this.processError(error));
    }

    handleSave(event) {
        let saveDraftValues = event.detail.draftValues;

        saveDraftValues.forEach(element => {
            Object.keys(element).forEach(fieldName => {
                if(fieldName != 'Id'){
                    element['UnitPrice'] = element[fieldName];
                    delete element[fieldName];
                }
            });    
        });
 
        updateRecord(saveDraftValues[0]);
    }

    processError(error){
        this.showError = true;
        if(error.status == null){
            this.errorMessage = error.message;    
        }
        else{
            this.errorMessage = error.statusText;
            this.setErrorCode(error.status);
        }

        this.showSpinner = false;
    }

    addCountryCodeColumnToTable(contactHomeCountry, productWrapper){
        let column;
        if(productWrapper.priceInPercent){
            column = {editable: true, label: contactHomeCountry, fieldName: contactHomeCountry, type: 'percent'}
        }
        else{
            column = {
                editable: true, label: contactHomeCountry, fieldName: contactHomeCountry, type: 'currency', typeAttributes: {
                    currencyCode: productWrapper.contactHomeCountriesToCurrencyIsoCodes[contactHomeCountry]
                }
            }
        }
        this.columns.push(column);
    }
}