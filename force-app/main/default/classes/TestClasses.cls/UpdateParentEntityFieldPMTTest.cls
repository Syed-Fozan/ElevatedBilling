@isTest
public class UpdateParentEntityFieldPMTTest {
   // Helper method to setup data for testing
    private static void setupTestData() {
        // Create an Account with a Parent Entity value set
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        // Create a Claim linked to the Account
        PMT__c testPMt = new PMT__c(Account__c = testAccount.Id );
        insert testPMt;
    }

    // Test the trigger on before insert
    @isTest static void testBeforeInsert() {
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        Test.startTest();
        PMT__c newPMT = new PMT__c(Account__c = testAccount.Id   );
        insert newPMT;
        Test.stopTest();

    }

    // Test the trigger on before update
    @isTest static void testBeforeUpdate() {
        setupTestData();
        Account newTestAccount = new Account(Name='New Test Account', Parent_entity__c='Parent Entity 1');
        insert newTestAccount;

        // Get the existing Claim
        PMT__c testPMT = [SELECT Id, Account__c, Parent_entity__c FROM PMT__c LIMIT 1];

        // Update the Claim to be related to a new Account
        Test.startTest();
        testPMT.Account__c = newTestAccount.Id;
        update testPMT;
        Test.stopTest();


    }
}