public class AccountSharingController {
    @AuraEnabled
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }
    @AuraEnabled
    public static Map<String, Object> getAccounts(Id userId) {
        Map<String, Object> result = new Map<String, Object>();
        
        List<AccountShare> accountShares = [SELECT AccountId FROM AccountShare WHERE UserOrGroupId = :userId];
        Set<Id> sharedAccountIds = new Set<Id>();
        for (AccountShare share : accountShares) {
            sharedAccountIds.add(share.AccountId);
        }
        
        List<Account> allAccounts = [SELECT Id, Name FROM Account WHERE Id NOT IN :sharedAccountIds ORDER BY Name];
        List<Account> removeAccount = [SELECT Id, Name FROM Account WHERE Id  IN :sharedAccountIds ORDER BY Name];

        
        result.put('allAccounts', allAccounts);
        result.put('removeAccount', removeAccount);

    
        return result;
    }
    @AuraEnabled
    public static void shareAccountWithUser(List<Id> accountIds, Id userId) {
        try {
            List<AccountShare> accountShares = new List<AccountShare>();
            for (Id accountId : accountIds) {
                AccountShare accountShare = new AccountShare();
                accountShare.AccountId = accountId;
                accountShare.UserOrGroupId = userId;
                accountShare.AccountAccessLevel = 'Edit';
                accountShare.OpportunityAccessLevel = 'None';
                accountShare.RowCause = Schema.AccountShare.RowCause.Manual;
                accountShares.add(accountShare);
            }
            // Insert the AccountShare records
            insert accountShares;
        } catch (Exception e) {
            throw new AuraHandledException('Error sharing accounts: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void removeAccount(List<Id> accountIds, Id userId ) {
        try {
            List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :userId And accountId =:accountIds];
            system.debug('accountShares >> '+accountShares );
            delete accountShares;
        } catch (Exception e) {
            throw new AuraHandledException('Error removing account sharing: ' + e.getMessage());
        }
    }
}
