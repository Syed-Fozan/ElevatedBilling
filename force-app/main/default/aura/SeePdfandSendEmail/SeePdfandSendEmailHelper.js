({
    sendEmailWithPDF : function(component, event, helper) {
        var action = component.get("c.sendEmailWithPDF");
        action.setParams({
            recordId: component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
            this.showToastMessage('Email Sent Successfully ', 'Success');
                
            }
        });

        $A.enqueueAction(action);
    },

    generatePDF: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.generatePDF");
        action.setParams({
            "recordId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result) {
                    window.open(result, '_blank');
                } else {
                    console.log('No URL returned from Apex method');
                }
            } else {
                console.log('Error calling Apex method: ' + state);
            }
        });
        $A.enqueueAction(action);
    },

    showToastMessage: function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            duration: ' 5000',
            mode: 'dismissible',
            message: message,
            type: type,
            title: type ,
        });
        toastEvent.fire();
    }
})
