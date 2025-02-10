trigger CalculatePmtSumOnBillingReport on Billing_Report__c (after insert,after Update) {
           Set<Id> accountIds = new Set<Id>();
           Date fromDate;
           Date toDate; 
            // Collect account IDs from Billing_Report__c records
            if (trigger.isInsert){ 
            system.debug('after isInsert run ');

            for (Billing_Report__c report : Trigger.new) {
                if (report.Dental_Office__c != null) {
                    fromdate = report.From_Date__c;           
                    todate = report.To_Date__c;  
                   accountIds.add(report.Dental_Office__c);
                } 
            }
            }
            else if (Trigger.isUpdate) {
                System.debug('after update run');
            
                for (Billing_Report__c report : Trigger.old) {
                    // Get the new version of the record safely
                    Billing_Report__c newReport = Trigger.newMap.get(report.Id);
                    
                    if (newReport != null) {
                        // Ensure From_Date__c and To_Date__c exist before comparing
                        if ((newReport.From_Date__c != null && newReport.From_Date__c != report.From_Date__c) ||
                            (newReport.To_Date__c != null && newReport.To_Date__c != report.To_Date__c)) {
            
                            fromDate = (newReport.From_Date__c != null) ? newReport.From_Date__c : Date.today();           
                            toDate = Date.today(); // Keeping this fixed as per your comment
                            
                            System.debug('fromDate: ' + fromDate);
                            System.debug('toDate: ' + toDate);
                            
                            // Ensure Dental_Office__c is not null before adding
                            if (report.Dental_Office__c != null) {
                                accountIds.add(report.Dental_Office__c);
                            }
                        }
                    }
                }
            }
                
            // Fetch pmt__c records related to these accounts, created in the last 7 days
            List<AggregateResult> totalAppealedClaims = new List<AggregateResult>();

            if (accountIds != null && !accountIds.isEmpty() && fromDate != null && toDate != null) {
                totalAppealedClaims = [
                    SELECT Account__c, 
                           SUM(Claims_Appealed__c) totalClaimsAppealed, 
                           SUM(EBS_Claims_Appealed__c) totalEbsClaimsAppealed 
                    FROM pmt__c
                    WHERE Account__c IN :accountIds 
                      AND CreatedDate >= :fromDate
                      AND CreatedDate <= :toDate.addDays(1)
                    GROUP BY Account__c
                ];
            }
            
                system.debug('totalAppealedClaims  '+totalAppealedClaims );

         
            
            // Query to fetch records from Monday
            List<AggregateResult> OCRclaimstouched = new List<AggregateResult>();

            if (accountIds != null && !accountIds.isEmpty() && fromDate != null && toDate != null) {
                OCRclaimstouched = [
                    SELECT Account__c, 
                           SUM(Outstanding_Claims_Worked__c) NOSOutstandingClaimsWorked, 
                           SUM(EBS_Outstanding_Claims_Worked__c) EBSOutstandingClaimsWorked
                    FROM pmt__c
                    WHERE Account__c IN :accountIds 
                      AND CreatedDate >= :fromDate
                      AND CreatedDate <= :toDate.addDays(1)
                    GROUP BY Account__c
                ];
            }
            
            System.debug('OCRclaimstouched: ' + OCRclaimstouched);

            List<AggregateResult> OpenAppeal = [
            SELECT Dental_Office__c, Count(ID) OpenAppeal 
            FROM Claim__c
            WHERE Dental_Office__c IN :accountIds AND Status__c = 'In Appeals'
            GROUP BY Dental_Office__c];
            system.debug('OpenAppeal  '+OpenAppeal );

         
            
            List<AggregateResult> needVbsAssitance =[
                Select Dental_Office__c, Count(ID) Need_VBS_Assitance
                From Claim__c
                Where Dental_Office__c IN :accountIds 
                AND Status__c = 'Needs VBS Assistance'
                GROUP BY Dental_Office__c];
                system.debug('needVbsAssitance  '+needVbsAssitance );

         
         
         
            // Prepare to update billing_report__c records
            List<Billing_Report__c> billingReportsToUpdate = new List<Billing_Report__c>();
            Map<Id, Integer> totalCountMap = new Map<Id, Integer>();
            Map<Id, Integer> StatusNoteMap = new Map<Id, integer>();
         
            Integer SumofTotalApeals = 0;
         
            for (AggregateResult ar : OpenAppeal) {
                SumofTotalApeals += (Integer) ar.get('OpenAppeal');
            }
                
         
                Integer RequireVbsAssistance = 0;
                for (AggregateResult vbs: needVbsAssitance){
                    RequireVbsAssistance += (Integer) vbs.get('Need_VBS_Assitance');
                }
                
         
         
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
                    reportToUpdate.Id = report.Id; 
                    reportToUpdate.Number_of_appeals_managed__c = String.valueOf(combinedTotalCount); 
                    reportToUpdate.Number_of_open_appeals__c	= String.valueOf(SumofTotalApeals);
                    reportToUpdate.Number_of_claims_still_requiring_VBS_ass__c	= String.valueOf(RequireVbsAssistance); 
                    reportToUpdate.Number_of_OCR_claims_touched_including__c = String.valueOf(combinedStatusNote);
                    billingReportsToUpdate.add(reportToUpdate);
                }
            }
            // Perform the update if there are any reports to update
            if (!billingReportsToUpdate.isEmpty()) {
                update billingReportsToUpdate;
            }
        }