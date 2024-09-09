import { LightningElement, track } from 'lwc';
import getPersonAccount from '@salesforce/apex/GuestPersonAccountController.getPersonAccount';
import updatePersonAccount from '@salesforce/apex/GuestPersonAccountController.updatePersonAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GuestPersonAccountForm extends LightningElement {
    @track personAccount = {};
    @track isLoading = true;
    @track errorMessage = '';
    @track formSubmitted = false; // New state to hide form after successful save
    token = ''; // This will be retrieved from the URL

    // T-shirt size options
    tshirtSizeOptions = [
        { label: 'XS', value: 'XS' },
        { label: 'S', value: 'S' },
        { label: 'M', value: 'M' },
        { label: 'L', value: 'L' },
        { label: 'XL', value: 'XL' },
        { label: 'XXL', value: 'XXL' }
    ];

    // Shoe size options
    shoeSizeOptions = [
        { label: '6.0', value: '6.0' },
        { label: '6.5', value: '6.5' },
        { label: '7.0', value: '7.0' },
        { label: '7.5', value: '7.5' },
        { label: '8.0', value: '8.0' },
        { label: '8.5', value: '8.5' },
        { label: '9.0', value: '9.0' },
        { label: '9.5', value: '9.5' },
        { label: '10.0', value: '10.0' },
        { label: '10.5', value: '10.5' },
        { label: '11.0', value: '11.0' },
        { label: '11.5', value: '11.5' },
        { label: '12.0', value: '12.0' },
        { label: '12.5', value: '12.5' },
        { label: '13.0', value: '13.0' },
        { label: '13.5', value: '13.5' },
        { label: '14.0', value: '14.0' },
        { label: '14.5', value: '14.5' },
        { label: '15.0', value: '15.0' },
        { label: '15.5', value: '15.5' },
        { label: '16.0', value: '16.0' }
    ];

    connectedCallback() {
        // Retrieve token from URL
        const urlParams = new URLSearchParams(window.location.search);
        this.token = urlParams.get('token');
        console.log('Token retrieved from URL: ', this.token);

        if (this.token) {
            this.fetchPersonAccount();
        } else {
            this.isLoading = false;
            this.errorMessage = 'No token provided.';
        }
    }

    // Fetch Person Account data from Apex imperatively
    fetchPersonAccount() {
        this.isLoading = true;
        console.log('Fetching person account with token:', this.token);

        getPersonAccount({ token: this.token })
            .then(result => {
                this.personAccount = result;
                console.log('Person Account fetched successfully:', JSON.stringify(this.personAccount));
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching person account:', JSON.stringify(error));
                this.errorMessage = 'Error fetching person account: ' + error.body.message;
                this.isLoading = false;
            });
    }

    // Handle input changes and store them in the personAccount object
    handleInputChange(event) {
        const field = event.target.name;
        this.personAccount[field] = event.target.value;
        console.log('Field updated:', field, 'New Value:', this.personAccount[field]);
    }

    // Validate required fields before saving
    validateFields() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        return allValid;
    }

    // Handle form submission to update the record
    handleSave() {
        if (!this.validateFields()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill out all required fields.',
                    variant: 'error',
                })
            );
            return; // Stop execution if fields are invalid
        }

        this.isLoading = true;
        console.log('Saving person account:', JSON.stringify(this.personAccount));

        updatePersonAccount({ updatedAccount: this.personAccount })
            .then(() => {
                console.log('Person account updated successfully.');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Person account updated successfully.',
                        variant: 'success',
                    })
                );
                this.isLoading = false;
                this.formSubmitted = true; // Hide the form after successful save
            })
            .catch(error => {
                console.error('Error updating person account:', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating person account: ' + error.body.message,
                        variant: 'error',
                    })
                );
                this.isLoading = false;
            });
    }
}