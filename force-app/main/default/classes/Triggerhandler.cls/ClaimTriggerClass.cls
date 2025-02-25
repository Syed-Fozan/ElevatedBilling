public class ClaimTriggerClass {

  public void updateDueDate(list<Claim__c> newValue, Map<Id, Claim__c> oldValue) {
    for (Claim__c newclaim : newValue) {
      if (newclaim.Status__c != oldValue.get(newclaim.id).Status__c) {
        if (newclaim.Status__c == 'Resubmitted' || newclaim.Status__c == 'Processing' ) {
          newclaim.Due_Date__c = System.today() + 15;
        }
        else if (newclaim.Status__c == 'Needs Office Assistance' ||newclaim.Status__c == 'Paid to Member' || newclaim.Status__c == 'Paid but Not Posted' || newclaim.Status__c == 'Needs VBS Assistance' ){
            newclaim.Due_Date__c = System.today() + 7;
        }
        else if (newclaim.Status__c == 'Ready for NOS' ){
            newclaim.Due_Date__c = System.today() + 3;
        }
        else if (newclaim.Status__c == 'In Appeals' ){
            newclaim.Due_Date__c = System.today() + 25;
        }
        else if (newclaim.Status__c == 'New' ){
            newclaim.Due_Date__c = System.today() + 20;
        }
        else if (newclaim.Status__c == 'Ortho Claim' ){
            newclaim.Due_Date__c = System.today() + 90;
        }
      }
    }
  }
}