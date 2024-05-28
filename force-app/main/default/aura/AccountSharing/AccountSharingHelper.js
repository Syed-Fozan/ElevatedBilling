({
    fetchUsers: function(component) {
        var action = component.get("c.getUsers");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.users", response.getReturnValue());
            } else {
                console.error('Error fetching users:', response.getError());
            }
        });

        $A.enqueueAction(action);
    },

    fetchAccounts: function(component, userId) {
        var action = component.get("c.getAccounts");
        action.setParams({ 
            userId: userId 
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var accounts = result.allAccounts.map(function(account) {
                    return {
                        label: account.Name,
                        value: account.Id
                    };
                });
                var selectedAccountIds = result.sharedAccountIds;
                var selectedShareId = result.shareIds;

                component.set("v.accounts", accounts);
                component.set("v.selectedAccountIds", selectedAccountIds);
                component.set("v.shareIds", selectedShareId);

                component.set('v.disabledRemoveShareAccount', selectedAccountIds.length === 0);
            } else {
                console.error('Error fetching accounts:', response.getError());
            }
        });

        $A.enqueueAction(action);
    }
})
