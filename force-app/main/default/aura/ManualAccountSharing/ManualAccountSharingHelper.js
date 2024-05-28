({
    fetchAccounts: function(component) {
        var action = component.get("c.getAccounts");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var accounts = response.getReturnValue();
                var accountOptions = accounts.map(function(account) {
                    return { label: account.Name, value: account.Id };
                });
                component.set("v.accounts", accountOptions);
            } else {
                console.error(response.getError());
                this.showToast("Error", "Error fetching accounts", "error");
            }
        });

        $A.enqueueAction(action);
    },

    fetchManualShares: function(component, accountId) {
        var action = component.get("c.getManualShares");
        action.setParams({ 
            accountId: accountId 
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var manualShares = response.getReturnValue();
                component.set("v.manualShares", manualShares);
                
                var columns = [
                    { label: 'Account Name', fieldName: 'accountName', type: 'text', editable: false },
                    { label: 'User Name', fieldName: 'userName', type: 'text', editable: false },
                    { type: 'button', 
                      typeAttributes: { 
                          label: 'Remove', 
                          name: 'remove', 
                          title: 'Remove', 
                          disabled: false, 
                          value: 'remove', 
                          iconPosition: 'center' 
                      } 
                    }
                ];
                component.set("v.columns", columns);
            } else {
                console.error(response.getError());
                this.showToast("Error", "Error fetching manual shares", "error");
            }
        });

        $A.enqueueAction(action);
    },

    removeManualShare: function(component, shareId) {
        var action = component.get("c.removeManualShare");
        action.setParams({
            shareId: shareId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Update the manualShares list without reloading the page
                var manualShares = component.get("v.manualShares");
                var updatedManualShares = manualShares.filter(function(share) {
                    return share.id !== shareId;
                });
                component.set("v.manualShares", updatedManualShares);
                this.showToast("Success", "Dental Office removed successfully", "success");
            } else {
                console.error(response.getError());
                this.showToast("Error", "Error removing manual share", "error");
            }
        });

        $A.enqueueAction(action);
    },

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})