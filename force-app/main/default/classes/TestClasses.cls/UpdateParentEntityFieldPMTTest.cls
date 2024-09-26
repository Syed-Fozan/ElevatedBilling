@isTest
public class UpdateParentEntityFieldPMTTest {
    private static void setupTestData() {
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        PMT__c testPMt = new PMT__c(Account__c = testAccount.Id );
        insert testPMt;
    }

    @isTest static void testBeforeInsert() {
        Account testAccount = new Account(Name='Test Account', Parent_entity__c='Parent Entity 1');
        insert testAccount;

        Test.startTest();
        PMT__c newPMT = new PMT__c(Account__c = testAccount.Id   );
        insert newPMT;
        Test.stopTest();

    }

    @isTest static void testBeforeUpdate() {
        setupTestData();
        Account newTestAccount = new Account(Name='New Test Account', Parent_entity__c='Parent Entity 1');
        insert newTestAccount;

        PMT__c testPMT = [SELECT Id, Account__c, Parent_entity__c FROM PMT__c LIMIT 1];

        Test.startTest();
        testPMT.Account__c = newTestAccount.Id;
        update testPMT;
        Test.stopTest();


    }
}