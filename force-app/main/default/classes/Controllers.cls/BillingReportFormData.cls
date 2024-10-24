public with sharing class BillingReportFormData {
    public Billing_Report__c BillingReport { get; set; }
    
    public BillingReportFormData() {
        String recordId = ApexPages.currentPage().getParameters().get('id');
        BillingReport = getBillingReport(recordId);
    }

    public Billing_Report__c getBillingReport(String recordId) {
        if (recordId != null) {
            List<Billing_Report__c> records = [SELECT Id, Name, 
                                                      (SELECT  Name,ClientName__c, ClientDate__c 
                                                       FROM Billing_ReportLineItems__r),
                                                      All_claims_submitted_in_one_business_day__c,Dental_Office__c,Dental_Office__r.Name,X100_audit_of_NOS_payment_posting_Y_N__c, Challenges__c, All_payments_posted_in_two_business_days__c, Pending_claims_log_addressed__c, Number_of_appeals_managed__c, Number_of_open_appeals__c, Number_of_OCR_claims_touched_including__c, Number_of_claims_still_requiring_VBS_ass__c, X100_audit_of_NOS_claim_submission_Y_N__c, All_client_questions_addressed__c,Successes__c , Client2Name__c,Client1Name__c,Client2Date__c,Client1Date__c,Requests_for_Support__c
                                                  FROM Billing_Report__c 
                                                  WHERE Id = :recordId LIMIT 1];
            if (records.size() > 0) {
                return records[0];
            }
        }
        return new Billing_Report__c();
    }



    @AuraEnabled
    public static String generatePDF(String recordId) {
        try {
            Billing_Report__c billingReportRecord = [SELECT Id, Name,All_claims_submitted_in_one_business_day__c,Challenges__c,All_payments_posted_in_two_business_days__c,Pending_claims_log_addressed__c,Dental_Office__r.Name,Number_of_appeals_managed__c,Number_of_open_appeals__c,Number_of_OCR_claims_touched_including__c,Number_of_claims_still_requiring_VBS_ass__c,X100_audit_of_NOS_claim_submission_Y_N__c,X100_audit_of_NOS_payment_posting_Y_N__c,All_client_questions_addressed__c,Successes__c,Client2Name__c,Dental_Office__c,Client2Date__c,Client1Date__c, Requests_for_Support__c  FROM Billing_Report__c WHERE Id = :recordId];
            if (billingReportRecord != null) {
                return 'https://elevatebillingsolutions--fozansb--c.sandbox.vf.force.com/apex/BillingReport?id=' + recordId; 
            }
        } catch (Exception e) {
            System.debug('Error fetching Billing Report Record: ' + e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    @future(callout=true)
    public static void sendEmailWithPDF(Id recordId) {
        try {
            // Re-query the updated record to ensure data is current
            Billing_Report__c record = [SELECT Id, Name, X100_audit_of_NOS_claim_submission_Y_N__c,Dental_Office__c, Successes__c, Challenges__c, Number_of_appeals_managed__c, Client2Name__c, Client1Name__c, Client2Date__c, Client1Date__c, X100_audit_of_NOS_payment_posting_Y_N__c 
                                        FROM Billing_Report__c 
                                        WHERE Id = :recordId LIMIT 1];
    
            PageReference pdfPage = Page.BillingReport; // Visualforce page name
            pdfPage.getParameters().put('id', recordId);
            Blob pdfBlob = pdfPage.getContentAsPDF();
    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'compliance@elevatebillingsolutions.com'}; 
            mail.setToAddresses(toAddresses);
            mail.setSubject('Weekly Accountability Report - Billing ' + record.Name);
            mail.setPlainTextBody('Please find the attached PDF for the record.');
    
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Weekly Accountability Report - Billing.pdf');
            attachment.setBody(pdfBlob);
    
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
    
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email sent successfully to ' + toAddresses);

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
}