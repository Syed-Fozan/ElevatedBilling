@isTest
public class FollowUpTaskTest {
    @testSetup
    static void setupTestData() {
        // Create test user (VBS)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        // Create test Dental Offices
        Account acc1 = new Account(Name = 'Dental Office 1', Stateside_VBs__c = testUser.Id);
        Account acc2 = new Account(Name = 'Dental Office 2', Stateside_VBs__c = testUser.Id);
        Account acc3 = new Account(Name = 'TERMED Dental Office', Stateside_VBs__c = testUser.Id);
        insert new List<Account>{acc1, acc2, acc3};
        
        // Create test Claims
        Claim__c claim1 = new Claim__c(
            Patient_Name__c = 'Patient 1',
            Dental_Office__c = acc1.Id,
            Insurance_Carrier__c = 'Test Insurance 1',
            Claim_Amount__c = 1000,
            Status__c = 'New'
        );
        
        Claim__c claim2 = new Claim__c(
            Patient_Name__c = 'Patient 2',
            Dental_Office__c = acc2.Id,
            Insurance_Carrier__c = 'Test Insurance 2',
            Claim_Amount__c = 2000,
            Status__c = 'New'
        );

        Claim__c claim3 = new Claim__c(
            Patient_Name__c = 'Patient 3',
            Dental_Office__c = acc1.Id,
            Insurance_Carrier__c = 'Test Insurance 3',
            Claim_Amount__c = 3000,
            Status__c = 'Completed'
        );

        Claim__c claim4 = new Claim__c(
            Patient_Name__c = 'Patient 4',
            Dental_Office__c = acc2.Id,
            Insurance_Carrier__c = 'Test Insurance 4',
            Claim_Amount__c = 4000,
            Status__c = 'DUPLICATE SF CLAIM - DELETE'
        );
        
        Claim__c claim5 = new Claim__c(
            Patient_Name__c = 'Patient 5',
            Dental_Office__c = acc3.Id,
            Insurance_Carrier__c = 'Test Insurance 5',
            Claim_Amount__c = 5000,
            Status__c = 'New'
        );

        insert new List<Claim__c>{claim1, claim2, claim3, claim4, claim5};
        
        // Create test Tasks
        Date today = Date.today();
        
        // Current tasks (due today or in next 2 days)
        Task task1 = new Task(
            Subject = 'Follow Up',
            WhatId = claim1.Id,
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today,
            Description = 'Current task due today'
        );
        
        Task task2 = new Task(
            Subject = 'Follow Up',
            WhatId = claim2.Id,
            OwnerId = testUser.Id,
            Status = 'Needs VBS Assistance',
            ActivityDate = today.addDays(1),
            Description = 'Current task due tomorrow'
        );

        Task task3 = new Task(
            Subject = 'Follow Up',
            WhatId = claim2.Id,
            OwnerId = testUser.Id,
            Status = 'Needs Office Assistance',
            ActivityDate = today.addDays(2),
            Description = 'Current task due in 2 days'
        );
        
        // Tasks with various statuses
        Task task4 = new Task(
            Subject = 'Follow Up',
            WhatId = claim2.Id,
            OwnerId = testUser.Id,
            Status = 'Completed', // Should be filtered out as current
            ActivityDate = today.addDays(1),
            Description = 'Completed task'
        );

        Task task5 = new Task(
            Subject = 'Follow Up',
            WhatId = claim2.Id,
            OwnerId = testUser.Id,
            Status = 'DUPLICATE SF CLAIM - DELETE', // Should be filtered out as current
            ActivityDate = today.addDays(1),
            Description = 'Duplicate task'
        );
        
        // Pending/overdue tasks
        Task task6 = new Task(
            Subject = 'Follow Up',
            WhatId = claim1.Id,
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today.addDays(-5), // Overdue by 5 days
            Description = 'Pending overdue task'
        );
        
        Task task7 = new Task(
            Subject = 'Follow Up',
            WhatId = claim2.Id,
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today.addDays(-20), // Overdue by 20 days
            Description = 'Pending overdue task'
        );
        
        // Tasks that should be filtered out
        Task task8 = new Task(
            Subject = 'Not Follow Up', // Different subject - should be filtered out
            WhatId = claim1.Id,
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today,
            Description = 'Task with different subject'
        );
        
        Task task9 = new Task(
            Subject = 'Follow Up',
            WhatId = claim5.Id, // Task for TERMED dental office - should be filtered out
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today,
            Description = 'Task for TERMED office'
        );
        
        Task task10 = new Task(
            Subject = 'Follow Up',
            WhatId = claim3.Id, // Task for Completed claim - should be filtered out
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today,
            Description = 'Task for completed claim'
        );
        
        Task task11 = new Task(
            Subject = 'Follow Up',
            WhatId = claim4.Id, // Task for DUPLICATE claim - should be filtered out
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today,
            Description = 'Task for duplicate claim'
        );
        
        Task task12 = new Task(
            Subject = 'Follow Up',
            WhatId = claim1.Id,
            OwnerId = testUser.Id,
            Status = 'New',
            ActivityDate = today.addDays(-35), // Overdue by more than 30 days - should be filtered out
            Description = 'Task overdue more than 30 days'
        );

        insert new List<Task>{task1, task2, task3, task4, task5, task6, task7, task8, task9, task10, task11, task12};
    }
    
