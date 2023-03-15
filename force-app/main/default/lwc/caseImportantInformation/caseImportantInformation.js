import { LightningElement, track, api} from 'lwc';
import getContactProductImportantData from '@salesforce/apex/CaseImportantInformationController.getContactProductImportantData';

export default class CaseImportantInformation extends LightningElement {
    @api recordId;
    @track contactProductHyperLink = null;
    @track contactHomeCountry = null;
    @track showSpinner = true;

    renderedCallback(){
        this.retreiveData();
    }

    retreiveData(){
        let globalContext = this;
        getContactProductImportantData({caseId: this.recordId}).then(productWrapper => {
            globalContext.contactHomeCountry = productWrapper.contactHomeCountry;
            globalContext.contactProductHyperLink = '<a href=' + productWrapper.contactProductUrl + '> ' + productWrapper.contactProductName + '</a>';
            globalContext.showSpinner = false;
        }).catch(error => {
            console.log(error);
            globalContext.showSpinner = false;
        });
    }
}