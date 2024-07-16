trigger DuplicateClaims on Claim__c (after insert) {
    // List to collect claims where status needs to be updated
    List<Claim__c> claimsToUpdate = new List<Claim__c>();

    // Set to collect unique keys for new claims for reference
    Set<String> newClaimKeys = new Set<String>();

    // Map to collect existing claims from Salesforce
    Map<String, Claim__c> existingClaimsMap = new Map<String, Claim__c>();
    
    // Get the dental offices for the new claims
    Set<Id> dentalOfficesForNewClaims = new Set<Id>();
    for (Claim__c newClaim : Trigger.new) {
        dentalOfficesForNewClaims.add(newClaim.Dental_Office__c);
    }

    // Query for all claims in Salesforce related to the dental offices of new claims
    List<Claim__c> relatedClaims = [
        SELECT Id, Status__c, Claim_Completed__c, Patient_Name__c, Claim_Amount__c, Date_of_Service__c, Subscriber_ID__c, Insurance_Carrier__c, Dental_Office__c, Patient_DOB__c
        FROM Claim__c
        WHERE Dental_Office__c IN :dentalOfficesForNewClaims
    ];

    // Populate the map with existing claims based on a unique key
    for (Claim__c claim : relatedClaims) {
        String uniqueKey = claim.Patient_Name__c + '-' + claim.Claim_Amount__c + '-' + claim.Date_of_Service__c + '-' + claim.Subscriber_ID__c + '-' + claim.Insurance_Carrier__c + '-' + claim.Dental_Office__c + '-' + claim.Patient_DOB__c;
        existingClaimsMap.put(uniqueKey, claim);
    }

    // Process each new claim to handle duplicates according to the specified conditions
    for (Claim__c newClaim : Trigger.new) {
        String uniqueKey = newClaim.Patient_Name__c + '-' + newClaim.Claim_Amount__c + '-' + newClaim.Date_of_Service__c + '-' + newClaim.Subscriber_ID__c + '-' + newClaim.Insurance_Carrier__c + '-' + newClaim.Dental_Office__c + '-' + newClaim.Patient_DOB__c;
        newClaimKeys.add(uniqueKey);

        // Check if there's a matching existing claim
        if (existingClaimsMap.containsKey(uniqueKey)) {
            Claim__c existingClaim = existingClaimsMap.get(uniqueKey);
            if (existingClaim.Status__c == 'Completed') {
                existingClaim.Status__c = 'New'; 
                claimsToUpdate.add(existingClaim);
            }
        }
    }

    // Process all existing claims to update their status based on conditions
    // for (Claim__c existingClaim : relatedClaims) {
    //     String uniqueKey = existingClaim.Patient_Name__c + '-' + existingClaim.Claim_Amount__c + '-' + existingClaim.Date_of_Service__c + '-' + existingClaim.Subscriber_ID__c + '-' + existingClaim.Insurance_Carrier__c + '-' + existingClaim.Dental_Office__c + '-' + existingClaim.Patient_DOB__c;

    //     // If a claim is not in the new claims but is present in Salesforce and the checkbox is not true
    //     if (!newClaimKeys.contains(uniqueKey) && !existingClaim.Claim_Completed__c) {
    //         existingClaim.Status__c = 'Completed';
    //         claimsToUpdate.add(existingClaim);
    //     }
    // }

    // Update claims if necessary
    if (!claimsToUpdate.isEmpty()) {
        update claimsToUpdate;
    }
}