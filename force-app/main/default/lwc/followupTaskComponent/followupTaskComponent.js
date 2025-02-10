import { LightningElement, track, wire } from 'lwc';
import FollowUpTask from '@salesforce/apex/FollowUpTask.FollowUpTask';

const columns = [
    { label: 'Owner Name', fieldName: 'name', type: 'text' },
    { label: 'Practice Name', fieldName: 'dentalOfficeName', type: 'text' },
    { label: 'Total Assigned Tasks', fieldName: 'assignedTasks', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Pending Task Count', fieldName: 'countOfClaims', type: 'number', cellAttributes: { alignment: 'left' }},
    { label: 'Pending Task Amount', fieldName: 'pendingTaskAmount', type: 'currency' ,cellAttributes: { alignment: 'left' }},
   {
    type: "button",
    label: 'Assigned Task',
    initialWidth: 180,
    typeAttributes: {
        label: 'Assigned Task',
        name: 'AssignedTask',
        title: 'View Assigned Task',
        disabled: { fieldName: 'disableAction' },  
        value: 'view',
        iconName: 'utility:preview',
        variant: 'brand'
    },
    cellAttributes: {
        class: { fieldName: 'rowClass' }  // Add a class condition
    }
},
{
    type: "button",
    label: 'Pending Task',
    initialWidth: 150,
    typeAttributes: {
        label: 'Pending Task',
        name: 'PendingTask',
        title: 'View Pending Task',
        disabled: { fieldName: 'disableAction' },  
        value: 'view',
        iconName: 'utility:preview',
        variant: 'Error'
    },
    cellAttributes: {
        class: { fieldName: 'rowClass' }  // Add a class condition
    }
}
];

export default class FollowupTaskComponent extends LightningElement {
    @track data;
    @track treeData;
    @track error;
    columns = columns;

    // Modal Data
    @track isModalOpen = false;
    @track modalData = [];
    @track modalColumns = [
        { label: 'Claim Name', fieldName: 'claimName', type: 'text' },
        { label: 'Owner Name', fieldName: 'ownerName', type: 'text' },
        { label: 'Insurance Name', fieldName: 'insuranceName', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Work Date ', fieldName: 'lastModifiedDate' },
        // { label: 'Assigned Tasks', fieldName: 'assignedTasks', type: 'number', cellAttributes: { alignment: 'left' } },
        { label: 'Comments ', fieldName: 'description' }

    ];

    @wire(FollowUpTask)
    wiredAccounts({ error, data }) {
        if (data) {
            this.data = data;
            this.treeData = this.transformData(data);
        } else if (error) {
            this.error = error;
        }
    }

    transformData(data) {
    let groupedData = {};

    data.forEach(office => {
        office.claims.forEach(claim => {
            const ownerName = claim.ownerName;
            const dentalOfficeName = office.dentalOfficeName;

            if (!groupedData[ownerName]) {
                groupedData[ownerName] = {
                    Id: ownerName,
                    name: ownerName,
                    disableAction: true,  // Disable buttons for owner rows
                    rowClass: "slds-hide",  // Hide button column
                    _children: {}
                };
            }

            if (!groupedData[ownerName]._children[dentalOfficeName]) {
                groupedData[ownerName]._children[dentalOfficeName] = {
                    Id: `${ownerName}-${dentalOfficeName}`,
                    ownerName: ownerName,
                    dentalOfficeName: dentalOfficeName,
                    assignedTasks: 0,
                    countOfClaims: 0,  
                    pendingTaskAmount: 0,
                    claims: [],
                    pendingTasks: [],
                    disableAction: false, // Enable buttons for detail rows
                    rowClass: ""  // Keep visible for practice name rows
                };
            }

            groupedData[ownerName]._children[dentalOfficeName].assignedTasks += claim.assignedTasks;
            groupedData[ownerName]._children[dentalOfficeName].claims.push(claim);
        });

        office.pendingTasks.forEach(task => {
            const ownerName = task.ownerName;
            const dentalOfficeName = office.dentalOfficeName;

            if (!groupedData[ownerName]) {
                groupedData[ownerName] = {
                    Id: ownerName,
                    name: ownerName,
                    disableAction: true,
                    rowClass: "slds-hide",
                    _children: {}
                };
            }

            if (!groupedData[ownerName]._children[dentalOfficeName]) {
                groupedData[ownerName]._children[dentalOfficeName] = {
                    Id: `${ownerName}-${dentalOfficeName}`,
                    ownerName: ownerName,
                    dentalOfficeName: dentalOfficeName,
                    assignedTasks: 0,
                    countOfClaims: 0,
                    pendingTaskAmount: 0,
                    claims: [],
                    pendingTasks: [],
                    disableAction: false,
                    rowClass: ""
                };
            }

            groupedData[ownerName]._children[dentalOfficeName].pendingTasks.push(task);
        });

        Object.values(groupedData).forEach(owner => {
            Object.values(owner._children).forEach(child => {
                child.countOfClaims = child.pendingTasks.length;
            });
        });
    });

    return Object.values(groupedData).map(owner => ({
        Id: owner.Id,
        name: owner.name,
        disableAction: true,  // Owner row should not have buttons
        rowClass: "slds-hide",  // Hide buttons for owners
        _children: Object.values(owner._children)
    }));
}

    // Handle button click action
    callRowAction(event) {
        const actionName = event.detail.action.name;
        const rowData = event.detail.row;

        if (actionName === 'AssignedTask') {
            this.openModal(rowData, 'claims');
        } else if (actionName === 'PendingTask') {
            this.openModal(rowData, 'pendingTasks');
        }
    }

    // Open modal and filter data based on button clicked
    openModal(rowData, type) {
        this.modalData = type === 'claims' ? rowData.claims || [] : rowData.pendingTasks || [];
        this.isModalOpen = true;
    }

    // Close modal
    closeModal() {
        this.isModalOpen = false;
    }
}