({
    doInit: function(component, event, helper) {
        debugger;
        helper.fetchClaimStatusCounts(component); // Fetch claim status counts
    },

    scriptsLoaded: function(component, event, helper) {
        helper.initializeChart(component); // Initialize the chart after loading scripts
    },

    getDateValue: function(component, event, helper) {
        debugger;
        // Get the date value from the lightning:input component by aura:id
        var dateInput = component.find("dateInput");
        
        // Get the value of the input field
        var dateValue = dateInput.get("v.value");
        
        // Log the value or use it as needed
        console.log("Selected Date:", dateValue);
    },   

    handleLegendClick: function(component, event, helper) {
        let status = event.getParam("label");
        helper.fetchRecordsByStatus(component, status); // Fetch records by status
    }
});