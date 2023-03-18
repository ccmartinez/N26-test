import { LightningElement, track, api} from 'lwc';
import getProductsImportantDataBasedOnCases from '@salesforce/apex/CaseImportantInformationController.getProductsImportantDataBasedOnCases';
import updatePriceBookList from '@salesforce/apex/CaseImportantInformationController.updatePriceBookList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseImportantInformation extends LightningElement {
    @api recordId;
    @track contactProductHyperLink;
    @track contactHomeCountry;
    @track showSpinner = true;
    @track showError = false;
    @track errorCode;
    @track errorCodePopulated = false;
    @track errorMessage;
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
                this.priceBooks = {};
                this.productWrappers = {};
                productWrappers.forEach(productWrapper => {
                    this.productWrappers[productWrapper.id] = productWrapper;
                    this.columns.push({editable: true, label: productWrapper.name, fieldName: 'priceBookName', actions: [
                        { label: 'All', checked: true, name: 'all' },
                        { label: 'Published', checked: false, name: 'show_published' },
                        { label: 'Unpublished', checked: false, name: 'show_unpublished' },
                    ]});
                    if(Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).includes('Standard')){ //Standard value should always be displayed first
                        this.addCountryCodeColumnToTable('Standard', productWrapper);
                    }

                    Object.keys(productWrapper.contactHomeCountriesToCurrencyIsoCodes).forEach(contactHomeCountry => {
                        if(contactHomeCountry != 'Standard'){
                            this.addCountryCodeColumnToTable(contactHomeCountry, productWrapper);
                        }
                    })
    
                    productWrapper.productPriceBooks.forEach(priceBook => {
                        this.priceBooks[priceBook.id] = priceBook;
                        let priceBookWrapper = {};
                        priceBookWrapper.id = priceBook.id;
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
        try{
            let pricebookWrappers = [];
            let saveDraftValues = event.detail.draftValues;
            saveDraftValues.forEach(pricebook => {
                if(pricebook.id.includes('row')){ //if it is a new row, let's just take the last product
                    if(Object.keys(pricebook).length <= 1){

                    }
                    pricebook.id = null;
                    Object.keys(this.productWrappers).forEach(productId => {
                        this.currentProductWrapper = this.productWrappers[productId];
                    })
                }
                else{
                    this.currentProductWrapper = this.productWrappers[productId];
                }

                let wrapperToPush = {
                    id: pricebook.id
                };

                Object.keys(pricebook).every(fieldName => {
                    switch (fieldName){
                        case 'id':
                            return true;
                        case 'priceBookName':
                            wrapperToPush.name = pricebook.priceBookName;
                            return true;
                        default:
                            let countryCodeToPriceMap = {};
                            countryCodeToPriceMap[fieldName] = parseFloat(pricebook[fieldName]);
                            wrapperToPush.countryCodeToPriceMap = countryCodeToPriceMap;
                            return false;//We only need one currency value, the rest will be converted automatically in the table
                    }
                });

                pricebookWrappers.push(wrapperToPush);
                
            });
    
            updatePriceBookList({
                pricebookWrappersAsJson: JSON.stringify(pricebookWrappers),
                contactHomeCountriesToCurrencyIsoCodes: this.currentProductWrapper.contactHomeCountriesToCurrencyIsoCodes,
                productId: this.currentProductWrapper.id
            }).then(response => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Product price data updated successfully',
                        variant: 'success'
                    })
                )
                location.reload();
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message == null ? error.statusText : error.body.message,
                        variant: 'error'
                    })
                )
                this.draftValues = [];
            });
        }catch(error){
            this.processError(error)
        }
    }

    addRow(){
        this.data.push({});
        this.showSpinner = true;
        this.sleep(1).then(response => {
            this.showSpinner = false;
        });
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    handleChange(event){
        this.value = event.target.value; 
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
                    currencyCode: productWrapper.contactHomeCountriesToCurrencyIsoCodes[contactHomeCountry], step: '0.01'
                }
            }
        }
        this.columns.push(column);
    }
}