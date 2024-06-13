@isTest
public class AccountSharingControllerTest {
    // Utility method to create test data
    private static void setupTestData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        List<User> users = new List<User>{
            new User(
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
            ),
            new User(
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
            )
        };
        insert users;

        List<Account> accounts = new List<Account>{
            new Account(Name='Test1 Account 1'),
            new Account(Name='Test2 Account 2')
        };
        insert accounts;
    }

    // Test the getUsers method
    @isTest static void testGetUsers() {
        setupTestData();
        Test.startTest();
        List<User> users = AccountSharingController.getUsers();
        Test.stopTest();

    }

    // Test the getAccounts method
    @isTest static void testGetAccounts() {
        setupTestData();
        User testUser = [SELECT Id FROM User WHERE Username='fozanasif12@trcm.com' LIMIT 1];
        Map<String, Object> accounts = AccountSharingController.getAccounts(testUser.Id);

        System.assertNotEquals(null, accounts, 'Accounts map should not be null');
        System.assert(accounts.containsKey('allAccounts'), 'Should contain allAccounts key');
        System.assert(accounts.containsKey('removeAccount'), 'Should contain removeAccount key');
    }

    // Test the shareAccountWithUser method
    @isTest static void testShareAccountWithUser() {
        setupTestData();
        User testUser = [SELECT Id FROM User WHERE Username='fozanasif12@trcm.com' LIMIT 1];
        List<Id> accountIds = new List<Id>{[SELECT Id FROM Account LIMIT 1].Id};

        Test.startTest();
        AccountSharingController.shareAccountWithUser(accountIds, testUser.Id);
        Test.stopTest();

        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :testUser.Id];
        System.assertEquals(1, shares.size(), 'Should have shared one account');
    }

    // Test the removeAccount method
    @isTest static void testRemoveAccount() {
        setupTestData();
        User testUser = [SELECT Id FROM User WHERE Username='fozanasif12@trcm.com' LIMIT 1];
        List<Id> accountIds = new List<Id>{[SELECT Id FROM Account LIMIT 1].Id};

        // First share an account
        AccountSharingController.shareAccountWithUser(accountIds, testUser.Id);

        // Then attempt to remove the share
        Test.startTest();
        AccountSharingController.removeAccount(accountIds, testUser.Id);
        Test.stopTest();

        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :testUser.Id];
        System.assertEquals(0, shares.size(), 'Should have removed shared accounts');
    }
}