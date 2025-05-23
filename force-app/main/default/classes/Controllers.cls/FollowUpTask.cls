public without sharing class FollowUpTask {
    @AuraEnabled(Cacheable = true)
    public static List<Map<String, Object>> FollowUpTask(String userId) {

        Set<Id> claimIdsss = new Set<Id>();
        List<Claim__c> claims;
        
        if (String.isBlank(userId)) {
            claims = [
                SELECT Id
                FROM Claim__c
                WHERE Dental_Office__c NOT IN (
                    SELECT Id FROM Account WHERE Name LIKE '%TERMED%'
                )
				AND Status__c NOT IN ('Completed', 'DUPLICATE SF CLAIM - DELETE')


            ];
        } else {
            claims = [
                SELECT Id
                FROM Claim__c
                WHERE Dental_Office__c NOT IN (
                    SELECT Id FROM Account WHERE Name LIKE '%TERMED%'
                )
                AND Dental_Office__r.Stateside_VBs__c = :userId
                AND Status__c NOT IN ('Completed', 'DUPLICATE SF CLAIM - DELETE')

            ];
        }
        
        for (Claim__c c : claims) {
            claimIdsss.add(c.Id);
        }




        List<AggregateResult> taskResults = [
            SELECT OwnerId, Owner.Name ownerName,
                   WhatId, What.Name claimName,
                   COUNT(Id) AssignedTasks,
                   LastModifiedById, 
                   Status
            FROM Task
            WHERE Subject = 'Follow Up'
            AND ActivityDate >= TODAY
            AND ActivityDate <= NEXT_N_DAYS:2            
            AND What.Type = 'Claim__c'
            AND WhatId IN :claimIdsss
            AND Status Not In ('Completed','DUPLICATE SF CLAIM - DELETE','New', 'Needs VBS Assistance', 'Needs Office Assistance')
            GROUP BY OwnerId, Owner.Name, WhatId, What.Name, LastModifiedById, Status
        ];

        List<AggregateResult> newclaims = [
            SELECT OwnerId, Owner.Name ownerName,
                   WhatId, What.Name claimName,
                   COUNT(Id) AssignedTasks,
                   LastModifiedById, 
                   Status
            FROM Task
            WHERE Subject = 'Follow Up'          
            AND What.Type = 'Claim__c'
            AND ActivityDate > TODAY
            AND WhatId IN :claimIdsss
            AND Status In ('New', 'Needs VBS Assistance', 'Needs Office Assistance')
            GROUP BY OwnerId, Owner.Name, WhatId, What.Name, LastModifiedById, Status
        ];
        
        taskResults.addAll(newclaims);


        Set<Id> claimIds = new Set<Id>();
        for (AggregateResult ar : taskResults) {
            if (ar.get('WhatId') != null) {
                claimIds.add((Id) ar.get('WhatId'));
            }
        }

        Map<Id, Claim__c> claimMap = new Map<Id, Claim__c>([
            SELECT Id, Name, Dental_Office__c, Dental_Office__r.Name, Insurance_Carrier__c, Claim_Amount__c
            FROM Claim__c
            WHERE Id IN :claimIds
            AND Status__c NOT IN ('Completed', 'DUPLICATE SF CLAIM - DELETE', 'New', 'Needs VBS Assistance', 'Needs Office Assistance')
            AND Dental_Office__c NOT IN (
            SELECT Id FROM Account WHERE Name LIKE '%TERMED%'
            )
        ]);
        
        // Second query: Get claims with other statuses
        Map<Id, Claim__c> newClaimMap = new Map<Id, Claim__c>([
            SELECT Id, Name, Dental_Office__c, Dental_Office__r.Name, Insurance_Carrier__c, Claim_Amount__c
            FROM Claim__c
            WHERE Id IN :claimIds
            AND Dental_Office__c NOT IN (
            SELECT Id FROM Account WHERE Name LIKE '%TERMED%' 
            )
            AND Status__c IN ('New', 'Needs VBS Assistance', 'Needs Office Assistance')
        ]);
        
        // Merge the results into claimMap
        claimMap.putAll(newClaimMap);

        Map<Id, Map<String, Object>> pendingTaskMap = new Map<Id, Map<String, Object>>();

        List<AggregateResult> pendingTaskResults = [
            SELECT WhatId, COUNT(Id) countOfTasks
            FROM Task
            Where Status != 'Completed'
            AND ActivityDate >= LAST_N_DAYS:30  // Last 30 days (including today)
            AND ActivityDate < TODAY       
            AND WhatId IN :claimIdsss      
            GROUP BY WhatId
        ];

        for (AggregateResult ar : pendingTaskResults) {
            Id claimId = (Id) ar.get('WhatId');
            System.debug('claimId: ' + claimId);
            System.debug('countOfTasks: ' + ar.get('countOfTasks'));
            Integer countOfTasks = (Integer) ar.get('countOfTasks');
            Decimal pendingTaskAmount = claimMap.containsKey(claimId) ? claimMap.get(claimId).Claim_Amount__c : 0;

            Map<String, Object> taskData = new Map<String, Object>{
                'countOfClaims' => countOfTasks,
                'pendingTaskAmount' => pendingTaskAmount != null ? pendingTaskAmount : 0
            };
            pendingTaskMap.put(claimId, taskData);
        }
        System.debug('pendingTaskMap: ' + pendingTaskMap);

        List<Task> pendingTasksList = [
            SELECT Id, WhatId, Owner.Name, LastModifiedById, ActivityDate, LastModifiedDate, Description, Status 
            FROM Task 
            WHERE Status != 'Completed'
            AND ActivityDate >= LAST_N_DAYS:30 // Last 30 days (including today)
            AND WhatId IN :claimIdsss
            
            AND ActivityDate < TODAY    
        ];
        
        // Extract the WhatId values from the tasks
        Set<Id> whatIds = new Set<Id>();
        for (Task t : pendingTasksList) {
            if (t.WhatId != null) {
                whatIds.add(t.WhatId);
            }
        }
        
        // Query Claims using the WhatIds from tasks
        Map<Id, Claim__c> newClaimMap12 = new Map<Id, Claim__c>([
            SELECT Id, Name, Dental_Office__c, Dental_Office__r.Name, Insurance_Carrier__c, Claim_Amount__c
            FROM Claim__c
            WHERE Id IN :whatIds
            AND Status__c != 'Completed'
            AND Dental_Office__c NOT IN (
                SELECT Id FROM Account WHERE Name LIKE '%TERMED%'
            )
        ]);
        claimMap.putAll(newClaimMap12);

        Map<Id, List<Map<String, Object>>> pendingTasksByOffice = new Map<Id, List<Map<String, Object>>>();

        for (Task t : pendingTasksList) {
            Claim__c claim = claimMap.get(t.WhatId);
            if (claim == null || claim.Dental_Office__c == null) {
                continue;
            }

            Id dentalOfficeId = claim.Dental_Office__c;

            if (!pendingTasksByOffice.containsKey(dentalOfficeId)) {
                pendingTasksByOffice.put(dentalOfficeId, new List<Map<String, Object>>());
            }

            pendingTasksByOffice.get(dentalOfficeId).add(new Map<String, Object> {
                'claimId' => t.WhatId,
                'claimName' => claim.Name,
                'DueDate'=> t.ActivityDate,
                'ownerName' => t.Owner.Name,
                'lastModifiedById' => t.LastModifiedById,
                'lastModifiedDate' => t.LastModifiedDate.format('yyyy-MM-dd'),
                'description' => t.Description,
                'status' => t.Status,
                'insuranceName' => claim.Insurance_Carrier__c
            });
        }

        Map<Id, List<Task>> taskDetailsMap = new Map<Id, List<Task>>();
        List<Task> AssignedTaskList = [
            SELECT WhatId, LastModifiedDate, ActivityDate, Description
            FROM Task
            WHERE WhatId IN :claimIds
            AND Subject = 'Follow Up'
            AND ActivityDate >= TODAY
            AND ActivityDate <= NEXT_N_DAYS:2
            AND WhatId IN :claimIdsss            
            AND What.Type = 'Claim__c'
            AND Status NOT IN ('Completed', 'DUPLICATE SF CLAIM - DELETE', 'New', 'Needs VBS Assistance', 'Needs Office Assistance')
        ];
        
        // Second query: Get tasks with other statuses
        List<Task> newAssignedTaskList = [
            SELECT WhatId, LastModifiedDate, ActivityDate, Description
            FROM Task
            WHERE WhatId IN :claimIds
            AND Subject = 'Follow Up'
            // AND WhatId IN :claimIdsss

            AND What.Type = 'Claim__c'
            AND Status IN ('New', 'Needs VBS Assistance', 'Needs Office Assistance')
        ];
        
        // Merge the two task lists
        AssignedTaskList.addAll(newAssignedTaskList);

        for (Task t : AssignedTaskList) {
            if (!taskDetailsMap.containsKey(t.WhatId)) {
                taskDetailsMap.put(t.WhatId, new List<Task>());
            }
            taskDetailsMap.get(t.WhatId).add(t);
        }

        Map<Id, Map<String, Object>> dentalOfficeMap = new Map<Id, Map<String, Object>>();

        for (AggregateResult ar : taskResults) {
            Id claimId = (Id) ar.get('WhatId');
            String ownerName = (String) ar.get('ownerName');
            Integer assignedTasks = (Integer) ar.get('AssignedTasks');
            Id lastModifiedById = (Id) ar.get('LastModifiedById');
            String status = (String) ar.get('Status');

            Claim__c claim = claimMap.get(claimId);
            if (claim == null || claim.Dental_Office__c == null) {
                continue;
            }

            Id dentalOfficeId = claim.Dental_Office__c;
            Map<String, Object> dentalOfficeData;

            System.debug('!dentalOfficeMap.containsKey(dentalOfficeId) >>>> '+!dentalOfficeMap.containsKey(dentalOfficeId));

            if (!dentalOfficeMap.containsKey(dentalOfficeId)) {
                dentalOfficeData = new Map<String, Object>();
                dentalOfficeData.put('dentalOfficeId', dentalOfficeId);
                dentalOfficeData.put('dentalOfficeName', claim.Dental_Office__r.Name);
                dentalOfficeData.put('countOfClaims', pendingTaskMap.containsKey(claimId) ? pendingTaskMap.get(claimId).get('countOfClaims') : 0);
                dentalOfficeData.put('pendingTaskAmount', pendingTaskMap.containsKey(claimId) ? pendingTaskMap.get(claimId).get('pendingTaskAmount') : 0);
                dentalOfficeData.put('owners', new Map<String, Integer>());
                dentalOfficeData.put('claims', new List<Map<String, Object>>());
                dentalOfficeData.put('pendingTasks', pendingTasksByOffice.containsKey(dentalOfficeId) ? pendingTasksByOffice.get(dentalOfficeId) : new List<Map<String, Object>>());

                dentalOfficeMap.put(dentalOfficeId, dentalOfficeData);
                system.debug('dentalOfficeMap: ' + dentalOfficeMap);
            } else {
                dentalOfficeData = dentalOfficeMap.get(dentalOfficeId);
                system.debug('dentalOfficeMap:12 ' + dentalOfficeMap);

            }

            List<Map<String, Object>> claimsList = (List<Map<String, Object>>) dentalOfficeData.get('claims');
            List<Task> taskDetails = taskDetailsMap.get(claimId);

            if (taskDetails != null) {
                for (Task t : taskDetails) {
                    Map<String, Object> claimData = new Map<String, Object>();
                    claimData.put('claimId', claimId);
                    claimData.put('claimName', ar.get('claimName'));
                    claimData.put('ownerName', ownerName);
                    claimData.put('lastModifiedById', lastModifiedById);
                    claimData.put('lastModifiedDate', t.LastModifiedDate != null ? t.LastModifiedDate.format('yyyy-MM-dd') : null);
                    claimData.put('description', t.Description);
                    claimData.put('DueDate', t.ActivityDate != null ? t.ActivityDate.format() : null);
                    claimData.put('status', status);
                    claimData.put('insuranceName', claim.Insurance_Carrier__c);
                    claimsList.add(claimData);
                }
            } else {
                System.debug('No task details found for claimId: ' + claimId);
            }
        }

        return new List<Map<String, Object>>(dentalOfficeMap.values());
    }
}