({
    doInit: function(component, event, helper) {
        helper.fetchUsers(component);
    },

    handleUserChange: function(component, event, helper) {
        var selectedUserId = component.get("v.selectedUserId");
        if (selectedUserId !== '') {
            helper.fetchAccounts(component, selectedUserId);
        } else {
            component.set("v.accounts", []);
            component.set("v.selectedAccountIds", []);
            component.set('v.disabledShareAccount', true);
            component.set('v.disabledRemoveShareAccount', true);
        }
    },

    handleAccountSelection: function(component, event, helper) {
        var selectedAccountIds = component.get("v.selectedAccountIds");
        var removeAccountIds = component.get("v.selectedAccountIdsRemove");
    
        // Check if the selectedAccountIds is an array and has elements
        var isShareActive = Array.isArray(selectedAccountIds) && selectedAccountIds.length > 0;
        component.set('v.disabledShareAccount', !isShareActive);
    
        // Check if the removeAccountIds is an array and has elements
        var isRemoveActive = Array.isArray(removeAccountIds) && removeAccountIds.length > 0;
        component.set('v.disabledRemoveShareAccount', !isRemoveActive);
    },
    

    shareAccount: function(component, event, helper) {
        var selectedUserId = component.get("v.selectedUserId");
        var selectedAccountIds = component.get("v.selectedAccountIds");

        var action = component.get("c.shareAccountWithUser");
        action.setParams({
            accountIds: selectedAccountIds,
            userId: selectedUserId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.find('notificationsLib').showToast({
                    "variant": "success",
                    "title": "Success",
                    "message": "Dental Office shared successfully!"
                });
                // Refetch the accounts to update the list
                helper.fetchAccounts(component, selectedUserId);
            } else {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.find('notificationsLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Error: " + errors[0].message
                    });
                } else {
                    component.find('notificationsLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Unknown error"
                    });
                }
            }
        });

        $A.enqueueAction(action);
    },

    filterAccounts: function(component, event, helper) {
        debugger;
        var filterKey = event.getSource().get("v.value").toLowerCase();
        var allAccounts = component.get("v.accounts") || [];
    
        if (filterKey === '') {
            // Reset to original full list of accounts if filter is cleared
            helper.fetchAccounts(component, component.get("v.selectedUserId"));
        } else {
            // Apply filter
            var filteredAccounts = allAccounts.filter(function(account) {
                return account.label.toLowerCase().includes(filterKey);
            });
            component.set("v.accounts", filteredAccounts);
        }
    },

    filterRemoveAccounts: function(component, event, helper) {
        var filterKey = event.getSource().get("v.value").toLowerCase();
        var allRemoveAccounts = component.get("v.removeAccountIds") || [];
    
        if (filterKey === '') {
            // Reset to original full list of accounts to be removed if filter is cleared
            helper.fetchAccounts(component, component.get("v.selectedUserId")); // Assumes fetching also repopulates the remove list
        } else {
            // Apply filter
            var filteredRemoveAccounts = allRemoveAccounts.filter(function(account) {
                return account.label.toLowerCase().includes(filterKey);
            });
            component.set("v.removeAccountIds", filteredRemoveAccounts);
        }
    },

    removeAccountSharing: function(component, event, helper) {
        var selectedUserId = component.get("v.selectedUserId");
        var selectedAccountIds = component.get("v.selectedAccountIdsRemove");
        // var shareIds = component.get("v.shareIds");

        var action = component.get("c.removeAccount");
        action.setParams({
            accountIds: selectedAccountIds,
            userId: selectedUserId
            // shareIds: shareIds
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.find('notificationsLib').showToast({
                    "variant": "success",
                    "title": "Success",
                    "message": "Dental Office removed successfully!"
                });
                // Refetch the accounts to update the list
                helper.fetchAccounts(component, selectedUserId);
            } else {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.find('notificationsLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Error: " + errors[0].message
                    });
                } else {
                    component.find('notificationsLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Unknown error"
                    });
                }
            }
        });

        $A.enqueueAction(action);
    }
})
