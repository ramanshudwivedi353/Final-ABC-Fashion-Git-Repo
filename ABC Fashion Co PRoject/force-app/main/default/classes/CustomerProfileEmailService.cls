public without sharing class CustomerProfileEmailService {
    
    // Method to send customer profile email
    public static void sendCustomerProfileEmail(String customerEmail, String customerName, String profileAccessToken, String siteUrl) {
        if (String.isBlank(customerEmail) || String.isBlank(profileAccessToken)) {
            System.debug('Invalid email or token. Email not sent.');
            return;
        }
        
        // Constructing the full profile link with the token
        String profileUrl = siteUrl + '?token=' + profileAccessToken;
        
        //subject and body of the email
        String subject = 'Welcome to ABC Fashion';
        String body = 'Hello ' + customerName + ',' +
            '\n\nClick on the following link to view and update your profile:' +
            '\n' + profileUrl + 
            '\n\nThanks,' +
            '\nABC Fashion Support';
        
        // Create a new SingleEmailMessage object
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { customerEmail });
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setReplyTo('support@abcfashion.com');  
        email.setSenderDisplayName('ABC Fashion Support');  
        
        try {
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email }, false);  
            System.debug('Email successfully sent to: ' + customerEmail);
        } catch (Exception e) {
            System.debug('Failed to send email to: ' + customerEmail + ' due to: ' + e.getMessage());
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
    }
}