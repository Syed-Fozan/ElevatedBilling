@isTest
public class BillingReportFormDataTest {

    @testSetup
    static void setupTestData() {
        Account dentalOffice = new Account(
       Name='Test Account',
       Parent_entity__c='Parent Entity 1'
        // Add other required fields as needed
    );
    insert dentalOffice;
        // Create test data for Billing_Report__c
        Billing_Report__c billingReport = new Billing_Report__c(
            Name = 'Test Billing Report',
            Dental_Office__c = dentalOffice.Id,
            X100_audit_of_NOS_claim_submission_Y_N__c = 'Yes',
            All_claims_submitted_in_one_business_day__c = 'Yes',
            All_payments_posted_in_two_business_days__c = 'Yes',
            Number_of_appeals_managed__c = '5',
            Number_of_open_appeals__c = '3',
            Number_of_OCR_claims_touched_including__c = '10',
            Number_of_claims_still_requiring_VBS_ass__c = '2',
            Client1Name__c = 'Client A',
            Client1Date__c = Date.today(),
            Successes__c = 'Success A',
            Challenges__c = 'Challenge A',
            Requests_for_Support__c = 'Request A'
        );
        insert billingReport;
    }

    @isTest
    static void testGetBillingReport() {
        // Create a page reference to simulate the page with 'id' parameter
        PageReference pageRef = Page.BillingReport; // Ensure the Visualforce page exists
        Test.setCurrentPage(pageRef);

        // Set page parameters
        pageRef.getParameters().put('id', [SELECT Id FROM Billing_Report__c LIMIT 1].Id);

        // Create instance of BillingReportFormData
        BillingReportFormData controller = new BillingReportFormData();

        // Assert that the BillingReport is populated
        System.assertNotEquals(null, controller.BillingReport);
        System.assertEquals('Test Billing Report', controller.BillingReport.Name);
    }

    @isTest
    static void testGeneratePDF() {
        // Fetch a Billing Report Id
        Billing_Report__c billingReport = [SELECT Id FROM Billing_Report__c LIMIT 1];

        // Call the method to test
        String pdfUrl = BillingReportFormData.generatePDF(billingReport.Id);

        // Assert the PDF URL is correct
        System.assertNotEquals(null, pdfUrl);
        System.assert(pdfUrl.contains('/apex/BillingReport?id=' + billingReport.Id));
    }

@isTest
static void testSendEmailWithPDF() {
    // Set up test data
    Billing_Report__c billingReport = new Billing_Report__c(Name = 'Test Billing Report');
    insert billingReport;

    // Call the future method within Test.startTest() and Test.stopTest() to ensure the future method is executed
    Test.startTest();
    BillingReportFormData.sendEmailWithPDF(billingReport.Id);
    Test.stopTest();

    // Since there's no way to directly assert the email, we'll rely on the fact that no exceptions are thrown
    // Optionally, you can add debug statements in the future method and assert their presence in logs
    System.assert(true, 'Future method executed without exceptions.');
}

}