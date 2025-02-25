@isTest
public class AssignClaimsToUsersTriggerhandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Get Standard Profile ID
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create Users
        User user1 = new User(
            Username='fozanasif12@trcm.com', 
            Email='testuser111@test.com', 
            Alias='test11', 
            LastName='Test112', 
            IsActive=true, 
            ProfileId = standardProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US'
        );

        User user2 = new User(
            Username='fozanasif1122@trcm.com', 
            Email='testuser232@test.com', 
            Alias='test21', 
            LastName='Test221', 
            IsActive=true, 
            ProfileId = standardProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US'
        );

        insert new List<User>{ user1, user2 };

        // Create a Dental Office (Account)
        Account dentalOffice = new Account(Name = 'Dental Clinic', User_1__c = user1.Id, User_2__c = user2.Id);
        insert dentalOffice;

        // Create Claims related to the Dental Office
        List<Claim__c> claims = new List<Claim__c>{
            new Claim__c(Patient_Name__c = 'Patient 1', Dental_Office__c = dentalOffice.Id),
            new Claim__c(Patient_Name__c = 'Patient 2', Dental_Office__c = dentalOffice.Id),
            new Claim__c(Patient_Name__c = 'Patient 3', Dental_Office__c = dentalOffice.Id)
        };
        insert claims;
    }

    @isTest
    static void testAssignClaims() {
        // Retrieve claims
        List<Claim__c> claims = [SELECT Id, Dental_Office__c, Assigned_Claim_User__c FROM Claim__c];
        Test.startTest();
        AssignClaimsToUsersTriggerhandler.assignClaims(claims);
        Test.stopTest();

        // Reload claims from DB
        claims = [SELECT Id, Assigned_Claim_User__c FROM Claim__c];

        // Validate claims are assigned in a round-robin fashion
        System.assertNotEquals(claims[0].Assigned_Claim_User__c, null, 'Claim 1 should be assigned');
        System.assertNotEquals(claims[1].Assigned_Claim_User__c, null, 'Claim 2 should be assigned');
        System.assertNotEquals(claims[2].Assigned_Claim_User__c, null, 'Claim 3 should be assigned');
        System.assert(claims[0].Assigned_Claim_User__c != claims[1].Assigned_Claim_User__c, 'Users should be assigned in round-robin fashion');
    }

    @isTest
    static void testCreateFollowUpTasks() {
        // Retrieve claims and assign users
        List<Claim__c> claims = [SELECT Id, Dental_Office__c FROM Claim__c];
        AssignClaimsToUsersTriggerhandler.assignClaims(claims);
        update claims; // Ensure claims are committed with assigned users

        Test.startTest();
        AssignClaimsToUsersTriggerhandler.createFollowUpTasks(claims);
        Test.stopTest();

        // Verify tasks were created
        List<Task> tasks = [SELECT Id, WhatId, OwnerId, Subject, Status FROM Task];
        System.assertEquals(6, tasks.size(), 'Three tasks should be created');
        System.assertEquals('Follow up', tasks[0].Subject, 'Task subject should be "Follow up"');
        System.assertEquals('New', tasks[0].Status, 'Task status should be "New"');
    }

    @isTest
    static void testNoUsersForDentalOffice() {
        // Create a Dental Office without users
        Account officeWithoutUsers = new Account(Name = 'No Users Office');
        insert officeWithoutUsers;

        // Create Claims for this office
        List<Claim__c> claims = new List<Claim__c>{
            new Claim__c(Patient_Name__c = 'Patient 4', Dental_Office__c = officeWithoutUsers.Id),
            new Claim__c(Patient_Name__c = 'Patient 5', Dental_Office__c = officeWithoutUsers.Id)
        };
        insert claims;

        Test.startTest();
        AssignClaimsToUsersTriggerhandler.assignClaims(claims);
        Test.stopTest();

        // Verify claims remain unassigned
        claims = [SELECT Id, Assigned_Claim_User__c FROM Claim__c WHERE Dental_Office__c = :officeWithoutUsers.Id];
        for (Claim__c claim : claims) {
            System.assertEquals(null, claim.Assigned_Claim_User__c, 'Claims should not be assigned if no users are available');
        }
    }
}