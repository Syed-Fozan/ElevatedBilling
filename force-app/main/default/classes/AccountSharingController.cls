public class AccountSharingController {
    @AuraEnabled
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }

    @AuraEnabled
    public static Map<String, Object> getAccounts(Id userId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get the list of accounts shared with the given user
        List<AccountShare> accountShares = [SELECT id, AccountId FROM AccountShare WHERE UserOrGroupId = :userId];
        List<Id> sharedAccountIds = new List<Id>();
        List<Id> shareIds = new List<Id>();
        for (AccountShare share : accountShares) {
            sharedAccountIds.add(share.AccountId);
            shareIds.add(share.Id);
        }
        
        // Filter accounts based on some criteria
        // For example, you could filter accounts based on the user's profile, role, or other criteria
        // Replace the following line with your filtering logic
        List<Account> allAccounts = [SELECT Id, Name FROM Account ORDER BY Name];
        
        result.put('allAccounts', allAccounts);
        result.put('sharedAccountIds', sharedAccountIds);
        result.put('shareIds', shareIds);

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
    public static void removeAccount(List<Id> accountIds, Id userId, List<Id> shareIds) {
        try {
            List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE Id IN :shareIds AND UserOrGroupId = :userId And accountId =:accountIds];
            system.debug('accountShares >> '+accountShares );
            delete accountShares;
        } catch (Exception e) {
            throw new AuraHandledException('Error removing account sharing: ' + e.getMessage());
        }
    }
}
