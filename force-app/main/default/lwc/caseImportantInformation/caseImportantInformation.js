import { LightningElement, track, api} from 'lwc';
import getContactProductImportantData from '@salesforce/apex/CaseImportantInformationController.getContactProductImportantData';

export default class CaseImportantInformation extends LightningElement {
    @api recordId;
    @track contactProductHyperLink = null;
    @track contactHomeCountry = null;
    @track showSpinner = true;
    @track showError = false;
    @track errorCode = null;
    @track errorMessage = null;

    renderedCallback(){
        this.retreiveData();
    }

    retreiveData(){
        getContactProductImportantData({caseId: this.recordId}).then(productWrapper => {
            this.contactHomeCountry = productWrapper.contactHomeCountry;
            this.contactProductHyperLink = '<a href=' + productWrapper.contactProductUrl + '> ' + productWrapper.contactProductName + '</a>';
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.showError = true;
            this.errorCode = error.status;
            this.errorMessage = error.statusText;
        });
    }
}