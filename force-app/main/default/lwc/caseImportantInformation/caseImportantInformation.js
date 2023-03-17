import { LightningElement, track, api} from 'lwc';
import getProductsImportantDataBasedOnCases from '@salesforce/apex/CaseImportantInformationController.getProductsImportantDataBasedOnCases';

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
    alreadyRendered = false;

    setErrorCode(val){
        this.errorCodePopulated = true;
        this.errorCode = val;
    }

    renderedCallback(){
        this.alreadyRendered = true;
        this.retreiveData();
    }

    retreiveData(){
        getProductsImportantDataBasedOnCases({caseIds: [this.recordId]}).then(productWrappers => {
            try{
                productWrappers.forEach(productWrapper => {
                    this.columns.push({label: productWrapper.productName, fieldName: 'priceBookName'});
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
                        priceBookWrapper.priceBookName = priceBook.name;
                        
                        Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).forEach(contactHomeCountry => {
                            priceBookWrapper[contactHomeCountry] = priceBook.price;
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
            column = {label: contactHomeCountry, fieldName: contactHomeCountry, type: 'percent'}
        }
        else{
            column = {
                label: contactHomeCountry, fieldName: contactHomeCountry, type: 'currency', typeAttributes: {
                    currencyCode: productWrapper.contactHomeCountriesToCurrencyIsoCodes[contactHomeCountry]
                }
            }
        }
        this.columns.push(column);
    }
}