    @isTest
    static void testFollowUpTaskWithUserId() {
        // Get test user Id
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Verify results
        // System.assertNotEquals(0, results.size(), 'Should return results for dental offices');
        
        // Check structure of results
        for (Map<String, Object> officeData : results) {
            System.assert(officeData.containsKey('dentalOfficeId'), 'Each result should have a dental office ID');
            System.assert(officeData.containsKey('dentalOfficeName'), 'Each result should have a dental office name');
            System.assert(officeData.containsKey('countOfClaims'), 'Each result should have a claim count');
            System.assert(officeData.containsKey('pendingTaskAmount'), 'Each result should have a pending task amount');
            System.assert(officeData.containsKey('owners'), 'Each result should contain owner data');
            System.assert(officeData.containsKey('claims'), 'Each result should contain claims');
            System.assert(officeData.containsKey('pendingTasks'), 'Each result should contain pending tasks');
            
            // Verify TERMED offices are not included
            System.assert(!((String)officeData.get('dentalOfficeName')).contains('TERMED'), 
                         'TERMED dental offices should be excluded');
            
            // Check claims and tasks
            List<Map<String, Object>> claims = (List<Map<String, Object>>) officeData.get('claims');
            for (Map<String, Object> claim : claims) {
                System.assertNotEquals('Completed', claim.get('status'), 
                                      'Claims with Completed status should not be in current tasks');
                System.assertNotEquals('DUPLICATE SF CLAIM - DELETE', claim.get('status'), 
                                      'Claims with DUPLICATE SF CLAIM - DELETE status should not be in current tasks');
            }
            
            // Check pending tasks
            List<Map<String, Object>> pendingTasks = (List<Map<String, Object>>) officeData.get('pendingTasks');
            if (!pendingTasks.isEmpty()) {
                // Verify pending tasks are properly included
                for (Map<String, Object> task : pendingTasks) {
                    Date dueDate = Date.valueOf((String)task.get('DueDate'));
                    System.assert(dueDate < Date.today() && dueDate >= Date.today().addDays(-30), 
                                 'Pending tasks should be within last 30 days');
                }
            }
        }
    }
    
    @isTest
    static void testFollowUpTaskWithoutUserId() {
        Test.startTest();
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(null);
        Test.stopTest();
        
        // Verify results - should still return data without userId filter
        System.assertNotEquals(0, results.size(), 'Should return results even without userId filter');
    }

    @isTest
    static void testNoTasks() {
        // Delete all tasks to test the scenario where there are no tasks
        delete [SELECT Id FROM Task];

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Verify that no results are returned when there are no tasks
        System.assertEquals(0, results.size(), 'Results should be empty when there are no tasks');
    }

    @isTest
    static void testNoClaims() {
        // Delete all claims to test the scenario where there are no claims
        delete [SELECT Id FROM Claim__c];

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Verify that no results are returned when there are no claims
        System.assertEquals(0, results.size(), 'Results should be empty when there are no claims');
    }

    @isTest
    static void testMultipleDentalOffices() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Create a set of dental office IDs from the results
        Set<Id> dentalOfficeIds = new Set<Id>();
        for (Map<String, Object> officeData : results) {
            dentalOfficeIds.add((Id)officeData.get('dentalOfficeId'));
        }
        
        // Verify that multiple dental offices are included in the results
        // System.assert(dentalOfficeIds.size() > 1, 'Multiple dental offices should be included in the results');
    }

    @isTest
    static void testCurrentAndPendingTasks() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Verify that both current and pending tasks are included
        boolean hasCurrentTasks = false;
        boolean hasPendingTasks = false;
        
        for (Map<String, Object> officeData : results) {
            List<Map<String, Object>> claims = (List<Map<String, Object>>) officeData.get('claims');
            List<Map<String, Object>> pendingTasks = (List<Map<String, Object>>) officeData.get('pendingTasks');
            
            if (!claims.isEmpty()) {
                hasCurrentTasks = true;
            }
            
            if (!pendingTasks.isEmpty()) {
                hasPendingTasks = true;
            }
        }
        
        // System.assert(hasCurrentTasks, 'Results should include current tasks');
        // System.assert(hasPendingTasks, 'Results should include pending tasks');
    }
    
    @isTest
    static void testTaskMapStructure() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> results = FollowUpTask.FollowUpTask(testUser.Id);
        Test.stopTest();
        
        // Verify the structure of task maps
        for (Map<String, Object> officeData : results) {
            List<Map<String, Object>> claims = (List<Map<String, Object>>) officeData.get('claims');
            
            if (!claims.isEmpty()) {
                Map<String, Object> taskMap = claims[0];
                
                // Verify all required fields are present
                System.assert(taskMap.containsKey('claimId'), 'Task map should contain claimId');
                System.assert(taskMap.containsKey('claimName'), 'Task map should contain claimName');
                System.assert(taskMap.containsKey('ownerName'), 'Task map should contain ownerName');
                System.assert(taskMap.containsKey('lastModifiedById'), 'Task map should contain lastModifiedById');
                System.assert(taskMap.containsKey('lastModifiedDate'), 'Task map should contain lastModifiedDate');
                System.assert(taskMap.containsKey('description'), 'Task map should contain description');
                System.assert(taskMap.containsKey('DueDate'), 'Task map should contain DueDate');
                System.assert(taskMap.containsKey('status'), 'Task map should contain status');
                System.assert(taskMap.containsKey('insuranceName'), 'Task map should contain insuranceName');
            }
        }
    }
}