public class CreateUserAndAssignAccountController {
    @AuraEnabled
    public static PicklistValuesWrapper getPicklistValues() {
        PicklistValuesWrapper picklistValues = new PicklistValuesWrapper();

        picklistValues.timeZoneOptions = populateTimeZoneOptions();
        picklistValues.localeOptions = populateLocaleOptions();
        picklistValues.emailEncodingOptions = populateEmailEncodingOptions();
        picklistValues.languageOptions = populateLanguageOptions();
        picklistValues.profileOptions = populateProfileOptions();
        picklistValues.roleOptions = populateRoleOptions();
        picklistValues.accountOptions = populateAccountOptions();

        return picklistValues;
    }

    private static List<SelectOption> populateTimeZoneOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('America/Los_Angeles', 'America/Los_Angeles'));
        options.add(new SelectOption('America/New_York', 'America/New_York'));
        options.add(new SelectOption('Europe/London', 'Europe/London'));
        options.add(new SelectOption('Asia/Kolkata', 'Asia/Kolkata'));
        options.add(new SelectOption('Asia/Tokyo', 'Asia/Tokyo'));
        return options;
    }

    private static List<SelectOption> populateLocaleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('en_US', 'English (United States)'));
        options.add(new SelectOption('fr_FR', 'French (France)'));
        options.add(new SelectOption('de_DE', 'German (Germany)'));
        options.add(new SelectOption('es_ES', 'Spanish (Spain)'));
        options.add(new SelectOption('zh_CN', 'Chinese (China)'));
        return options;
    }

    private static List<SelectOption> populateEmailEncodingOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('UTF-8', 'UTF-8'));
        options.add(new SelectOption('ISO-8859-1', 'ISO-8859-1'));
        return options;
    }

    private static List<SelectOption> populateLanguageOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('en_US', 'English (United States)'));
        options.add(new SelectOption('fr_FR', 'French (France)'));
        options.add(new SelectOption('de_DE', 'German (Germany)'));
        options.add(new SelectOption('es_ES', 'Spanish (Spain)'));
        options.add(new SelectOption('zh_CN', 'Chinese (China)'));
        return options;
    }

    private static List<SelectOption> populateProfileOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for (Profile prof : [SELECT Id, Name FROM Profile]) {
            options.add(new SelectOption(prof.Id, prof.Name));
        }
        return options;
    }

    private static List<SelectOption> populateRoleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for (UserRole role : [SELECT Id, Name FROM UserRole]) {
            options.add(new SelectOption(role.Id, role.Name));
        }
        return options;
    }

    private static List<SelectOption> populateAccountOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for (Account acc : [SELECT Id, Name FROM Account]) {
            options.add(new SelectOption(acc.Id, acc.Name));
        }
        return options;
    }

    @AuraEnabled
    public static Map<String, Object> createUserAndAssignAccount(String username, String email, String firstName, String lastName, String password, String alias, String timeZone, String locale, String emailEncoding, String language, String selectedProfileId, String selectedRoleId, List<String> selectedAccountIds) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            User newUser = new User();
            newUser.Username = username;
            newUser.Email = email;
            newUser.FirstName = firstName;
            newUser.LastName = lastName;
            newUser.Alias = alias;
            newUser.TimeZoneSidKey = timeZone;
            newUser.LocaleSidKey = locale;
            newUser.EmailEncodingKey = emailEncoding;
            newUser.LanguageLocaleKey = language;
            newUser.ProfileId = selectedProfileId;
            newUser.UserRoleId = selectedRoleId;
            insert newUser;

            // Grant access to selected accounts
            List<AccountShare> shares = new List<AccountShare>();
            for (String accountId : selectedAccountIds) {
                AccountShare share = new AccountShare();
                share.UserOrGroupId = newUser.Id;
                share.AccountId = accountId;
                share.AccountAccessLevel = 'Read';
                share.OpportunityAccessLevel = 'None';
                shares.add(share);
            }
            insert shares;

            response.put('success', true);
            response.put('message', 'User created successfully and accounts assigned.');
        } catch (Exception e) {
            response.put('success', false);
            response.put('message', 'Error creating user: ' + e.getMessage());
        }
        return response;
    }
}
