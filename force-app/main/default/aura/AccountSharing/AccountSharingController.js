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
        if (selectedAccountIds.length > 0) {
            component.set('v.disabledShareAccount', false);
            component.set('v.disabledRemoveShareAccount', false);
        } else {
            component.set('v.disabledShareAccount', true);
            component.set('v.disabledRemoveShareAccount', true);
        }
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

    removeAccountSharing: function(component, event, helper) {
        var selectedUserId = component.get("v.selectedUserId");
        var selectedAccountIds = component.get("v.selectedAccountIds");
        var shareIds = component.get("v.shareIds");

        var action = component.get("c.removeAccount");
        action.setParams({
            accountIds: selectedAccountIds,
            userId: selectedUserId,
            shareIds: shareIds
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
