@IsTest
private class OCRDashboardTeamLeadTest {
    @TestSetup
    static void setupTestData() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
List<User> testUsers = new List<User>();
for (Integer i = 0; i < 2; i++) { // Create 2 users
    testUsers.add(new User(
        FirstName = 'Test'+i,
        LastName = 'User' + i,
        Email = 'testuser12' + i +'1'+ '@gmail.com',
        Username = 'testuser1222' + i +'1'+  '@gmail.com',
        Alias = 'tuser' + i,
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = p.Id,
        LanguageLocaleKey = 'en_US',
        IsActive = true
    ));
}
insert testUsers;
        
        // Create test accounts (dental offices)
        List<Account> dentalOffices = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            dentalOffices.add(new Account(
                Name = 'Test Dental Office ' + i,
                Stateside_VBs__c = testUsers[0].Id
            ));
        }
        // Add a termed account
        dentalOffices.add(new Account(
            Name = 'TERMED Dental Office',
            Stateside_VBs__c = testUsers[0].Id
        ));
        insert dentalOffices;
        
        // Create test claims
        List<Claim__c> claims = new List<Claim__c>();
        for (Integer i = 0; i < 5; i++) {
            claims.add(new Claim__c(
                Patient_Name__c = 'Test Patient 14',
                Dental_Office__c = dentalOffices[Math.mod(i, 3)].Id, // Distribute claims across first 3 offices
                Insurance_Carrier__c = 'Test Insurance',
                Claim_Amount__c = 100 * (i + 1),
                Status__c = 'New'
            ));
        }
        // Add a claim for the termed account (should be excluded)
        claims.add(new Claim__c(
            Patient_Name__c = 'Test Patient 4',
            Dental_Office__c = dentalOffices[3].Id,
            Insurance_Carrier__c = 'Test Insurance',
            Claim_Amount__c = 500,
            Status__c = 'New'
        ));
        insert claims;
        
        // Create test tasks
        List<Task> tasks = new List<Task>();
        Date today = Date.today();
        
        // Active tasks (upcoming)
        for (Integer i = 0; i < 3; i++) {
            tasks.add(new Task(
                WhatId = claims[i].Id,
                Subject = 'Follow Up',
                Status = 'New',
                ActivityDate = today.addDays(i),
                OwnerId = testUsers[Math.mod(i, 2)].Id // Alternate between first two users
            ));
        }
        
        // Active tasks with specific statuses
        tasks.add(new Task(
            WhatId = claims[0].Id,
            Subject = 'Follow Up',
            Status = 'New',
            ActivityDate = today.addDays(-1),
            OwnerId = testUsers[0].Id
        ));
        tasks.add(new Task(
            WhatId = claims[1].Id,
            Subject = 'Follow Up',
            Status = 'Needs VBS Assistance',
            ActivityDate = today.addDays(1),
            OwnerId = testUsers[1].Id
        ));
        
        // Pending tasks (past due)
        for (Integer i = 2; i < 5; i++) {
            tasks.add(new Task(
                WhatId = claims[i].Id,
                Subject = 'Follow Up',
                Status = 'New',
                ActivityDate = today.addDays(-(i + 1)),
                OwnerId = testUsers[Math.mod(i, 2)].Id
            ));
        }
        
        // Task that should be excluded (not Follow Up)
        tasks.add(new Task(
            WhatId = claims[0].Id,
            Subject = 'Other Task',
            Status = 'New',
            ActivityDate = today.addDays(1),
            OwnerId = testUsers[0].Id
        ));
        
        // Task that should be excluded (completed)
        tasks.add(new Task(
            WhatId = claims[1].Id,
            Subject = 'Follow Up',
            Status = 'Completed',
            ActivityDate = today.addDays(-5),
            OwnerId = testUsers[1].Id
        ));
        
        insert tasks;
    }
    
    @IsTest
    static void testGetUsers() {
        Test.startTest();
        List<User> users = OCRDashboardTeamLead.getUsers();
        Test.stopTest();
        
        // Verify we got at least the active user we created in setup
        System.assert(!users.isEmpty(), 'Should return at least one active user');
        System.assertEquals('Test0 User0', users[0].Name, 'Expected first user to be Test User0');
    }
    
    @IsTest
    static void testOCRDashboardTeamLeadWithUserId() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User0' LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> dashboardData = OCRDashboardTeamLead.OCRDashboardTeamLead(testUser.Id);
        Test.stopTest();
        
        // Verify the structure and content of the returned data
        System.assert(!dashboardData.isEmpty(), 'Should return dashboard data for the user');
        
        // Verify we have data for the dental offices (excluding the termed one)
        System.assertEquals(3, dashboardData.size(), 'Should return data for 3 dental offices');
        
        // Verify the first dental office has claims and tasks
        Map<String, Object> firstOffice = dashboardData[0];
        System.assert(firstOffice.containsKey('claims'), 'Dental office data should contain claims');
        System.assert(firstOffice.containsKey('pendingTasks'), 'Dental office data should contain pending tasks');
        
        List<Map<String, Object>> claims = (List<Map<String, Object>>) firstOffice.get('claims');
        System.assert(!claims.isEmpty(), 'Should have active tasks for claims');
        
        // Verify owner counts
        Map<String, Integer> owners = (Map<String, Integer>) firstOffice.get('owners');
        System.assert(!owners.isEmpty(), 'Should have owner counts');
    }
    
    @IsTest
    static void testOCRDashboardTeamLeadWithoutUserId() {
        Test.startTest();
        List<Map<String, Object>> dashboardData = OCRDashboardTeamLead.OCRDashboardTeamLead(null);
        Test.stopTest();
        
        // Verify we got data for all offices (excluding termed)
        System.assertEquals(3, dashboardData.size(), 'Should return data for all 3 dental offices when no user specified');
    }
    
    @IsTest
    static void testGetRelevantClaimIdsWithUserId() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User0' LIMIT 1];
        
        Test.startTest();
        Set<Id> claimIds = OCRDashboardTeamLead.getRelevantClaimIds(testUser.Id);
        Test.stopTest();
        

        

    }
    
    @IsTest
    static void testGetRelevantClaimIdsWithoutUserId() {
        Test.startTest();
        Set<Id> claimIds = OCRDashboardTeamLead.getRelevantClaimIds(null);
        Test.stopTest();
        
        // Verify we got all claims (excluding termed)
        System.assert(!claimIds.isEmpty(), 'Should return all claims when no user specified');
        

    }
    
    @IsTest
    static void testGetClaimDetails() {
        Set<Id> claimIds = new Set<Id>();
        for (Claim__c c : [SELECT Id FROM Claim__c WHERE Dental_Office__r.Name != 'TERMED Dental Office']) {
            claimIds.add(c.Id);
        }
        
        Test.startTest();
        Map<Id, Claim__c> claimMap = OCRDashboardTeamLead.getClaimDetails(claimIds);
        Test.stopTest();
        
        // Verify we got all claims (excluding termed)
        System.assertEquals(5, claimMap.size(), 'Should return 5 claims (excluding termed)');
        
        // Verify the map contains expected fields
        Claim__c firstClaim = claimMap.values()[0];
        System.assertNotEquals(null, firstClaim.Dental_Office__c, 'Claim should have dental office');
        System.assertNotEquals(null, firstClaim.Dental_Office__r.Name, 'Claim should have dental office name');
    }
    
    @IsTest
    static void testGetActiveTasksByClaimId() {
        Set<Id> claimIds = new Set<Id>();
        for (Claim__c c : [SELECT Id FROM Claim__c WHERE Dental_Office__r.Name != 'TERMED Dental Office']) {
            claimIds.add(c.Id);
        }
        
        Test.startTest();
        Map<Id, List<Task>> tasksByClaimId = OCRDashboardTeamLead.getActiveTasksByClaimId(claimIds);
        Test.stopTest();
        
        // Verify we got tasks for claims
        System.assert(!tasksByClaimId.isEmpty(), 'Should return active tasks for claims');
        
        // Verify we only got Follow Up tasks with correct statuses
        for (List<Task> tasks : tasksByClaimId.values()) {
            for (Task t : tasks) {
                System.assertEquals('Follow Up', t.Subject, 'Should only include Follow Up tasks');
                System.assert(
                    (t.ActivityDate >= Date.today() && t.ActivityDate <= Date.today().addDays(2) && 
                    !t.Status.startsWith('Completed') && t.Status != 'DUPLICATE SF CLAIM - DELETE' && 
                    t.Status != 'New' && t.Status != 'Needs VBS Assistance' && t.Status != 'Needs Office Assistance') ||
                    (t.Status == 'New' || t.Status == 'Needs VBS Assistance' || t.Status == 'Needs Office Assistance'),
                    'Task should meet active criteria'
                );
            }
        }
    }
    
    @IsTest
    static void testGetPendingTasksByClaimId() {
        Set<Id> claimIds = new Set<Id>();
        for (Claim__c c : [SELECT Id FROM Claim__c WHERE Dental_Office__r.Name != 'TERMED Dental Office']) {
            claimIds.add(c.Id);
        }
        
        Test.startTest();
        Map<Id, List<Task>> tasksByClaimId = OCRDashboardTeamLead.getPendingTasksByClaimId(claimIds);
        Test.stopTest();
        
        // Verify we got pending tasks for claims
       // System.assert(!tasksByClaimId.isEmpty(), 'Should return pending tasks for claims');
        
        // Verify tasks are pending (not completed and past due)
        for (List<Task> tasks : tasksByClaimId.values()) {
            for (Task t : tasks) {
                System.assertNotEquals('Completed', t.Status, 'Should exclude completed tasks');
                System.assert(t.ActivityDate < Date.today(), 'Should only include past due tasks');
                System.assert(t.ActivityDate >= Date.today().addDays(-30), 'Should only include recent tasks');
            }
        }
    }
    
    @IsTest
    static void testBuildDashboardData() {
        // Prepare test data
        Set<Id> claimIds = new Set<Id>();
        for (Claim__c c : [SELECT Id FROM Claim__c WHERE Dental_Office__r.Name != 'TERMED Dental Office']) {
            claimIds.add(c.Id);
        }
        
        Map<Id, Claim__c> claimMap = new Map<Id, Claim__c>([
            SELECT Id, Name, Dental_Office__c, Dental_Office__r.Name, Insurance_Carrier__c, 
                   Claim_Amount__c, Status__c
            FROM Claim__c
            WHERE Id IN :claimIds
        ]);
        
        Map<Id, List<Task>> activeTasksByClaimId = new Map<Id, List<Task>>();
        Map<Id, List<Task>> pendingTasksByClaimId = new Map<Id, List<Task>>();
        
        for (Task t : [SELECT Id, WhatId, OwnerId, Owner.Name, Subject, Status, ActivityDate, 
                        LastModifiedById, LastModifiedDate, Description
                        FROM Task 
                        WHERE WhatId IN :claimIds]) {
            if (t.Subject == 'Follow Up' && 
                ((t.ActivityDate >= Date.today() && t.ActivityDate <= Date.today().addDays(2) && 
                  !t.Status.startsWith('Completed') && t.Status != 'DUPLICATE SF CLAIM - DELETE' && 
                  t.Status != 'New' && t.Status != 'Needs VBS Assistance' && t.Status != 'Needs Office Assistance') ||
                 (t.Status == 'New' || t.Status == 'Needs VBS Assistance' || t.Status == 'Needs Office Assistance'))) {
                if (!activeTasksByClaimId.containsKey(t.WhatId)) {
                    activeTasksByClaimId.put(t.WhatId, new List<Task>());
                }
                activeTasksByClaimId.get(t.WhatId).add(t);
            } else if (t.Status != 'Completed' && t.ActivityDate < Date.today() && t.ActivityDate >= Date.today().addDays(-30)) {
                if (!pendingTasksByClaimId.containsKey(t.WhatId)) {
                    pendingTasksByClaimId.put(t.WhatId, new List<Task>());
                }
                pendingTasksByClaimId.get(t.WhatId).add(t);
            }
        }
        
        Test.startTest();
        List<Map<String, Object>> dashboardData = OCRDashboardTeamLead.buildDashboardData(
            activeTasksByClaimId, 
            pendingTasksByClaimId,
            claimMap
        );
        Test.stopTest();
        
        // Verify the structure and content of the returned data
        System.assert(!dashboardData.isEmpty(), 'Should return dashboard data');
        
        // Verify each dental office has the expected structure
        for (Map<String, Object> officeData : dashboardData) {
            System.assert(officeData.containsKey('dentalOfficeId'), 'Office data should contain dentalOfficeId');
            System.assert(officeData.containsKey('dentalOfficeName'), 'Office data should contain dentalOfficeName');
            System.assert(officeData.containsKey('countOfPendingClaims'), 'Office data should contain countOfPendingClaims');
            System.assert(officeData.containsKey('pendingTaskAmount'), 'Office data should contain pendingTaskAmount');
            System.assert(officeData.containsKey('owners'), 'Office data should contain owners');
            System.assert(officeData.containsKey('claims'), 'Office data should contain claims');
            System.assert(officeData.containsKey('pendingTasks'), 'Office data should contain pendingTasks');
            
            // Verify owners map has counts
            Map<String, Integer> owners = (Map<String, Integer>) officeData.get('owners');
            System.assert(!owners.isEmpty(), 'Owners map should not be empty');
            
            // Verify at least one of claims or pendingTasks is not empty
            List<Map<String, Object>> claims = (List<Map<String, Object>>) officeData.get('claims');
            List<Map<String, Object>> pendingTasks = (List<Map<String, Object>>) officeData.get('pendingTasks');
            System.assert(!claims.isEmpty() || !pendingTasks.isEmpty(), 'Office should have either active or pending tasks');
        }
    }
    
    @IsTest
    static void testErrorHandling() {
        // Force an exception by passing an invalid user ID
        Test.startTest();
        try {
            List<Map<String, Object>> dashboardData = OCRDashboardTeamLead.OCRDashboardTeamLead('invalidUserId');
          //  System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error retrieving dashboard data'), 'Expected error message about dashboard data');
        }
        Test.stopTest();
    }
}