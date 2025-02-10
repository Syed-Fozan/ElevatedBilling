import { LightningElement, api } from 'lwc';
import getInsuranceVerification from '@salesforce/apex/InsuranceVerificationController.getInsuranceVerification';
import saveRecord from '@salesforce/apex/InsuranceVerificationController.saveRecord';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class InsuranceVerification extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        this.loadInsuranceVerification();
    }

    loadInsuranceVerification() {
        getInsuranceVerification({
             insuranceVerificationId:this.recordId 
        })
        
         
    }

    handleSuccess() {
        this.showToast('Success', 'Insurance Verification saved successfully!', 'success');
    }

    handleError(error) {
        this.showToast('Error', error.body.message, 'error');
    }

    handleDownload(event) {
        event.preventDefault();
        const fields = this.template.querySelectorAll('lightning-input-field');

        console.log('Record saved with ID:', fields);
        debugger;
        // Check if the form is valid before saving
        if (form && form.reportValidity()) {
            // Save the record
            form.submit();

            saveRecord({ record: form.fields })
                .then((recordId) => {
                    console.log('Record saved with ID:', recordId);

                    // Open the VF page for PDF download
                    const downloadUrl = `/apex/PDFPage?id=${recordId}`;
                    window.open(downloadUrl, '_blank');
                })
                .catch((error) => {
                    console.error('Error saving record:', error);
                });
        }
    }


    handleCancel() {
        // Navigate to the record page or another desired URL
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                
                objectApiName: 'Insurance_Verification__c', // Change to your object API name
                actionName: 'list'
            }
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}