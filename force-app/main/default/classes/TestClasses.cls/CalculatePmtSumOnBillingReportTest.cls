@isTest
public class CalculatePmtSumOnBillingReportTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Accounts (Dental Offices)
        Account acc1 = new Account(Name = 'Dental Office 1');
        Account acc2 = new Account(Name = 'Dental Office 2');
        insert new List<Account>{acc1, acc2};
        
        // Create test pmt__c records
        pmt__c pmt1 = new pmt__c(Account__c = acc1.Id, Claims_Appealed__c = 5, EBS_Claims_Appealed__c = 3, Outstanding_Claims_Worked__c = 4, EBS_Outstanding_Claims_Worked__c = 2);
        pmt__c pmt2 = new pmt__c(Account__c = acc2.Id, Claims_Appealed__c = 6, EBS_Claims_Appealed__c = 4, Outstanding_Claims_Worked__c = 5, EBS_Outstanding_Claims_Worked__c = 3);
        insert new List<pmt__c>{pmt1, pmt2};
        
        // Create test Claim__c records
        Claim__c claim1 = new Claim__c(Patient_Name__c = 'Dental Office 1', Dental_Office__c = acc1.Id, Status__c = 'Needs VBS Assistance');
        Claim__c claim2 = new Claim__c(Patient_Name__c = 'Dental Office 2', Dental_Office__c = acc2.Id, Status__c = 'In Appeals');
        Claim__c claim3 = new Claim__c(Patient_Name__c = 'Dental Office 2', Dental_Office__c = acc2.Id, Status__c = 'Needs VBS Assistance');
        insert new List<Claim__c>{claim1, claim2, claim3};
    }
    
    @isTest
    static void testInsertTrigger() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Dental Office 2' LIMIT 1];

        Billing_Report__c report1 = new Billing_Report__c(Dental_Office__c = acc1.Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));
        Billing_Report__c report2 = new Billing_Report__c(Dental_Office__c = acc2.Id, Dental_Office_2__c = acc1.Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));

        Test.startTest();
        insert new List<Billing_Report__c>{report1, report2};
        Test.stopTest();
        
        // Retrieve updated Billing_Report__c records
        Billing_Report__c updatedReport1 = [SELECT Number_of_appeals_managed__c, Number_of_claims_still_requiring_VBS_ass__c, Number_of_OCR_claims_touched_including__c FROM Billing_Report__c WHERE Id = :report1.Id];
        Billing_Report__c updatedReport2 = [SELECT Number_of_appeals_managed__c, Number_of_claims_still_requiring_VBS_ass__c, Number_of_OCR_claims_touched_including__c FROM Billing_Report__c WHERE Id = :report2.Id];

        System.assertEquals('0', updatedReport1.Number_of_appeals_managed__c);
        System.assertEquals('2', updatedReport1.Number_of_claims_still_requiring_VBS_ass__c);
        System.assertEquals('0', updatedReport1.Number_of_OCR_claims_touched_including__c);

        System.assertEquals('0', updatedReport2.Number_of_appeals_managed__c);
        System.assertEquals('2', updatedReport2.Number_of_claims_still_requiring_VBS_ass__c);
        System.assertEquals('0', updatedReport2.Number_of_OCR_claims_touched_including__c);
    }

    @isTest
    static void testUpdateTrigger() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1];
        Billing_Report__c report = new Billing_Report__c(Dental_Office__c = acc1.Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));
        insert report;
        
        report.To_Date__c = Date.newInstance(2025, 2, 3);
        Test.startTest();
        update report;
        Test.stopTest();
        
        Billing_Report__c updatedReport = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Id = :report.Id];
        System.assert(updatedReport.Number_of_appeals_managed__c != null);
    }
    
    @isTest
    static void testNoImpactTrigger() {
        Billing_Report__c report = new Billing_Report__c(From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));
        Test.startTest();
        insert report;
        Test.stopTest();
        Billing_Report__c updatedReport = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Id = :report.Id];
        System.assertEquals(null, updatedReport.Number_of_appeals_managed__c);
    }


   @isTest
    static  void testBillingReportTrigger() {
        Test.startTest();
        
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Claims with different statuses
        PMT__c claim1 = new PMT__c(Account__c = acc.Id, Outstanding_Claims_Worked__c = 3);
        PMT__c claim2 = new PMT__c(Account__c = acc.Id, EBS_Outstanding_Claims_Worked__c = 2);
        insert new List<PMT__c>{ claim1, claim2 };

        // Insert Billing Report to trigger calculations
        Billing_Report__c report = new Billing_Report__c(Dental_Office__c = acc.Id,From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));
        insert report;

        // Retrieve and verify updated values
        Billing_Report__c updatedReport = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Dental_Office__c = :acc.Id LIMIT 1];
        System.assertEquals(null, updatedReport.Number_of_appeals_managed__c, 'Total claims count incorrect.');

        Test.stopTest();
    }

   @isTest
    static void testOCRClaimsAggregation() {
        Test.startTest();

        // Perform SOQL Aggregation to simulate real AggregateResult
        List<AggregateResult> OCRclaimstouched = [
            SELECT Account__c, 
                   SUM(Outstanding_Claims_Worked__c) Outstanding_Claims_Worked__c, 
                   SUM(EBS_Outstanding_Claims_Worked__c) EBS_Outstanding_Claims_Worked__c 
            FROM PMT__c 
            GROUP BY Account__c
        ];

        // Map to store results
        Map<Id, Integer> StatusNoteMap = new Map<Id, Integer>();

        for (AggregateResult result : OCRclaimstouched) {
            Id accountId = (Id) result.get('Account__c');
            
            Integer NOSOutstandingClaimsWorked = (result.get('Outstanding_Claims_Worked__c') != null) ? 
                ((Decimal) result.get('Outstanding_Claims_Worked__c')).intValue() : 0;
            
            Integer EBSOutstandingClaimsWorked = (result.get('EBS_Outstanding_Claims_Worked__c') != null) ? 
                ((Decimal) result.get('EBS_Outstanding_Claims_Worked__c')).intValue() : 0;

            Integer TotalOutstandingClaimsWorked = EBSOutstandingClaimsWorked + NOSOutstandingClaimsWorked;
            StatusNoteMap.put(accountId, TotalOutstandingClaimsWorked);
        }

        // Validate Results
        Account acc = [SELECT Id FROM Account LIMIT 1];
        System.assertEquals(6, StatusNoteMap.get(acc.Id), 'Total outstanding claims worked is incorrect.');

        Test.stopTest();
    }

    @isTest
    static void testMixedData() {
        // Retrieve the existing Account
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1];

        // Create a unique Account name for acc2 to avoid duplicate rules
        String uniqueName = 'Dental Office 5 - ' + System.now().getTime();
        Account acc2 = new Account(Name = uniqueName);
        insert acc2;

        // Create Billing_Report__c records
        Billing_Report__c report1 = new Billing_Report__c(
            Dental_Office__c = acc1.Id, 
            From_Date__c = Date.newInstance(2025, 2, 1), 
            To_Date__c = Date.newInstance(2025, 2, 3)
        );
        Billing_Report__c report2 = new Billing_Report__c(
            Dental_Office__c = acc2.Id, 
            From_Date__c = null, 
            To_Date__c = Date.newInstance(2025, 2, 3)
        );

        // Test the insertion of Billing_Report__c records
        Test.startTest();
        try {
            insert new List<Billing_Report__c>{report1, report2};
        } catch (Exception e) {
            // Verify that the exception is due to a validation error (e.g., required field missing)
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Expected validation exception.');
        }
        Test.stopTest();

        // Verify that report1 was successfully inserted and has the expected data
        Billing_Report__c updatedReport1 = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Id = :report1.Id];
        System.assert(updatedReport1.Number_of_appeals_managed__c != null, 'Report 1 should have appeals managed count.');
    }

    @isTest
    static void testDateRange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1];

        Billing_Report__c report = new Billing_Report__c(Dental_Office__c = acc.Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));

        Test.startTest();
        insert report;
        report.From_Date__c = Date.newInstance(2025, 2, 2);
        update report;
        Test.stopTest();

        Billing_Report__c updatedReport = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Id = :report.Id];
        System.assert(updatedReport.Number_of_appeals_managed__c != null, 'Report should have appeals managed count.');
    }

        @isTest
    static void testBulkInsertTrigger() {
        List<Billing_Report__c> reports = new List<Billing_Report__c>();
        for (Integer i = 0; i < 10; i++) {
            reports.add(new Billing_Report__c(Dental_Office__c = [SELECT Id FROM Account LIMIT 1].Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3)));
        }
        Test.startTest();
        insert reports;
        Test.stopTest();
        System.assertEquals(10, [SELECT COUNT() FROM Billing_Report__c]);
    }

  @isTest
