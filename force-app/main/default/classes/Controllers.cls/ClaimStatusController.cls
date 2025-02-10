public with sharing class ClaimStatusController {

    @AuraEnabled
    public static Map<String, Integer> getClaimStatusCounts(String recordId ) {
        Map<String, Integer> statusCounts = new Map<String, Integer>();

        // Query to count claims grouped by their Status
        AggregateResult[] results = [
            SELECT Status__c, COUNT(Id) total
            FROM Claim__c
            WHERE Dental_Office__c  = :recordId
            GROUP BY Status__c
        ];

        // Populate the map with the results
        for (AggregateResult result : results) {
            statusCounts.put((String) result.get('Status__c'), (Integer) result.get('total'));
        }

        return statusCounts;
    }

    @AuraEnabled(cacheable=true)
   public static List<Claim__c> getRecordsByStatus(String status, String recordId) {
        return [
            SELECT Id, Name, Status__c,Date_of_Service__c,Insurance_Carrier__c, Patient_Name__c, Claim_Amount__c
            FROM Claim__c
            WHERE Dental_Office__c  = :recordId
            AND Status__c = :status
            WITH SECURITY_ENFORCED

        ];
    }
}
