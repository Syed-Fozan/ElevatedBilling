trigger UpdateParentEntityFieldPMT on PMT__c (before insert,before update) {
    Set<Id> accountIds = new Set<Id>();
    
    // Collect all related Account IDs
    for (PMT__c record : Trigger.new) {
        if (record.Account__c!= null) {
            accountIds.add(record.Account__c);
        }
    }
    
    // Query related Account records
    Map<Id, Account> relatedAccounts = new Map<Id, Account>([
        SELECT Id, Parent_entity__c FROM Account WHERE Id IN :accountIds
    ]);
    
    // Update CustomObject records
    for (PMT__c record : Trigger.new) {
        if (record.Account__c != null && relatedAccounts.containsKey(record.Account__c	)) {
            record.Parent_entity__c = relatedAccounts.get(record.Account__c).Parent_entity__c;
        }
    }
}