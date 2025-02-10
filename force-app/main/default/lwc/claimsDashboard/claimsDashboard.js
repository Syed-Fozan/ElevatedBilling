import { LightningElement, wire } from 'lwc';
import getClaimStatusCounts from '@salesforce/apex/ClaimStatusController.getClaimStatusCounts';
import getRecordsByStatus from '@salesforce/apex/ClaimStatusController.getRecordsByStatus';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';

export default class ClaimsDashboard extends LightningElement {
   columns = [
      { label: 'Claim ID', fieldName: 'Id' },
      { label: 'Name', fieldName: 'Name' },
      { label: 'Status', fieldName: 'Status__c' },
      { label: 'Amount', fieldName: 'Claim_Amount__c' },
  ];
  
    chart;
    chartjsInitialized = false;
    chartData = [];
    chartLabels = [];
    completedRecords = []; // Store the records for the "Completed" status
    showDatatable = false; // Control visibility of the datatable

    @wire(getClaimStatusCounts)
    wiredClaimStatusCounts({ error, data }) {
        if (data) {
            this.chartLabels = Object.keys(data); // Example: ['Completed', 'Pending']
            this.chartData = Object.values(data); // Example: [20, 15]
            this.renderChart();
        } else if (error) {
            console.error('Error fetching data:', error);
        }
    }

    renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }
        this.chartjsInitialized = true;

        loadScript(this, chartjs)
            .then(() => this.renderChart())
            .catch(error => console.error('Error loading Chart.js:', error));
    }

    renderChart() {
        if (this.chart || !this.chartData.length) {
            return;
        }
        const ctx = this.template.querySelector('canvas').getContext('2d');
        this.chart = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: this.chartLabels,
                datasets: [
                    {
                        label: 'Claim Status Distribution',
                        data: this.chartData,
                        backgroundColor: [
                            'rgba(0, 51, 102, 0.9)', // Dark Navy Blue
                            'rgba(102, 0, 51, 0.9)', // Dark Maroon
                            'rgba(51, 51, 51, 0.9)', // Dark Gray
                            'rgba(0, 102, 0, 0.9)',  // Dark Green
                        ],
                        borderColor: [
                            'rgba(0, 51, 102, 1)',   // Navy Blue Border
                            'rgba(102, 0, 51, 1)',   // Maroon Border
                            'rgba(51, 51, 51, 1)',   // Gray Border
                            'rgba(0, 102, 0, 1)',    // Green Border
                        ],
                        borderWidth: 2,
                    },
                ],
            },
            options: {
                responsive: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        onClick: (e, legendItem) => this.handleLegendClick(legendItem.text),
                    },
                },
            },
        });
    }

    handleLegendClick(label) {
        if (label === 'Completed') {
            this.fetchRecordsByStatus('Completed');
        }
    }

    fetchRecordsByStatus(status) {
        getRecordsByStatus({ status })
            .then((records) => {
                this.completedRecords = records;
                this.showDatatable = true;
            })
            .catch((error) => {
                console.error('Error fetching records:', error);
            });
    }
}
