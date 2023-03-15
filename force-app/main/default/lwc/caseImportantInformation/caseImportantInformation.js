import { LightningElement, track, api} from 'lwc';
import getContactProductsImportantData from '@salesforce/apex/CaseImportantInformationController.getContactProductsImportantData';

const columns = [
    { label: 'Contact Product', fieldName: 'contactProduct'},
    { label: 'Contact Home Country', fieldName: 'contactHomeCountry'}
];

const data = [];

export default class CaseImportantInformation extends LightningElement {
    @api recordId;
    @track contactProductHyperLink = null;
    @track contactHomeCountry = null;
    @track showSpinner = true;
    @track showError = false;
    @track errorCode = null;
    @track errorCodePopulated = false;
    @track errorMessage = null;

    setErrorCode(val){
        this.errorCodePopulated = true;
        this.errorCode = val;
    }

    renderedCallback(){
        this.retreiveData();
    }

    retreiveData(){
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