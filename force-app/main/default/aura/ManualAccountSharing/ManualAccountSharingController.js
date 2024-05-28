({
    doInit: function(component, event, helper) {
        helper.fetchAccounts(component);
    },

    handleAccountChange: function(component, event, helper) {
        var selectedAccountId = component.get("v.selectedAccountId");
        helper.fetchManualShares(component, selectedAccountId);
    },

    handleRowAction: function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        switch (action.name) {
            case 'remove':
                helper.removeManualShare(component, row.id);
                break;
        }
    }
})