import { LightningElement, track, wire,api } from 'lwc';
import FollowUpTask from '@salesforce/apex/OCRDashboardTeamLead.OCRDashboardTeamLead';
import getUsers from '@salesforce/apex/OCRDashboardTeamLead.getUsers';
const columns = [
    { label: 'Practice Name', fieldName: 'name', type: 'text' },
    { label: 'User Name', fieldName: 'ownerName', type: 'text' },
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
        variant: 'success'
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
        variant: 'Brand'
    },
    cellAttributes: {
        class: { fieldName: 'rowClass' }  // Add a class condition
    }
}
];

export default class FollowupTaskComponent extends LightningElement {
    @track selectedUser = ''; // Default is no user
    @track data;
    @track treeData;
    @track error;
    columns = columns;
    @track expandedRows = []; // Add this property

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

    handleUserChange(event) {
        this.selectedUser  = event.target.value;

        // FollowUpTask({ userId: this.SelectedUser })
        //     .then(result => {
        //         debugger;
        //         this.data = result;
        //         this.treeData = this.transformData(result);
        //         this.expandedRows = this.treeData.map(row => row.Id);
        //     })
        //     .catch(error => {
        //         this.error = error;
        //     });
    }

   @wire(FollowUpTask, { userId: '$selectedUser' })
    wiredAccounts({ error, data }) {
        debugger;
        if (data) {
            this.data = data;
            this.treeData = this.transformData(data);
            this.expandedRows = this.treeData.map(row => row.Id);
        } else if (error) {
            this.error = error;
            this.treeData = [];
            this.expandedRows = [];
        }
    }

    transformData(data) {
    let groupedData = {};

    data.forEach(office => {
        const dentalOfficeName = office.dentalOfficeName;
        const pendingTaskAmount = office.pendingTaskAmount;

        if (!groupedData[dentalOfficeName]) {
            groupedData[dentalOfficeName] = {
                Id: dentalOfficeName,
                name: dentalOfficeName,
                disableAction: true,
                rowClass: "slds-hide",
                _children: [],
                expanded: true
            };
        }

        // Group assigned claims by owner under the dental office
        office.claims.forEach(claim => {
            const ownerName = claim.ownerName;
            const dentalOfficeName = office.dentalOfficeName;
            const pendingTaskAmount = office.pendingTaskAmount;


            let childRow = groupedData[dentalOfficeName]._children.find(child => child.ownerName === ownerName);
            if (!childRow) {
                childRow = {
                    Id: `${dentalOfficeName}-${ownerName}`,
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
                groupedData[dentalOfficeName]._children.push(childRow);
            }

            childRow.assignedTasks += 1;
            childRow.claims.push(claim);
        });

        // Group pending tasks by owner under the dental office
        office.pendingTasks.forEach(task => {
            const ownerName = task.ownerName;

            let childRow = groupedData[dentalOfficeName]._children.find(child => child.ownerName === ownerName);
            if (!childRow) {
                childRow = {
                    Id: `${dentalOfficeName}-${ownerName}`,
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
                groupedData[dentalOfficeName]._children.push(childRow);
            }

            childRow.pendingTasks.push(task);
        });
    });

    // Calculate countOfClaims and assignedTasks for each child row
    Object.values(groupedData).forEach(office => {
        office._children.forEach(child => {
            child.countOfClaims = child.pendingTasks.length;
            child.assignedTasks = child.claims.length;
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