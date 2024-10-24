@isTest
public class CalculatePmtSumOnBillingReportTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Accounts (Dental Offices)
        Account acc1 = new Account(Name = 'Dental Office 1');
        Account acc2 = new Account(Name = 'Dental Office 2');
        insert new List<Account>{acc1, acc2};
        
        // Create test pmt__c records for both Accounts
        pmt__c pmt1 = new pmt__c(Account__c = acc1.Id, Claims_Appealed__c = 5, EBS_Claims_Appealed__c = 3, Outstanding_Claims_Worked__c = 4, EBS_Outstanding_Claims_Worked__c = 2);
        pmt__c pmt2 = new pmt__c(Account__c = acc2.Id, Claims_Appealed__c = 6, EBS_Claims_Appealed__c = 4, Outstanding_Claims_Worked__c = 5, EBS_Outstanding_Claims_Worked__c = 3);
        insert new List<pmt__c>{pmt1, pmt2};
        
        // Create test Claim__c records for both Dental Offices
        Claim__c claim1 = new Claim__c(Patient_Name__c = 'Dental Office 1',Dental_Office__c = acc1.Id, Status__c = 'Needs VBS Assistance');
        Claim__c claim2 = new Claim__c(Patient_Name__c = 'Dental Office 2',Dental_Office__c = acc2.Id, Status__c = 'New');
        Claim__c claim3 = new Claim__c(Patient_Name__c = 'Dental Office 3',Dental_Office__c = acc2.Id, Status__c = 'Needs VBS Assistance');
        insert new List<Claim__c>{claim1, claim2, claim3};
    }
    
    @isTest
    static void testCalculatePmtSumOnBillingReport() {
        // Create Billing_Report__c records
        Billing_Report__c report1 = new Billing_Report__c(Dental_Office__c = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1].Id);
        Billing_Report__c report2 = new Billing_Report__c(Dental_Office__c = [SELECT Id FROM Account WHERE Name = 'Dental Office 2' LIMIT 1].Id, Dental_Office_2__c = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1].Id);
        
        Test.startTest();
        // Insert Billing_Report__c records to fire the trigger
        insert new List<Billing_Report__c>{report1, report2};
        Test.stopTest();
        
        // Retrieve updated Billing_Report__c records
        Billing_Report__c updatedReport1 = [SELECT Number_of_appeals_managed__c, Number_of_open_appeals__c, Number_of_claims_still_requiring_VBS_ass__c, Number_of_OCR_claims_touched_including__c 
                                            FROM Billing_Report__c WHERE Id = :report1.Id];
        Billing_Report__c updatedReport2 = [SELECT Number_of_appeals_managed__c, Number_of_open_appeals__c, Number_of_claims_still_requiring_VBS_ass__c, Number_of_OCR_claims_touched_including__c 
                                            FROM Billing_Report__c WHERE Id = :report2.Id];
        
        // Assert the values are correctly updated
 System.assertEquals('8', updatedReport1.Number_of_appeals_managed__c); // Sum of Claims_Appealed and EBS_Claims_Appealed
        System.assertEquals('2', updatedReport1.Number_of_claims_still_requiring_VBS_ass__c); // VBS Assistance count
        System.assertEquals('6', updatedReport1.Number_of_OCR_claims_touched_including__c); // Sum of Outstanding Claims Worked

        System.assertEquals('18', updatedReport2.Number_of_appeals_managed__c); // Sum of Claims_Appealed for both Dental Offices
        System.assertEquals('2', updatedReport2.Number_of_claims_still_requiring_VBS_ass__c); // VBS Assistance count
        System.assertEquals('14', updatedReport2.Number_of_OCR_claims_touched_including__c); // Sum of Outstanding Claims Worked for both Dental Offices

    }
}