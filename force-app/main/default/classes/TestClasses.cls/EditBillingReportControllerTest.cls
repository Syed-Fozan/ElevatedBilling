@isTest
public class EditBillingReportControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a Billing Report for testing
               Billing_Report__c report = new Billing_Report__c(
            Name = 'Test Billing Report',
            All_claims_submitted_in_one_business_day__c = 'Yes', 
            X100_audit_of_NOS_payment_posting_Y_N__c = 'Yes',
            Challenges__c = 'Some Challenges',
            All_payments_posted_in_two_business_days__c = 'Yes', 
            Pending_claims_log_addressed__c = 'Yes', 
            Number_of_appeals_managed__c = '10',
            Number_of_open_appeals__c = '5',
            Number_of_OCR_claims_touched_including__c = '20',
            Number_of_claims_still_requiring_VBS_ass__c = '3',
            X100_audit_of_NOS_claim_submission_Y_N__c = 'Yes', 
            All_client_questions_addressed__c = 'Yes', 
            Successes__c = 'Success details',
            Requests_for_Support__c = 'Some requests'
        );
        insert report;

        // Create Billing Report Line Items
        Billing_ReportLineItem__c lineItem1 = new Billing_ReportLineItem__c(
            BillingReportLineItem__c = report.Id,
            ClientName__c = 'Test Client 1',
            ClientDate__c = Date.today()
        );
        Billing_ReportLineItem__c lineItem2 = new Billing_ReportLineItem__c(
            BillingReportLineItem__c = report.Id,
            ClientName__c = 'Test Client 2',
            ClientDate__c = Date.today().addDays(-1)
        );
        insert new List<Billing_ReportLineItem__c>{lineItem1, lineItem2};
    }
    
    @isTest
    static void testControllerMethods() {
        // Retrieve the test Billing Report
        Billing_Report__c billingReport = [SELECT Id FROM Billing_Report__c LIMIT 1];
        
        // Mock StandardController for testing
        ApexPages.StandardController stdController = new ApexPages.StandardController(billingReport);
        
        // Instantiate the controller
        EditBillingReportController controller = new EditBillingReportController(stdController);
        
        // Test initial values
        System.assertNotEquals(null, controller.billingReport, 'Billing report should not be null');
        System.assert(controller.lineItems.size() > 0, 'Line items should be present initially');
        
        // Test removeLineItem method
        Integer initialSize = controller.lineItems.size();
        controller.removeLineItem(0);
        System.assertEquals(initialSize - 1, controller.lineItems.size(), 'Line item should be removed');
        
        // Test addLineItem method
        controller.addLineItem();
        System.assertEquals(initialSize, controller.lineItems.size(), 'New line item should be added');
        
        // Test save method
        Test.startTest();
        PageReference result = controller.save();
        Test.stopTest();
        
        System.assertEquals('/' + billingReport.Id, result.getUrl(), 'Save should redirect to billing report page');
    }
    
    
    
    
    @isTest
    static void testCancelMethod() {
        // Retrieve the test Billing Report
        Billing_Report__c billingReport = [SELECT Id FROM Billing_Report__c LIMIT 1];
        
        // Mock StandardController for testing
        ApexPages.StandardController stdController = new ApexPages.StandardController(billingReport);
        
        // Instantiate the controller
        EditBillingReportController controller = new EditBillingReportController(stdController);
        
        // Test cancel method
        PageReference result = controller.cancel();
        System.assertEquals('/' + billingReport.Id, result.getUrl(), 'Cancel should redirect to billing report page');
    }
}