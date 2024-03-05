public class pdfController {
    public InsuranceVerfication__c obj { get; set; }
    
    // Constructor
    public pdfController() {
    
    }
    
    // Method to determine which Visualforce page to render based on record type
    @AuraEnabled
    public static String generatePDF(String recordId) {
        InsuranceVerfication__c insuranceVerificationRecord;
        try {
            insuranceVerificationRecord = [SELECT Id, Name, RecordTypeId, RecordType.Name FROM InsuranceVerfication__c WHERE Id = :recordId];
            System.debug('Insurance Verification Record: ' + insuranceVerificationRecord);
            if (insuranceVerificationRecord != null) {
                String recordTypeName = insuranceVerificationRecord.RecordType.Name;
                System.debug('Record Type Name: ' + recordTypeName);
                if (recordTypeName == 'Dino Kids Dentistry Breakdown') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/InsuranceVerfication?id=' + recordId; // URL for Visualforce page for RecordType1
                } else if (recordTypeName == 'Aesthetic & Implant Dentistry of Atlanta Breakdown') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/AestheticImplantDentistry?id=' + recordId; // URL for Visualforce page for RecordType2
                }

            }
        } catch (Exception e) {
            System.debug('Error fetching Insurance Verification Record: ' + e.getMessage());
        }
        return null;
    }
    
}
