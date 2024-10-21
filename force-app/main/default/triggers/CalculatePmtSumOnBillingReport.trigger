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

    List<AggregateResult> OCRclaimstouched = [
        SELECT Account__c, 
               SUM(Outstanding_Claims_Worked__c) NOSOutstandingClaimsWorked, 
               SUM(EBS_Outstanding_Claims_Worked__c) EBSOutstandingClaimsWorked
        FROM pmt__c
        WHERE Account__c IN :accountIds 
          AND CreatedDate = LAST_N_DAYS:7
        GROUP BY Account__c
    ];





    List<AggregateResult> OpenAppeal = [
    SELECT Dental_Office__c, Count(ID) OpenAppeal 
    FROM Claim__c
    WHERE Dental_Office__c IN :accountIds AND Status__c != 'Completed' AND Status__c != 'DUPLICATE SF CLAIM - DELETE'	
    GROUP BY Dental_Office__c];
    System.debug('OpenAppeal: ' + OpenAppeal);

    System.debug('Total Appealed Claims: ' + totalAppealedClaims);
    
    List<AggregateResult> needVbsAssitance =[
        Select Dental_Office__c, Count(ID) Need_VBS_Assitance
        From Claim__c
        Where Dental_Office__c IN :accountIds 
        AND Status__c = 'Needs VBS Assistance'
        GROUP BY Dental_Office__c];
        
        System.debug('needVbsAssitance ++' +needVbsAssitance);




    // Prepare to update billing_report__c records
    List<Billing_Report__c> billingReportsToUpdate = new List<Billing_Report__c>();
    Map<Id, Integer> totalCountMap = new Map<Id, Integer>();
    Map<Id, Integer> StatusNoteMap = new Map<Id, integer>();

    Integer SumofTotalApeals = 0;

    for (AggregateResult ar : OpenAppeal) {
        SumofTotalApeals += (Integer) ar.get('OpenAppeal');
    }
        System.debug('Appealed Claims: ' + SumofTotalApeals);

        Integer RequireVbsAssistance = 0;
    
        for (AggregateResult vbs: needVbsAssitance){
            RequireVbsAssistance += (Integer) vbs.get('Need_VBS_Assitance');
        }
        System.debug('RequireVbsAssistance: ' + RequireVbsAssistance);


    // Process totalAppealedClaims to populate totalCountMap
    for (AggregateResult result : OCRclaimstouched) {
        Id accountId = (Id) result.get('Account__c');

        // Safely get the totals and handle potential null values
        Integer NOSOutstandingClaimsWorked = (result.get('NOSOutstandingClaimsWorked') != null) ? 
        ((Decimal) result.get('NOSOutstandingClaimsWorked')).intValue() : 0;

        Integer EBSOutstandingClaimsWorked = (result.get('EBSOutstandingClaimsWorked') != null) ? 
            ((Decimal) result.get('EBSOutstandingClaimsWorked')).intValue() : 0;

        // Combine both totals
        Integer TotalOutstandingClaimsWorked = EBSOutstandingClaimsWorked + NOSOutstandingClaimsWorked;
        StatusNoteMap.put(accountId, TotalOutstandingClaimsWorked);
    }

    for (AggregateResult result : totalAppealedClaims) {
        Id accountId = (Id) result.get('Account__c');

        // Safely get the totals and handle potential null values
        Integer totalClaimsAppealed = (result.get('totalClaimsAppealed') != null) ? 
                                       ((Decimal) result.get('totalClaimsAppealed')).intValue() : 0;
    Integer totalEbsClaimsAppealed = (result.get('totalEbsClaimsAppealed') != null) ? 
                                           ((Decimal) result.get('totalEbsClaimsAppealed')).intValue() : 0;

        // Combine both totals
        Integer totalCount = totalClaimsAppealed + totalEbsClaimsAppealed;
        totalCountMap.put(accountId, totalCount);
    }




    // Iterate over the Billing_Report__c records to update
    for (Billing_Report__c report : Trigger.new) {
        Integer combinedTotalCount = 0;
        Integer combinedStatusNote = 0; 

        // Check if Dental_Office__c matches any account in the totalCountMap
        if (report.Dental_Office__c != null && totalCountMap.containsKey(report.Dental_Office__c)) {
            combinedTotalCount += totalCountMap.get(report.Dental_Office__c);
        }
        if (report.Dental_Office__c != null && StatusNoteMap.containsKey(report.Dental_Office__c)) {
            combinedStatusNote += StatusNoteMap.get(report.Dental_Office__c);
        }

        // Check if Dental_Office_2__c matches any account in the totalCountMap
        if (report.Dental_Office_2__c != null && totalCountMap.containsKey(report.Dental_Office_2__c)) {
            combinedTotalCount += totalCountMap.get(report.Dental_Office_2__c);
        }
        if (report.Dental_Office_2__c != null && StatusNoteMap.containsKey(report.Dental_Office_2__c)) {
            combinedStatusNote += StatusNoteMap.get(report.Dental_Office_2__c);
        }

        // Update the report only if there's a count
        if (combinedTotalCount > 0  || SumofTotalApeals > 0  ||  RequireVbsAssistance > 0  || combinedStatusNote > 0) {
            // Create a new instance for the update
            Billing_Report__c reportToUpdate = new Billing_Report__c();
            reportToUpdate.Id = report.Id; // Set the ID of the report to update
            reportToUpdate.Number_of_appeals_managed__c = String.valueOf(combinedTotalCount); // Update the field
            reportToUpdate.Number_of_open_appeals__c	= String.valueOf(SumofTotalApeals); // Update the field
            reportToUpdate.Number_of_claims_still_requiring_VBS_ass__c	= String.valueOf(RequireVbsAssistance); // Update the field
            reportToUpdate.Number_of_OCR_claims_touched_including__c = String.valueOf(combinedStatusNote);
            billingReportsToUpdate.add(reportToUpdate);
        }
    }
    
    // Perform the update if there are any reports to update
    if (!billingReportsToUpdate.isEmpty()) {
        update billingReportsToUpdate;
    }
}