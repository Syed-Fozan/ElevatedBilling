public class pdfController {
    public Id accountId { get; set; }
    
    public PageReference pdfController() {
        PageReference pdfPage = Page.InsuranceVerfication;
        pdfPage.getParameters().put('id', accountId);
        Blob pdfBlob;
        
        try {
            pdfBlob = pdfPage.getContentAsPDF();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error generating PDF: ' + e.getMessage()));
            return null;
        }
        
        Attachment attachment = new Attachment();
        attachment.Name = 'Account_Details.pdf';
        attachment.Body = pdfBlob;
        attachment.ParentId = accountId; // Attach PDF to the record, modify this according to your requirements
        insert attachment;
        
        return null;
    }
}