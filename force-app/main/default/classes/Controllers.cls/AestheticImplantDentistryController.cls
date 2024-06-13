public class AestheticImplantDentistryController {
    public InsuranceVerfication__c insuranceVerification { get; set; }
    private final String versionData;
    
    public AestheticImplantDentistryController() {
        String recordId = ApexPages.currentPage().getParameters().get('id');
        insuranceVerification = getInsuranceVerification(recordId);
    }
    
    public InsuranceVerfication__c getInsuranceVerification(String recordId) {
        if (recordId != null) {
            List<InsuranceVerfication__c> records = [SELECT  Payor_ID__c,
                                                     Adult_Prophy__c,Ortho_Lifetime_Max__c, Insurance_Name__c,Ins_Phone__c,Insurance_Effective_Date__c,Sealant_Limitations__c,D0396_CT_Scan_Freq__c,D0396_CT_Scan__c,
                                                     Adult_Prophy_Freq__c, Other_Method_COB__c, Is_plan_a_Cal_Year_or_Benefit_Year__c,Missing_Tooth_Clause__c,	Criteria__c,
                                                     Adult_Prophy_Freq_To_Age__c,Max_Applies_To_Diag_Prev__c,Rep_Name__c,Due_Date__c,Age_Limit__c,Patient_Date_of_Birth__c,
                                                     Age__c,Class_I_Preventive__c, D0274__c,D0274_Freq__c,Basic__c,Orthodontics__c,Plan_Type__c,Max_Remaining__c,Ging_Inflamm_D4346_freq__c,    
                                                     Are_there_Out_of_Network_Benefits__c,Fluoride_D1206__c,Fluoride_D1206_To_Age__c,Fluoride_D1206_Freq__c,Ging_Inflamm_D4346__c, 
                                                     Can_be_done_same_day_as_TX__c,Sealants__c,Sealants_Freq__c,Sealants_To_Age__c,Preventative__c,Perio_Maint_D4910__c, 
                                                     Child_Prophylaxis__c,Ref_Number__c,Plan_downgrade_Crowns__c,Plan_downgrade_Crowns_Freq__c,Payment_sent_to_Office_or_Subscriber__c, 
                                                     Child_Prophylaxis_Freq__c,EBS__c,Class_II_Basic__c,Crowns_Inlays_Onlays_LabialVeneers_Freq__c,Perio_Maint_D4910_Freq__c,
                                                     Child_Prophylaxis_Freq_To_Age__c,Composite_Filling_Freq__c,Crowns_Inlays_Onlays_Labial_Veneers__c, 
                                                     Composite_Fillings_D2391__c,Date_of_last_Exam__c,Pays_On_Prep_Seat_Date__c,Insurance_company__c,
                                                     D0140_shared_w_oral_exam__c,Date_of_last_BWX__c,Are_all_four_quads_allowed_in_one_day__c,Limitations__c, 
                                                     D0140_shared_w_oral_exam_Freq__c,Up_To_Age__c,Periodontal_Maintenance_Freq__c,Periodontal_Maintenance__c,
                                                     Date_Of_Birth__c,D2930__c,D2930_Freq__c,D2930_To_Age__c,Bridge_Dentures_Prosthetic__c,Bridge_Dentures_Prosthetic_Freq__c,
                                                     Deductible_applies_to__c,Last_Flouride__c,Date_of_last_Prophy__c,Date_of_last_Pano_FMX__c,
                                                     Dental_Maximum__c,D2929__c,D2929_Freq__c,D2929_To_Age__c,Used_to_date__c, Exam__c,Major__c,
                                                     Dental_Maximum_Remaining__c,D9630__c, Periapical__c,Periapical_Freq__c,Deductible__c,Duration__c,
                                                     Employer_Group_Name__c,SDF_D1354__c,SDF_D1354_Freq__c,SDF_D1354_To_Age__c,Prophy__c,BWX__c, 
                                                     Family_Deductible__c,D9630_Freq__c,Frenectomy_D7961_D7962__c,Fluoride_Age_Limit__c,Fluoride_Freq__c, 
                                                     Family_Deductible_Met_To_Date__c,Pulpotomy_D3220__c,Panoramic_FMX_Freq__c,Implants_D6010__c, 
                                                     Fee_Schedule__c,Ortho_Deductible__c,Comp_Exam_D0150_Freq__c,Implant_Abutment_D6056_D6057__c, 
                                                     In_Network__c,D1515__c,D1515_To_Age__c,PA_s_D0220__c,Panoramic_FMX__c,	Implant_Abutment_D6056_D6057_Freq__c,
                                                     Individual_Deductible__c,Ortho_Ded_Met__c,PA_s_D0220_Freq__c,Freq__c,Implant_Crown_D6056_D6057__c, 
                                                     Individual_Deductible_Met_To__c,Pulpotomy_D3220_To_Age__c,Implants_Benefits__c, 
                                                     Ins_Address__c,D1516__c,D1516_To_Age__c,PA_s_D0220_Freq_To_Age__c,Implant_Crown_D6056_D6057_Freq__c,
                                                     Patient_Name__c,D1517__c,D1517_To_Age__c,Routine_Prophylaxis__c,Routine_Prophylaxis_Freq__c,Routine_Prophylaxis_To_Age__c,
                                                     Payment_issued_to_Subscriber_or_Office__c,Are_posterior_composites_downgraded__c, 
                                                     Plan_Group__c,Ortho_Max_Met__c,Simple_Ext_To_Age__c,Endodontic__c,Maximum__c, 
                                                     Alternate_benefit__c,Perio_Scaling_Freq__c,Perio_Scaling__c, 
                                                     Routine_Oral_Exam_Freq__c,Ortho__c,Class_III_Major__c,Allowable_same_day_as_Crown__c,Crown_Build_up__c, 
                                                     Standard_COB__c,Payment_Frequency__c,Simple_Ext_D7140__c,Surgical_Ext__c,FMX__c,
                                                     Subscriber_Date_Of_Birth__c,Pallative_D9110__c,Bitewings_Freq__c,Bitewings__c,FL__c, 
                                                     Subscriber_ID__c,Auto_Pay__c,Pallative_D9110_Freq__c,Crown_Build_up_Freq__c,Has_deductible_been_met__c, 
                                                     Subscriber_Name__c,Claim_Submit_Freq__c,Frenectomy_D7961_D7962_Freq__c,Fillings__c, Date__c,
                                                     Bitewings_D0272__c,Bitewings_D0272_Freq__c,Bitewings_D0272_To_Age__c,	Nightguards_D9944__c,
                                                     Waiting_Period__c ,D0240__c,D0240_Freq__c,D0240_to_Age__c,Group_Name__c,Group__c,Eff_Date__c
                                                     FROM InsuranceVerfication__c 
                                                     WHERE Id = :recordId
                                                     LIMIT 1];
            if (records.size() > 0) {
                return records[0];
            }
        }
        return new InsuranceVerfication__c();
    }
}