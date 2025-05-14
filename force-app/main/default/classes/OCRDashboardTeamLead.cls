public without sharing class OCRDashboardTeamLead {

    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [
            SELECT Id, Name 
            FROM User 
            WHERE IsActive = true 
              AND Id IN (SELECT Stateside_VBs__c FROM Account) 
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> OCRDashboardTeamLead(String userId) {
        try {
            // Get all relevant claims
            Set<Id> userClaimIds = getRelevantClaimIds(userId);
            
            // Get all claim details
            Map<Id, Claim__c> claimMap = getClaimDetails(userClaimIds);
            
            // Get active tasks (upcoming or with specific statuses)
            Map<Id, List<Task>> activeTasksByClaimId = getActiveTasksByClaimId(userClaimIds);
            
            // Get pending tasks (past due and not completed)
            Map<Id, List<Task>> pendingTasksByClaimId = getPendingTasksByClaimId(userClaimIds);
            
            // Process data for dashboard view
            return buildDashboardData(activeTasksByClaimId, pendingTasksByClaimId, claimMap);
        } catch(Exception e) {
            throw new AuraHandledException('Error retrieving dashboard data: ' + e.getMessage());
        }
    }
    
    public static Set<Id> getRelevantClaimIds(String userId) {
        Set<Id> claimIds = new Set<Id>();
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
            claimIds.add(c.Id);
        }
        
        return claimIds;
    }

    
    
    public static Map<Id, Claim__c> getClaimDetails(Set<Id> claimIds) {
        return new Map<Id, Claim__c>([
            SELECT Id, Name, Dental_Office__c, Dental_Office__r.Name, Insurance_Carrier__c, 
                   Claim_Amount__c, Status__c
            FROM Claim__c
            WHERE Id IN :claimIds
              AND Dental_Office__c NOT IN (
                  SELECT Id FROM Account WHERE Name LIKE '%TERMED%'
              )
        ]);
    }
    
    public static Map<Id, List<Task>> getActiveTasksByClaimId(Set<Id> claimIds) {
        Map<Id, List<Task>> tasksByClaimId = new Map<Id, List<Task>>();
        
        List<Task> activeTasks = [
            SELECT Id, WhatId, OwnerId, Owner.Name, Subject, Status, ActivityDate, 
                   LastModifiedById, LastModifiedDate, Description
            FROM Task
            WHERE Subject = 'Follow Up'
              AND What.Type = 'Claim__c' 
              AND WhatId IN :claimIds
              AND (
                  (ActivityDate >= TODAY AND ActivityDate <= NEXT_N_DAYS:2 
                      AND Status NOT IN ('Completed','DUPLICATE SF CLAIM - DELETE','New', 'Needs VBS Assistance', 'Needs Office Assistance')) 
                  OR 
                  (Status IN ('New', 'Needs VBS Assistance', 'Needs Office Assistance'))
              )
        ];
        
        // Organize tasks by claim ID
        for (Task t : activeTasks) {
            if (!tasksByClaimId.containsKey(t.WhatId)) {
                tasksByClaimId.put(t.WhatId, new List<Task>());
            }
            tasksByClaimId.get(t.WhatId).add(t);
        }
        
        return tasksByClaimId;
    }
    
    public static Map<Id, List<Task>> getPendingTasksByClaimId(Set<Id> claimIds) {
        Map<Id, List<Task>> pendingTasksByClaimId = new Map<Id, List<Task>>();
        
        List<Task> pendingTasks = [
            SELECT Id, WhatId, OwnerId, Owner.Name, Subject, Status, ActivityDate, 
                   LastModifiedById, LastModifiedDate, Description
            FROM Task 
            WHERE WhatId IN :claimIds
              AND Status != 'Completed'
              AND ActivityDate >= LAST_N_DAYS:30
              AND ActivityDate < TODAY
        ];
        
        // Organize pending tasks by claim ID
        for (Task t : pendingTasks) {
            if (!pendingTasksByClaimId.containsKey(t.WhatId)) {
                pendingTasksByClaimId.put(t.WhatId, new List<Task>());
            }
            pendingTasksByClaimId.get(t.WhatId).add(t);
        }
        
        return pendingTasksByClaimId;
    }
    
    public static List<Map<String, Object>> buildDashboardData(
        Map<Id, List<Task>> activeTasksByClaimId, 
        Map<Id, List<Task>> pendingTasksByClaimId,
        Map<Id, Claim__c> claimMap
    ) {
        // Group by dental office
        Map<Id, Map<String, Object>> dentalOfficeMap = new Map<Id, Map<String, Object>>();
        
        // Combine claim IDs from both active and pending tasks
        Set<Id> allClaimIds = new Set<Id>();
        allClaimIds.addAll(activeTasksByClaimId.keySet());
        allClaimIds.addAll(pendingTasksByClaimId.keySet());
        
        // Process all claims with any tasks (active or pending)
        for (Id claimId : allClaimIds) {
            Claim__c claim = claimMap.get(claimId);
            if (claim == null || claim.Dental_Office__c == null) continue;
            
            Id dentalOfficeId = claim.Dental_Office__c;
            Map<String, Object> dentalOfficeData;
            
            // Create dental office entry if it doesn't exist
            if (!dentalOfficeMap.containsKey(dentalOfficeId)) {
                dentalOfficeData = new Map<String, Object>{
                    'dentalOfficeId' => dentalOfficeId,
                    'dentalOfficeName' => claim.Dental_Office__r.Name,
                    'countOfPendingClaims' => 0,
                    'pendingTaskAmount' => 0,
                    'owners' => new Map<String, Integer>(),
                    'claims' => new List<Map<String, Object>>(),
                    'pendingTasks' => new List<Map<String, Object>>()
                };
                dentalOfficeMap.put(dentalOfficeId, dentalOfficeData);
            } else {
                dentalOfficeData = dentalOfficeMap.get(dentalOfficeId);
            }
            
            // Process active tasks for this claim
            if (activeTasksByClaimId.containsKey(claimId)) {
                List<Task> claimTasks = activeTasksByClaimId.get(claimId);
                List<Map<String, Object>> claimsList = (List<Map<String, Object>>) dentalOfficeData.get('claims');
                
                // Add each active task as a claim entry
                for (Task t : claimTasks) {
                    claimsList.add(new Map<String, Object>{
                        'taskId' => t.Id,
                        'claimId' => claimId,
                        'claimName' => claim.Name,
                        'ownerName' => t.Owner.Name,
                        'ownerId' => t.OwnerId,
                        'lastModifiedById' => t.LastModifiedById,
                        'lastModifiedDate' => t.LastModifiedDate != null ? t.LastModifiedDate.format('yyyy-MM-dd') : null,
                        'description' => t.Description,
                        'dueDate' => t.ActivityDate != null ? t.ActivityDate.format() : null,
                        'status' => t.Status,
                        'insuranceName' => claim.Insurance_Carrier__c
                    });
                    
                    // Track task owners
                    Map<String, Integer> owners = (Map<String, Integer>) dentalOfficeData.get('owners');
                    String ownerName = t.Owner.Name;
                    owners.put(ownerName, owners.containsKey(ownerName) ? owners.get(ownerName) + 1 : 1);
                }
            }
            
            // Process pending tasks for this claim
            if (pendingTasksByClaimId.containsKey(claimId)) {
                List<Task> pendingTasks = pendingTasksByClaimId.get(claimId);
                List<Map<String, Object>> pendingTasksList = (List<Map<String, Object>>) dentalOfficeData.get('pendingTasks');
                
                // Update pending task metrics
                Integer countOfPendingClaims = (Integer) dentalOfficeData.get('countOfPendingClaims');
                Decimal pendingTaskAmount = (Decimal) dentalOfficeData.get('pendingTaskAmount');
                
                dentalOfficeData.put('countOfPendingClaims', countOfPendingClaims + pendingTasks.size());
                dentalOfficeData.put('pendingTaskAmount', pendingTaskAmount + (claim.Claim_Amount__c != null ? claim.Claim_Amount__c : 0));
                
                // Add each pending task details
                for (Task t : pendingTasks) {
                    pendingTasksList.add(new Map<String, Object>{
                        'taskId' => t.Id,
                        'claimId' => claimId,
                        'claimName' => claim.Name,
                        'ownerName' => t.Owner.Name,
                        'ownerId' => t.OwnerId,
                        'lastModifiedById' => t.LastModifiedById,
                        'lastModifiedDate' => t.LastModifiedDate != null ? t.LastModifiedDate.format('yyyy-MM-dd') : null,
                        'description' => t.Description,
                        'dueDate' => t.ActivityDate != null ? t.ActivityDate.format() : null,
                        'status' => t.Status,
                        'insuranceName' => claim.Insurance_Carrier__c
                    });
                    
                    // Track task owners for pending tasks as well
                    Map<String, Integer> owners = (Map<String, Integer>) dentalOfficeData.get('owners');
                    String ownerName = t.Owner.Name;
                    owners.put(ownerName, owners.containsKey(ownerName) ? owners.get(ownerName) + 1 : 1);
                }
            }
        }
        
        return new List<Map<String, Object>>(dentalOfficeMap.values());
    }
}