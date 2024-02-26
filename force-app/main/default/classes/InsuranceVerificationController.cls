public class InsuranceVerificationController {
    public InsuranceVerfication__c insuranceVerification { get; private set; }

    public InsuranceVerificationController() {
        insuranceVerification = getInsuranceVerification();
    }

    public InsuranceVerfication__c getInsuranceVerification() {
        return [SELECT Id, Payor_ID__c, 
                        Adult_Prophy__c, Insurance_Name__c,Ins_Phone__c,Insurance_Effective_Date__c,
                        Adult_Prophy_Freq__c, Other_Method_COB__c,Is_plan_a_Cal_Year_or_Benefit_Year__c,
                        Adult_Prophy_Freq_To_Age__c,Max_Applies_To_Diag_Prev__c,
                        Age__c, 
                        Are_there_Out_of_Network_Benefits__c, 
                        Can_be_done_same_day_as_TX__c, 
                        Child_Prophylaxis__c, 
                        Child_Prophylaxis_Freq__c, 
                        Child_Prophylaxis_Freq_To_Age__c, 
                        Composite_Fillings_D2391__c, 
                        D0140_shared_w_oral_exam__c, 
                        D0140_shared_w_oral_exam_Freq__c, 
                        Date_Of_Birth__c, 
                        Deductible_applies_to__c, 
                        Dental_Maximum__c, 
                        Dental_Maximum_Remaining__c, 
                        Employer_Group_Name__c, 
                        Family_Deductible__c, 
                        Family_Deductible_Met_To_Date__c, 
                        Fee_Schedule__c, 
                        In_Network__c, 
                        Individual_Deductible__c, 
                        Individual_Deductible_Met_To__c, 
                        Ins_Address__c, 
                        Patient_Name__c, 
                        Payment_issued_to_Subscriber_or_Office__c, 
                        Plan_Group__c, 
                        Plan_Type__c, 
                        Routine_Oral_Exam_Freq__c, 
                        Standard_COB__c, 
                        Subscriber_Date_Of_Birth__c, 
                        Subscriber_ID__c, 
                        Subscriber_Name__c, 
                        Subscriber_Plan_Type__c, 
                        Waiting_Period__c 
               FROM InsuranceVerfication__c 
               LIMIT 1];
    }
}