static void testLargeDataVolume() {
    // Create a unique Account name
    String uniqueName = 'Dental Office 7 - ' + System.now().getTime();
    Account acc = new Account(Name = uniqueName);
    insert acc;

    // Create a list of Billing_Report__c records
    List<Billing_Report__c> reports = new List<Billing_Report__c>();
    for (Integer i = 0; i < 1000; i++) {
        reports.add(new Billing_Report__c(Dental_Office__c = acc.Id, From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3)));
    }

    // Insert the reports
    Test.startTest();
    insert reports;
    Test.stopTest();

    // Verify the number of inserted reports
    List<Billing_Report__c> insertedReports = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Dental_Office__c = :acc.Id];
    System.assertEquals(1000, insertedReports.size(), 'All reports should be inserted.');
}

    
    @isTest
    static void testUpdateTriggerWithChanges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Dental Office 1' LIMIT 1];
        Billing_Report__c report = new Billing_Report__c(Dental_Office__c = acc.Id,From_Date__c = Date.newInstance(2025, 2, 1), To_Date__c = Date.newInstance(2025, 2, 3));
        insert report;
        
        report.To_Date__c = Date.newInstance(2025, 2, 3);
        Test.startTest();
        update report;
        Test.stopTest();
        
        Billing_Report__c updatedReport = [SELECT Number_of_appeals_managed__c FROM Billing_Report__c WHERE Id = :report.Id];
        System.assert(updatedReport.Number_of_appeals_managed__c != null);
    }
    
    @isTest
    static void testNullValuesHandling() {
        Billing_Report__c report = new Billing_Report__c();
        Test.startTest();
        insert report;
        Test.stopTest();
        Billing_Report__c insertedReport = [SELECT Id FROM Billing_Report__c WHERE Id = :report.Id];
        System.assert(insertedReport != null, 'Record with null values should still be inserted.');
    }
    
    

    
}