@isTest
public class DuplicateClaimsTest {

    @isTest
    static void testDuplicateClaimsTrigger() {
        // Create mock Dental Office and Insurance Carrier records
        Account dentalOfficeA = new Account(Name = 'Dental Office A');
        Account dentalOfficeB = new Account(Name = 'Dental Office B');
        insert new List<Account> { dentalOfficeA, dentalOfficeB };

        // Step 1: Create existing claims in the system
        Claim__c existingClaim1 = new Claim__c(
            Patient_Name__c = 'John Doe',
            Claim_Amount__c = 100.0,
            Date_of_Service__c = Date.newInstance(2023, 6, 15),
            Subscriber_ID__c = '12345',
            Insurance_Carrier__c = 'AETNA/100/80/50 ',
            Dental_Office__c = dentalOfficeA.Id,
            Patient_DOB__c = Date.newInstance(1990, 1, 1),
            Status__c = 'Completed',
            Claim_Completed__c = false
        );
        
        Claim__c existingClaim2 = new Claim__c(
            Patient_Name__c = 'Jane Doe',
            Claim_Amount__c = 200.0,
            Date_of_Service__c = Date.newInstance(2023, 6, 20),
            Subscriber_ID__c = '67890',
            Insurance_Carrier__c = 'AETNA/100/80/50' ,
            Dental_Office__c = dentalOfficeB.Id,
            Patient_DOB__c = Date.newInstance(1992, 2, 2),
            Status__c = 'New',
            Claim_Completed__c = false
        );
        
        insert new List<Claim__c> { existingClaim1, existingClaim2 };
        
        // Step 2: Insert new claims to trigger the DuplicateClaims trigger
        Claim__c newClaim1 = new Claim__c(
            Patient_Name__c = 'John Doe',
            Claim_Amount__c = 100.0,
            Date_of_Service__c = Date.newInstance(2023, 6, 15),
            Subscriber_ID__c = '12345',
            Insurance_Carrier__c = 'AETNA/100/80/50 ',
            Dental_Office__c = dentalOfficeA.Id,
            Patient_DOB__c = Date.newInstance(1990, 1, 1)
        );
        
        Claim__c newClaim2 = new Claim__c(
            Patient_Name__c = 'Alice Doe',
            Claim_Amount__c = 300.0,
            Date_of_Service__c = Date.newInstance(2023, 7, 10),
            Subscriber_ID__c = '54321',
            Insurance_Carrier__c = 'AETNA/100/80/50 ',
            Dental_Office__c = dentalOfficeB.Id,
            Patient_DOB__c = Date.newInstance(1993, 3, 3)
        );
        
        insert new List<Claim__c> { newClaim1, newClaim2 };
        
        // Step 3: Query all claims to verify trigger results
        List<Claim__c> updatedClaims = [
            SELECT Id, Status__c
            FROM Claim__c
            WHERE Id IN :new List<Id> { existingClaim1.Id, existingClaim2.Id }
        ];
        
        // Assertions to check the status updates
        for (Claim__c claim : updatedClaims) {
            if (claim.Id == existingClaim1.Id) {
                System.assertEquals('New', claim.Status__c, 'Status should be updated to New for existing claim 1');
            } else if (claim.Id == existingClaim2.Id) {
                System.assertEquals('Completed', claim.Status__c, 'Status should be updated to Completed for existing claim 2');
            }
        }
        
        // Query to check if new claims are inserted correctly
        List<Claim__c> insertedNewClaims = [
            SELECT Id, Patient_Name__c, Claim_Amount__c, Date_of_Service__c, Subscriber_ID__c, Insurance_Carrier__c, Dental_Office__c, Patient_DOB__c
            FROM Claim__c
            WHERE Id IN :new List<Id> { newClaim1.Id, newClaim2.Id }
        ];
        
        System.assertEquals(2, insertedNewClaims.size(), 'Two new claims should be inserted');
    }
}