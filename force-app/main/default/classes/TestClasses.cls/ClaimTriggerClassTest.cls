@isTest
public class ClaimTriggerClassTest {
    @isTest
    static void testUpdateDueDate() {
        // Step 1: Create a related record for Dental_Office__c
        Account dentalOffice = new Account(Name = 'Test Dental Office');
        insert dentalOffice;

        // Step 2: Create test claims with the valid Id of the Dental_Office__c field
        Claim__c claim1 = new Claim__c(
            Dental_Office__c = dentalOffice.Id, // Use the Id of the Account record
            Patient_Name__c = 'Test12',
            Status__c = 'New',
            Due_Date__c = System.today()
        );
        Claim__c claim2 = new Claim__c(
            Dental_Office__c = dentalOffice.Id,
            Patient_Name__c = 'Test34',
            Status__c = 'Processing',
            Due_Date__c = System.today()
        );
        Claim__c claim3 = new Claim__c(
            Dental_Office__c = dentalOffice.Id,
            Patient_Name__c = 'Test56',
            Status__c = 'Needs Office Assistance',
            Due_Date__c = System.today()
        );
        Claim__c claim4 = new Claim__c(
            Dental_Office__c = dentalOffice.Id,
            Patient_Name__c = 'Test78',
            Status__c = 'Ready for NOS',
            Due_Date__c = System.today()
        );

        // Insert the claims
        insert new List<Claim__c>{ claim1, claim2, claim3, claim4 };

        // Step 3: Simulate status changes
        claim1.Status__c = 'Resubmitted';
        claim2.Status__c = 'Paid but Not Posted';
        claim3.Status__c = 'In Appeals';
        claim4.Status__c = 'Ortho Claim';

        List<Claim__c> newClaims = new List<Claim__c>{ claim1, claim2, claim3, claim4 };
        Map<Id, Claim__c> oldClaims = new Map<Id, Claim__c>();
        for (Claim__c c : [SELECT Id, Status__c FROM Claim__c WHERE Id IN :newClaims]) {
            oldClaims.put(c.Id, c);
        }

        // Step 4: Call the method to test
        Test.startTest();
        ClaimTriggerClass triggerClass = new ClaimTriggerClass();
        triggerClass.updateDueDate(newClaims, oldClaims);
        Test.stopTest();

    }
}