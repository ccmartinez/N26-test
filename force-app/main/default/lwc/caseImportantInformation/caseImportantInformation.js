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

    setErrorCode(val){
        this.errorCodePopulated = true;
        this.errorCode = val;
    }

    renderedCallback(){
        this.retreiveData();
    }

    retreiveData(){
        debugger;
        getProductsImportantDataBasedOnCases({caseIds: [this.recordId]}).then(productWrappers => {
            productWrappers.forEach(productWrapper => {
                this.columns.push({label: productWrapper.productName, fieldName: 'priceBookName'});
                productWrapper.contactHomeCountries.forEach(contactHomeCountry => {
                    this.columns.push({label: contactHomeCountry, fieldName: contactHomeCountry});
                })

                productWrapper.productPriceBooks.forEach(priceBook => {
                    let priceBookWrapper = {};
                    priceBookWrapper.priceBookName = priceBook.name;
                    
                    priceBook.prices.forEach(price => {
                        priceBookWrapper[price.countryCode] = price.currencyType + ' ' + price.priceBookPrice;
                    })
                    this.data.push(priceBookWrapper);
                })
            });
            this.showSpinner = false; 
        }).catch(error => {
            this.showError = true;
            if(error instanceof TypeError){
                this.errorMessage = error.message;    
            }
            else{
                this.errorMessage = error.statusText;
                this.setErrorCode(error.status);
            }

            this.showSpinner = false;
        });
    }
}