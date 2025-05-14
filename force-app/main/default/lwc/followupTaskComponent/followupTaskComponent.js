import { LightningElement, track, wire } from 'lwc';
import FollowUpTask from '@salesforce/apex/FollowUpTask.FollowUpTask';
import getUsers from '@salesforce/apex/OCRDashboardTeamLead.getUsers';


const columns = [
    { label: 'User Name', fieldName: 'name', type: 'text' },
    { label: 'Practice Name', fieldName: 'dentalOfficeName', type: 'text' },
    { label: 'Assigned Tasks', fieldName: 'assignedTasks', type: 'number', cellAttributes: { alignment: 'left' } },
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
    @track selectedUser = ' '; // Default is no user

    @track treeData;
    @track error;
    columns = columns;
    @track expandedRows = []; // Add this property

    // Modal Data
    @track isModalOpen = false;
    @track modalData = [];
    @track modalColumns = [
        {
            label: 'Claim Name',
            fieldName: 'claimLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'claimName' }, target: '_blank' }
        },        { label: 'User Name', fieldName: 'ownerName', type: 'text' },
        { label: 'Insurance Name', fieldName: 'insuranceName', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Work Date ', fieldName: 'lastModifiedDate' },
        { label: 'Due Date', fieldName: 'DueDate' },

        // { label: 'Assigned Tasks', fieldName: 'assignedTasks', type: 'number', cellAttributes: { alignment: 'left' } },
        { label: 'Comments ', fieldName: 'description' }

    ];
   @wire(FollowUpTask, { userId: '$selectedUser' })
    wiredAccounts({ error, data }) {
        debugger;
        if (data) {
            this.data = data;
            this.treeData = this.transformData(data);
            this.expandedRows = this.treeData.map(row => row.Id); // Add this line

        } else if (error) {
            this.error = error;
            this.treeData = [];
            this.expandedRows = [];
        }
    }

    @wire(getUsers)
    wiredgetUser({data,error}){
        debugger;
        if(data){
            this.useroption = data.map(User =>({
                label : User.Name,
                value : User.Id
            }));
        } else if (error){
            console.error(error);
        }
    }



    handleUserChange(event) {
        this.selectedUser  = event.target.value;
    }  


    transformData(data) {
    let groupedData = {};

    data.forEach(office => {
        office.claims.forEach(claim => {
            const ownerName = claim.ownerName;
            const dentalOfficeName = office.dentalOfficeName;
            const pendingTaskAmount = office.pendingTaskAmount;

            if (!groupedData[ownerName]) {
                groupedData[ownerName] = {
                    Id: ownerName,
                    name: ownerName,
                    disableAction: true, 
                    rowClass: "slds-hide",  
                    _children: [],
                    expanded: true  
                };
            }

            let childRow = groupedData[ownerName]._children.find(child => child.dentalOfficeName === dentalOfficeName);
            if (!childRow) {
                childRow = {
                    Id: `${ownerName}-${dentalOfficeName}`,
                    ownerName: ownerName,
                    dentalOfficeName: dentalOfficeName,
                    assignedTasks: 0,
                    countOfClaims: 0,  
                    pendingTaskAmount: pendingTaskAmount,
                    claims: [],
                    pendingTasks: [],
                    disableAction: false, 
                    rowClass: "",
                    expanded: false
                };
                groupedData[ownerName]._children.push(childRow);
            }

            childRow.assignedTasks += 1; // Increment assigned tasks count
            childRow.claims.push(claim);
        });

        office.pendingTasks.forEach(task => {
            const ownerName = task.ownerName;
            const dentalOfficeName = office.dentalOfficeName;
            const pendingTaskAmount = office.pendingTaskAmount;

            if (!groupedData[ownerName]) {
                groupedData[ownerName] = {
                    Id: ownerName,
                    name: ownerName,
                    disableAction: true,
                    rowClass: "slds-hide",
                    _children: [],
                    expanded: true  
                };
            }

            let childRow = groupedData[ownerName]._children.find(child => child.dentalOfficeName === dentalOfficeName);
            if (!childRow) {
                childRow = {
                    Id: `${ownerName}-${dentalOfficeName}`,
                    ownerName: ownerName,
                    dentalOfficeName: dentalOfficeName,
                    assignedTasks: 0,
                    countOfClaims: 0,
                    pendingTaskAmount: pendingTaskAmount,
                    claims: [],
                    pendingTasks: [],
                    disableAction: false,
                    rowClass: "",
                    expanded: false
                };
                groupedData[ownerName]._children.push(childRow);
            }

            childRow.pendingTasks.push(task);
        });
    });

    // Calculate countOfClaims and assignedTasks for each child row
    Object.values(groupedData).forEach(owner => {
        owner._children.forEach(child => {
            child.countOfClaims = child.pendingTasks.length;
            child.assignedTasks = child.claims.length; // Ensure assignedTasks is updated
        });
    });

    return Object.values(groupedData);
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
        if (type === 'claims') {
            this.modalData = rowData.claims.map(claim => ({
                ...claim,
                claimLink: `/lightning/r/Claim__c/${claim.claimId}/view`  
            }));
        } else if (type === 'pendingTasks') {
            this.modalData = rowData.pendingTasks.map(task => ({
                ...task,
                claimLink: `/lightning/r/Claim__c/${task.claimId}/view`
            }));
        }
    
        this.isModalOpen = true;
    }

    // Close modal
    closeModal() {
        this.isModalOpen = false;
    }
}