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
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/InsuranceVerfication?id=' + recordId; 
                } else if (recordTypeName == 'Boise Dental Art Breakdown') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/BoiseDentalArtBreakdownForm?id=' + recordId; 
                } else if (recordTypeName == 'canatella breakdown') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/canatellabreakdown?id=' + recordId; 
                } else if (recordTypeName == 'buckhead Dental Studio Breakdown Form') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/buckheadDentalStudioBreakdownForm?id=' + recordId;
                } else if (recordTypeName == 'Alameda Breakdown') {
                    return 'https://elevatebillingsolutions--farukhtst--c.sandbox.vf.force.com/apex/AlamedaBreakdown?id=' + recordId; 
                }
                
            }
        } catch (Exception e) {
            System.debug('Error fetching Insurance Verification Record: ' + e.getMessage());
        }
        return null;
    }
    
}