public Without Sharing class SendProfileLinkJob implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;
    
    public SendProfileLinkJob(List<Account> accounts) {
        this.accounts = accounts;
    }
    
    public void execute(QueueableContext context) {
        // Use Salesforce Sites URL
          String siteUrl = 'https://abc-fashion-dev-ed.develop.my.site.com/abcfashionguestcustomer';
      
        system.debug(siteUrl);
        
        for (Account acc : accounts) {
            // Call the email service
            if (acc.IsPersonAccount == True){
                CustomerProfileEmailService.sendCustomerProfileEmail(acc.PersonEmail, acc.FirstName, acc.Profile_Access_Token__c, siteUrl); //,acc.Id
            }
        }
    }
}