trigger CalculatePmtSumOnBillingReport on Billing_Report__c (after insert) {
    Set<Id> accountIds = new Set<Id>();
    
    // Collect account IDs from Billing_Report__c records
    for (Billing_Report__c report : Trigger.new) {
        if (report.Dental_Office__c != null) {
            accountIds.add(report.Dental_Office__c);
        }
        if (report.Dental_Office_2__c != null) {
            accountIds.add(report.Dental_Office_2__c);
        }
    }
    
    // Fetch pmt__c records related to these accounts, created in the last 7 days
    List<AggregateResult> totalAppealedClaims = [
        SELECT Account__c, 
               SUM(Claims_Appealed__c) totalClaimsAppealed, 
               SUM(EBS_Claims_Appealed__c) totalEbsClaimsAppealed 
        FROM pmt__c
        WHERE Account__c IN :accountIds 
          AND CreatedDate = LAST_N_DAYS:7
        GROUP BY Account__c
    ];

    System.debug('Total Appealed Claims: ' + totalAppealedClaims);
    
    // Prepare to update billing_report__c records
    List<Billing_Report__c> billingReportsToUpdate = new List<Billing_Report__c>();
    Map<Id, Decimal> totalCountMap = new Map<Id, Decimal>();

    // Process totalAppealedClaims to populate totalCountMap
    for (AggregateResult result : totalAppealedClaims) {
        Id accountId = (Id) result.get('Account__c');

        // Safely get the totals and handle potential null values
        Decimal totalClaimsAppealed = (Decimal) result.get('totalClaimsAppealed') != null ? 
                                       (Decimal) result.get('totalClaimsAppealed') : 0;
        Decimal totalEbsClaimsAppealed = (Decimal) result.get('totalEbsClaimsAppealed') != null ? 
                                           (Decimal) result.get('totalEbsClaimsAppealed') : 0;

        // Combine both totals
        Decimal totalCount = totalClaimsAppealed + totalEbsClaimsAppealed;
        totalCountMap.put(accountId, totalCount);
    }

    // Iterate over the Billing_Report__c records to update
    for (Billing_Report__c report : Trigger.new) {
        Decimal combinedTotalCount = 0;

        // Check if Dental_Office__c matches any account in the totalCountMap
        if (report.Dental_Office__c != null && totalCountMap.containsKey(report.Dental_Office__c)) {
            combinedTotalCount += totalCountMap.get(report.Dental_Office__c);
        }

        // Check if Dental_Office_2__c matches any account in the totalCountMap
        if (report.Dental_Office_2__c != null && totalCountMap.containsKey(report.Dental_Office_2__c)) {
            combinedTotalCount += totalCountMap.get(report.Dental_Office_2__c);
        }

        // Update the report only if there's a count
        if (combinedTotalCount > 0) {
            // Create a new instance for the update
            Billing_Report__c reportToUpdate = new Billing_Report__c();
            reportToUpdate.Id = report.Id; // Set the ID of the report to update
            reportToUpdate.Number_of_appeals_managed__c = String.valueOf(combinedTotalCount); // Update the field
            billingReportsToUpdate.add(reportToUpdate);
        }
    }
    
    // Perform the update if there are any reports to update
    if (!billingReportsToUpdate.isEmpty()) {
        update billingReportsToUpdate;
    }
}