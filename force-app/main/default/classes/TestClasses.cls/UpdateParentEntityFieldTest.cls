@isTest
public class UpdateParentEntityFieldTest {
    // Helper method to setup data for testing
    private static void setupTestData() {
        // Create an Account with a Parent Entity value set
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        // Create a Claim linked to the Account
        Claim__c testClaim = new Claim__c(Dental_Office__c = testAccount.Id ,Patient_Name__c = 'testabcd');
        insert testClaim;
    }

    // Test the trigger on before insert
    @isTest static void testBeforeInsert() {
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        Test.startTest();
        Claim__c newClaim = new Claim__c(Dental_Office__c = testAccount.Id , Patient_Name__c = 'Syed Fozan'  );
        insert newClaim;
        Test.stopTest();

    }

    // Test the trigger on before update
    @isTest static void testBeforeUpdate() {
        setupTestData();
        Account newTestAccount = new Account(Name='New Test Account', Parent_entity__c='Parent Entity 1');
        insert newTestAccount;

        // Get the existing Claim
        Claim__c testClaim = [SELECT Id, Dental_Office__c, Parent_entity__c FROM Claim__c LIMIT 1];

        // Update the Claim to be related to a new Account
        Test.startTest();
        testClaim.Dental_Office__c = newTestAccount.Id;
        update testClaim;
        Test.stopTest();


    }
}


