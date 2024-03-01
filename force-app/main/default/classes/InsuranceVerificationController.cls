public class InsuranceVerificationController {
    public InsuranceVerfication__c insuranceVerification { get; set; }

    public InsuranceVerificationController() {
        insuranceVerification = getInsuranceVerification();
    }

    public InsuranceVerfication__c getInsuranceVerification() {
        return [ SELECT  Payor_ID__c,
                        Adult_Prophy__c, Insurance_Name__c,Ins_Phone__c,Insurance_Effective_Date__c,
                        Adult_Prophy_Freq__c, Other_Method_COB__c,Is_plan_a_Cal_Year_or_Benefit_Year__c,
                        Adult_Prophy_Freq_To_Age__c,Max_Applies_To_Diag_Prev__c,Rep_Name__c,Due_Date__c,
                        Age__c,Class_I_Preventive__c, D0274__c,D0274_Freq__c,	
                        Are_there_Out_of_Network_Benefits__c,Fluoride_D1206__c,Fluoride_D1206_To_Age__c,Fluoride_D1206_Freq__c, 
                        Can_be_done_same_day_as_TX__c,Sealants__c,Sealants_Freq__c,Sealants_To_Age__c, 
                        Child_Prophylaxis__c,Ref_Number__c, 
                        Child_Prophylaxis_Freq__c,EBS__c,Class_II_Basic__c,
                        Child_Prophylaxis_Freq_To_Age__c,Composite_Filling_Freq__c, 
                        Composite_Fillings_D2391__c,Date_of_last_Exam__c, 
                        D0140_shared_w_oral_exam__c,Date_of_last_BWX__c, 
                        D0140_shared_w_oral_exam_Freq__c,Up_To_Age__c,
                        Date_Of_Birth__c,D2930__c,D2930_Freq__c,D2930_To_Age__c,
                        Deductible_applies_to__c,Last_Flouride__c,Date_of_last_Prophy__c,Date_of_last_Pano_FMX__c,
                        Dental_Maximum__c,D2929__c,D2929_Freq__c,D2929_To_Age__c, 
                        Dental_Maximum_Remaining__c,D9630__c, 
                        Employer_Group_Name__c,SDF_D1354__c,SDF_D1354_Freq__c,SDF_D1354_To_Age__c, 
                        Family_Deductible__c,D9630_Freq__c,Frenectomy_D7961_D7962__c, 
                        Family_Deductible_Met_To_Date__c,Pulpotomy_D3220__c, 
                        Fee_Schedule__c,Ortho_Deductible__c,Comp_Exam_D0150_Freq__c, 
                        In_Network__c,D1515__c,D1515_To_Age__c,PA_s_D0220__c,
                        Individual_Deductible__c,Ortho_Ded_Met__c,PA_s_D0220_Freq__c, 
                        Individual_Deductible_Met_To__c,Pulpotomy_D3220_To_Age__c, 
                        Ins_Address__c,D1516__c,D1516_To_Age__c,PA_s_D0220_Freq_To_Age__c,
                        Patient_Name__c,D1517__c,D1517_To_Age__c, 
                        Payment_issued_to_Subscriber_or_Office__c, 
                        Plan_Group__c,Ortho_Max_Met__c,Simple_Ext_To_Age__c, 
                        Plan_Type__c,Ortho_Lifetime_Max__c,Alternate_benefit__c, 
                        Routine_Oral_Exam_Freq__c,Ortho__c,Class_III_Major__c, 
                        Standard_COB__c,Payment_Frequency__c,Simple_Ext_D7140__c, 
                        Subscriber_Date_Of_Birth__c,Pallative_D9110__c, 
                        Subscriber_ID__c,Auto_Pay__c,Pallative_D9110_Freq__c, 
                        Subscriber_Name__c,Claim_Submit_Freq__c,Frenectomy_D7961_D7962_Freq__c, 
                        Subscriber_Plan_Type__c,Bitewings_D0272__c,Bitewings_D0272_Freq__c,Bitewings_D0272_To_Age__c,
                        Waiting_Period__c ,D0240__c,D0240_Freq__c,D0240_to_Age__c
               FROM InsuranceVerfication__c 
               LIMIT 1];
    }
}
