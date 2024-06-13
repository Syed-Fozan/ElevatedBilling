trigger UpdateParentEntityFieldFinancials on A_R__c (before insert, before update) {
    Set<Id> accountIds = new Set<Id>();

    // Collect all related Account IDs
    for (A_R__c record : Trigger.new) {
        if (record.Dental_Office__c	 != null) {
            accountIds.add(record.Dental_Office__c	);
        }
    }

    // Query related Account records
    Map<Id, Account> relatedAccounts = new Map<Id, Account>([
        SELECT Id, Parent_entity__c FROM Account WHERE Id IN :accountIds
    ]);

    // Update CustomObject records
    for (A_R__c record : Trigger.new) {
        if (record.Dental_Office__c != null && relatedAccounts.containsKey(record.Dental_Office__c	)) {
            record.Parent_entity__c = relatedAccounts.get(record.Dental_Office__c).Parent_entity__c;
        }
    }
}