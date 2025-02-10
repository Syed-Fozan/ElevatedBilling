({
    fetchClaimStatusCounts: function (component) {
        let action = component.get("c.getClaimStatusCounts");
        action.setParams({ 
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                component.set("v.chartLabels", Object.keys(data));
                component.set("v.chartData", Object.values(data));
                this.initializeChart(component); // Initialize chart
            } else {
                console.error("Error fetching claim status counts:", response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    initializeChart: function (component) {
        let chartLabels = component.get("v.chartLabels");
        let chartData = component.get("v.chartData");

        if (!chartLabels || !chartData) return;

        let ctx = component.find("chartCanvas").getElement().getContext("2d");

        let chart = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: chartLabels,
                datasets: [{
                    data: chartData,
                    backgroundColor: [
                        'rgba(255, 99, 132, 0.7)',   // Red
                        'rgba(54, 162, 235, 0.7)',  // Blue
                        'rgba(255, 206, 86, 0.7)',  // Yellow
                        'rgba(75, 192, 192, 0.7)',  // Green
                        'rgba(153, 102, 255, 0.7)', // Purple
                        'rgba(54, 606, 86, 0.7)',  // Yellow
                        'rgba(75, 256, 86, 0.7)',  // Yellow
                        'rgba(255, 246, 86, 0.7)'  // Yellow
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'left',
                    }
                },
                onClick: (e) => {

                    // Use the tooltip feature to get information about the clicked segment
                    let activePoints = chart.getElementsAtEvent(e);
                
                    if (activePoints && activePoints.length > 0) {
                        // Get the index from the first active point
                        let clickedIndex = activePoints[0]._index;
                        let clickedLabel = chart.data.labels[clickedIndex]; // Get label from chart data
                        
                        console.log("Clicked Label:", clickedLabel); // Log for debugging
                        let navEvent = $A.get("e.force:navigateToComponent");
                        navEvent.setParams({
                            componentDef: "c:ClaimStatusDataPage", // Replace with your new component's name
                            componentAttributes: {
                                selectedStatus: clickedLabel, // Pass the clicked label as an attribute
                                recordId: component.get("v.recordId")
                            }
                        });
                        navEvent.fire();
                                
                        
                        // this.fetchRecordsByStatus(component, clickedLabel); // Fetch records for clicked label
                    } else {
                        console.log("No valid segment clicked.");
                    }
                }
            }
        });

        component.set("v.chart", chart);
    },

    fetchRecordsByStatus: function (component, status) {
        component.set("v.isLoading", true);
    
        // Fetch previously cached records if available
        let cachedData = component.get("v.cachedStatusRecords") || {};
        if (cachedData[status]) {
            component.set("v.selectedStatusRecords", cachedData[status]);
            component.set("v.showDatatable", true);
            component.set("v.isLoading", false); // Hide spinner
            return;
        }
    
        // Proceed with server call if no cache
        let action = component.get("c.getRecordsByStatus");
        action.setParams({ 
            status: status, 
            recordId: component.get("v.recordId")
        });
    
        action.setCallback(this, function (response) {
            component.set("v.isLoading", false); // Hide spinner
            let state = response.getState();
    
            if (state === "SUCCESS") {
                let records = response.getReturnValue();
                if (records && records.length > 0) {
                    cachedData[status] = records;
                    component.set("v.cachedStatusRecords", cachedData);
    
                    component.set("v.selectedStatusRecords", records);
                    component.set("v.showDatatable", true);
                } else {
                    // Handle empty results
                    component.set("v.selectedStatusRecords", []);
                    component.set("v.showDatatable", false);
                }
            } else if (state === "ERROR") {
                let errors = response.getError();
                console.error("Error fetching records:", errors);
                alert("An error occurred while fetching records. Please try again.");
            } else {
                console.warn("Unexpected response state:", state);
            }
        });
    
        $A.enqueueAction(action);
    }
    
});
