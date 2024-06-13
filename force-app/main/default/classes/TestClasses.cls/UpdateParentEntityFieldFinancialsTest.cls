@isTest
public class UpdateParentEntityFieldFinancialsTest {
    // Helper method to set up initial test data
    private static void setupTestData() {
        // Create an Account with a Parent Entity value set
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        // Create a financial record linked to the Account
        A_R__c testFinancials = new A_R__c(Dental_Office__c = testAccount.Id);
        insert testFinancials;
    }

    // Test the trigger on before insert
    @isTest static void testBeforeInsert() {
        // Insert a new Account to use in the test
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        // Start test to limit scope for Governor Limits
        Test.startTest();
        // Insert a new A_R__c record to trigger the logic
        A_R__c newFinancials = new A_R__c(Dental_Office__c = testAccount.Id);
        insert newFinancials;
        Test.stopTest();
    }

    // Test the trigger on before update
    @isTest static void testBeforeUpdate() {
        // Set up initial data
        setupTestData();
        // Create a new account with a different Parent Entity value
        Account newTestAccount = new Account(Name='New Test Account', Parent_entity__c='Parent Entity 1');
        insert newTestAccount;

        // Get the existing financial record
        A_R__c testFinancials = [SELECT Id, Dental_Office__c FROM A_R__c LIMIT 1];

        // Update the financial record to relate to the new Account
        Test.startTest();
        testFinancials.Dental_Office__c = newTestAccount.Id;
        update testFinancials;
        Test.stopTest();

    }
}