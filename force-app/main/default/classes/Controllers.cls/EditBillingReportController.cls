public class EditBillingReportController {
    public Billing_Report__c billingReport { get; set; }
    public List<Billing_ReportLineItem__c> lineItems { get; set; }
    
    public EditBillingReportController(ApexPages.StandardController stdController) {
        Id billingReportId = stdController.getId();
        
        billingReport = [SELECT Id, Name,All_claims_submitted_in_one_business_day__c,All_payments_posted_in_two_business_days__c,Pending_claims_log_addressed__c,Number_of_open_appeals__c,All_client_questions_addressed__c,Client2Name__c,Client1Name__c,Client2Date__c,Client1Date__c,
                         Number_of_appeals_managed__c,Dental_Office__c,Dental_Office__r.Name,X100_audit_of_NOS_payment_posting_Y_N__c,Number_of_claims_still_requiring_VBS_ass__c,Number_of_OCR_claims_touched_including__c,X100_audit_of_NOS_claim_submission_Y_N__c,Challenges__c,Successes__c,Requests_for_Support__c
                         FROM Billing_Report__c 
                         WHERE Id = :billingReportId];
        
        lineItems = [SELECT Id,Name, ClientName__c, ClientDate__c
                     FROM Billing_ReportLineItem__c
                     WHERE BillingReportLineItem__c = :billingReport.Id];
    }
    
    public void removeLineItem(Integer index) {
        if (index != null && index < lineItems.size()) {
            lineItems.remove(index);
        }
    }
    public void addLineItem() {
        Billing_ReportLineItem__c newLineItem = new Billing_ReportLineItem__c();
        newLineItem.BillingReportLineItem__c = billingReport.Id; // Associate with the parent billing report
        lineItems.add(newLineItem);
    }
    
    public PageReference save() {
        try {
            update billingReport; 

            if (lineItems != null && !lineItems.isEmpty()) {
                upsert lineItems; 
                        return new PageReference('/' + billingReport.Id);

            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Billing Report and Line Items saved successfully.'));
            return new PageReference('/' + billingReport.Id); 
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving records: ' + e.getMessage()));
            return null;
        }
    }
    public PageReference SaveandSendEmail() {
        try {
            // Update the billing report first
            update billingReport; 
        
            // Upsert line items if they are present
            if (lineItems != null && !lineItems.isEmpty()) {
                upsert lineItems; 
            }
    
            // Now call the future method to send the email
            BillingReportFormData.sendEmailWithPDF(billingReport.Id);
        
            // Add a success message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Billing Report and Line Items saved successfully.'));
        
            // Redirect to the updated billing report
            return new PageReference('/' + billingReport.Id); 
        } catch (Exception e) {
            // Error handling with an error message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving records: ' + e.getMessage()));
            return null;
        }
    }    
    
    public PageReference cancel() {
        return new PageReference('/' + billingReport.Id);
    }
}