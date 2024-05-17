public class CreateUserAndAssignAccountController {
    public String username { get; set; }
    public String email { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String password { get; set; }
    public String alias { get; set; }
    public String timeZone { get; set; }
    public String locale { get; set; }
    public String emailEncoding { get; set; }
    public String language { get; set; }
    public List<Id> selectedAccountIds { get; set; }
    public Id selectedProfileId { get; set; }
    public Id selectedRoleId { get; set; }

    public User newUser { get; set; }

    public List<SelectOption> accountOptions { get; set; }
    public List<SelectOption> timeZoneOptions { get; set; }
    public List<SelectOption> localeOptions { get; set; }
    public List<SelectOption> emailEncodingOptions { get; set; }
    public List<SelectOption> languageOptions { get; set; }
    public List<SelectOption> profileOptions { get; set; }
    public List<SelectOption> roleOptions { get; set; }

    public CreateUserAndAssignAccountController() {
        newUser = new User(); // Initialize new User object
        accountOptions = new List<SelectOption>();
        for (Account acc : [SELECT Id, Name FROM Account]) {
            accountOptions.add(new SelectOption(acc.Id, acc.Name));
        }

        timeZoneOptions = new List<SelectOption>();
        populateTimeZoneOptions();

        localeOptions = new List<SelectOption>();
        populateLocaleOptions();

        emailEncodingOptions = new List<SelectOption>();
        populateEmailEncodingOptions();

        languageOptions = new List<SelectOption>();
        populateLanguageOptions();

        profileOptions = new List<SelectOption>();
        populateProfileOptions();

        roleOptions = new List<SelectOption>();
        populateRoleOptions();

        setDefaultValues();
    }

    private void populateTimeZoneOptions() {
        // Populate with a few sample time zones
        timeZoneOptions.add(new SelectOption('America/Los_Angeles', 'America/Los_Angeles'));
        timeZoneOptions.add(new SelectOption('America/New_York', 'America/New_York'));
        timeZoneOptions.add(new SelectOption('Europe/London', 'Europe/London'));
        timeZoneOptions.add(new SelectOption('Asia/Kolkata', 'Asia/Kolkata'));
        timeZoneOptions.add(new SelectOption('Asia/Tokyo', 'Asia/Tokyo'));
    }

    private void populateLocaleOptions() {
        // Populate with a few sample locales
        localeOptions.add(new SelectOption('en_US', 'English (United States)'));
        localeOptions.add(new SelectOption('fr_FR', 'French (France)'));
        localeOptions.add(new SelectOption('de_DE', 'German (Germany)'));
        localeOptions.add(new SelectOption('es_ES', 'Spanish (Spain)'));
        localeOptions.add(new SelectOption('zh_CN', 'Chinese (China)'));
    }

    private void populateEmailEncodingOptions() {
        // Populate with a few sample email encodings
        emailEncodingOptions.add(new SelectOption('UTF-8', 'UTF-8'));
        emailEncodingOptions.add(new SelectOption('ISO-8859-1', 'ISO-8859-1'));
    }

    private void populateLanguageOptions() {
        // Populate with a few sample languages
        languageOptions.add(new SelectOption('en_US', 'English (United States)'));
        languageOptions.add(new SelectOption('fr_FR', 'French (France)'));
        languageOptions.add(new SelectOption('de_DE', 'German (Germany)'));
        languageOptions.add(new SelectOption('es_ES', 'Spanish (Spain)'));
        languageOptions.add(new SelectOption('zh_CN', 'Chinese (China)'));
    }

    private void populateProfileOptions() {
        // Query all profiles
        for (Profile prof : [SELECT Id, Name FROM Profile]) {
            profileOptions.add(new SelectOption(prof.Id, prof.Name));
        }
    }

    private void populateRoleOptions() {
        // Query all roles
        for (UserRole role : [SELECT Id, Name FROM UserRole]) {
            roleOptions.add(new SelectOption(role.Id, role.Name));
        }
    }

    private void setDefaultValues() {
        User currentUser = [SELECT Alias, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey 
                            FROM User WHERE Id = :UserInfo.getUserId()];
        alias = currentUser.Alias != null ? currentUser.Alias : 'alias';
        timeZone = currentUser.TimeZoneSidKey != null ? currentUser.TimeZoneSidKey : 'America/Los_Angeles';
        locale = currentUser.LocaleSidKey != null ? currentUser.LocaleSidKey : 'en_US';
        emailEncoding = currentUser.EmailEncodingKey != null ? currentUser.EmailEncodingKey : 'UTF-8';
        language = currentUser.LanguageLocaleKey != null ? currentUser.LanguageLocaleKey : 'en_US';
    }

    public void createUserAndAssignAccount() {
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

        // Use future method to grant access to the selected Account records
        if (selectedAccountIds != null && !selectedAccountIds.isEmpty()) {
            CreateUserAndAssignAccountController.addAccountShares(newUser.Id, selectedAccountIds);
        }
    }

    @future
    public static void addAccountShares(Id userId, List<Id> accountIds) {
        List<AccountShare> shares = new List<AccountShare>();
        for (Id accountId : accountIds) {
            AccountShare share = new AccountShare();
            share.UserOrGroupId = userId;
            share.AccountId = accountId;
            share.AccountAccessLevel = 'Read'; // Adjust access level as needed
            share.OpportunityAccessLevel = 'None'; // Adjust access level as needed
            shares.add(share);
        }
        insert shares;
    }
}
