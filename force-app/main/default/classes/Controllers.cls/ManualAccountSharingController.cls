public class ManualAccountSharingController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account];
    }

    @AuraEnabled
    public static List<ManualShareInfo> getManualShares(String accountId) {
        List<ManualShareInfo> manualShares = new List<ManualShareInfo>();
        
        List<AccountShare> accountShares = [
            SELECT Id, Account.Name, UserOrGroupId, UserOrGroup.Name
            FROM AccountShare
            WHERE RowCause = 'Manual' AND AccountId = :accountId
        ];

        for (AccountShare share : accountShares) {
            manualShares.add(new ManualShareInfo(share.Id, share.Account.Name, share.UserOrGroup.Name));
        }
        
        return manualShares;
    }

    @AuraEnabled
    public static void removeManualShare(String shareId) {
        try {
            AccountShare share = [SELECT Id FROM AccountShare WHERE Id = :shareId LIMIT 1];
            delete share;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ManualShareInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String userName { get; set; }

        public ManualShareInfo(String id, String accountName, String userName) {
            this.id = id;
            this.accountName = accountName;
            this.userName = userName;
        }
    }
}