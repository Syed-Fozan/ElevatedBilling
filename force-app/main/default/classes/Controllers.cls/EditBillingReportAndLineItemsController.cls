public class EditBillingReportAndLineItemsController {
    public Billing_Report__c billingReport { get; set; }
    public List<Billing_ReportLineItem__c> lineItems { get; set; }
    
    public EditBillingReportAndLineItemsController(ApexPages.StandardController stdController) {
        // Retrieve the record ID from the standard controller
        Id billingReportId = stdController.getId();
        
        // Query the necessary fields from Billing_Report__c object
        billingReport = [SELECT Id, Name,All_claims_submitted_in_one_business_day__c,All_payments_posted_in_two_business_days__c,Pending_claims_log_addressed__c,Number_of_open_appeals__c,All_client_questions_addressed__c,
                         Number_of_appeals_managed__c,X100_audit_of_NOS_payment_posting_Y_N__c,Number_of_claims_still_requiring_VBS_ass__c,Number_of_OCR_claims_touched_including__c,X100_audit_of_NOS_claim_submission_Y_N__c,Challenges__c,Successes__c,Requests_for_Support__c
                         FROM Billing_Report__c 
                         WHERE Id = :billingReportId];
        
        // Query the related line items
        lineItems = [SELECT Id,Name, ClientName__c, ClientDate__c
                     FROM Billing_ReportLineItem__c
                     WHERE BillingReportLineItem__c = :billingReport.Id];
    }
    
    public void removeLineItem(Integer index) {
        if (index != null && index < lineItems.size()) {
            lineItems.remove(index);
        }
    }
    // Method to add a new line item
    public void addLineItem() {
        Billing_ReportLineItem__c newLineItem = new Billing_ReportLineItem__c();
        newLineItem.BillingReportLineItem__c = billingReport.Id; // Associate with the parent billing report
        lineItems.add(newLineItem);
    }
    
    // Save method to update both the Billing Report and its Line Items
    public PageReference save() {
        try {
            update billingReport; // Save the billing report
            
            // Save line items only if there are any
            if (lineItems != null && !lineItems.isEmpty()) {
                upsert lineItems; // Use upsert to insert new items and update existing ones
                        return new PageReference('/' + billingReport.Id);

            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Billing Report and Line Items saved successfully.'));
            return ApexPages.currentPage(); // Refreshes the page
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving records: ' + e.getMessage()));
            return null;
        }
    }

    // Cancel method to go back to the original record page
    public PageReference cancel() {
        return new PageReference('/' + billingReport.Id);
    }
}