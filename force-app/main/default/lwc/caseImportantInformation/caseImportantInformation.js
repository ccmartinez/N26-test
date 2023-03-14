import { LightningElement, track, api} from 'lwc';
import getContactProductImportantData from '@salesforce/apex/CaseImportantInformationController.getContactProductImportantData';

const columns = [
    { label: 'Contact Product', fieldName: 'contactProduct'},
    { label: 'Contact Home Country', fieldName: 'contactHomeCountry'}
];

const data = [
    {
        id: 'a',
        contactProduct: 'Test Product',
        contactHomeCountry: 'Home Country'
    }
];
export default class CaseImportantInformation extends LightningElement {
    data = data;
    columns = columns;
    @api
    recordId;
    @track
    contactProduct = null;
    @track
    contactHomeCountry = null;

    renderedCallback(){
        this.retreiveData();
    }

    retreiveData(){
        let globalContext = this;
        getContactProductImportantData({caseId: this.recordId}).then(productWrapper => {
            globalContext.contactProduct = productWrapper.contactProduct;
            globalContext.contactHomeCountry = productWrapper.contactHomeCountry;
        }).catch(error => {
            console.log(error);
        });
    }
}