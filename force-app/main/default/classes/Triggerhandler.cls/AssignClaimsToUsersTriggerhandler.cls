public class AssignClaimsToUsersTriggerhandler {
   public static void assignClaims(List<Claim__c> claimList) {
     Map<Id, List<Id>> dentalOfficeUsersMap = new Map<Id, List<Id>>();
     Map<Id, Integer> dentalOfficeClaimCount = new Map<Id, Integer>();
 
     Set<Id> dentalOfficeIds = new Set<Id>();
     for (Claim__c claim : claimList) {
       if (claim.Dental_Office__c != null) {
         dentalOfficeIds.add(claim.Dental_Office__c);
       }
     }
 
     if (!dentalOfficeIds.isEmpty()) {
       List<Account> dentalOffices = [
         SELECT Id, User_1__c, User_2__c, User_3__c, User_4__c
         FROM Account
         WHERE Id IN :dentalOfficeIds
       ];
 
       for (Account office : dentalOffices) {
         List<Id> userList = new List<Id>();
 
         if (office.User_1__c != null)
           userList.add(office.User_1__c);
         if (office.User_2__c != null)
           userList.add(office.User_2__c);
         if (office.User_3__c != null)
           userList.add(office.User_3__c);
         if (office.User_4__c != null)
           userList.add(office.User_4__c);
 
         if (!userList.isEmpty()) {
           dentalOfficeUsersMap.put(office.Id, userList);
           dentalOfficeClaimCount.put(office.Id, 0);
         }
       }
     }
     assignUsersToClaims(claimList, dentalOfficeUsersMap, dentalOfficeClaimCount);
   }
 
   private static void assignUsersToClaims(List<Claim__c> claimList,Map<Id, List<Id>> dentalOfficeUsersMap,Map<Id, Integer> dentalOfficeClaimCount) {
     for (Claim__c claim : claimList) {
       if (
         claim.Dental_Office__c != null &&
         dentalOfficeUsersMap.containsKey(claim.Dental_Office__c)
       ) {
         List<Id> users = dentalOfficeUsersMap.get(claim.Dental_Office__c);
 
         if (!users.isEmpty()) {
           Integer claimCount = dentalOfficeClaimCount.get(
             claim.Dental_Office__c
           );
           Integer userIndex = Math.mod(claimCount, users.size());
 
           claim.Assigned_Claim_User__c = users[userIndex];
           dentalOfficeClaimCount.put(claim.Dental_Office__c, claimCount + 1);
         }
       }
     }
   }
 
   public static void createFollowUpTasks(List<Claim__c> claimList) {
     List<Task> taskList = new List<Task>();
     for (Claim__c claim : claimList) {
       if (claim.Assigned_Claim_User__c != null) {
         Task newTask = new Task(
           Subject = 'Follow up',
           WhatId = claim.Id,
           ActivityDate = Date.today() + 20,
           OwnerId = claim.Assigned_Claim_User__c,
           Status = 'New',
           Priority = 'Normal'
         );
         taskList.add(newTask);
       }
     }
     if (!taskList.isEmpty()) {
       insert taskList;
     }
   }
 }
 