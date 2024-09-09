@IsTest
public class CustomerProfileTestClass {
    
    // Utility method to create test Account
    public static Account createTestPersonAccount(String email) {
        
        Account acc = new Account(
            FirstName = 'TestFirst',
            LastName = 'TestLast',
            PersonEmail = email,
            Phone = '1234567890',
            T_shirt_size__c = 'M',
            Shoe_size__c = '10.0',
            Customer_Date_Of_Birth__c = Date.today() - 1000
        );
        Insert acc;
        
        Account accountToUse = [SELECT FirstName, LastName, Phone, PersonEmail, Profile_Access_Token__c, T_shirt_size__c, Shoe_size__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        system.debug('0.acc.===>'+JSON.serialize(acc));
        system.debug('0.accountToUse.===>'+JSON.serialize(accountToUse));
        return acc;
    }
    
    
    // Test the SendCustomerProfileLink trigger
    @IsTest
    static void testSendCustomerProfileLink() {
        
        Account testAccount = createTestPersonAccount('testemail@example.com');
        
        system.debug('0.testAccount.===>'+JSON.serialize(testAccount));
        testAccount = [SELECT Profile_Access_Token__c FROM Account WHERE Id = :testAccount.Id];
        system.debug('=====testAccount.Profile_Access_Token__c===>'+testAccount.Profile_Access_Token__c);
        Account retrievedAccount = GuestPersonAccountController.getPersonAccount(testAccount.Profile_Access_Token__c);
        system.debug('=====retrievedAccount===>'+JSON.serialize(retrievedAccount));
        
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Completed'];
        List<Account> updatedAccounts = [SELECT Loyalty_Customer_ID__c FROM Account WHERE Id = :testAccount.Id];
        
    }
    
    // Test SendProfileLinkJob Queueable
    @IsTest
    static void testSendProfileLinkJob() {
        Account testAccount = createTestPersonAccount('testemail@example.com');
        SendProfileLinkJob job = new SendProfileLinkJob(new List<Account>{testAccount});
        Test.startTest();
        Test.stopTest();
    }
    
    // Test the CustomerProfileEmailService
    @IsTest
    static void testCustomerProfileEmailService() {
        Account testAccount = createTestPersonAccount('testemail@example.com');
        CustomerProfileEmailService.sendCustomerProfileEmail('testemail@example.com', 'TestFirst', testAccount.Profile_Access_Token__c, 'https://abc-fashion-dev-ed.develop.my.site.com/abcfashionguestcustomer');
        
    }
    
    @IsTest
    static void testUpdatePersonAccount() {
        Account testAccount = createTestPersonAccount('testemail@example.com');
        Account updatedAccount = new Account(
            Id = testAccount.Id,
            FirstName = 'UpdatedFirst',
            LastName = 'UpdatedLast',
            Phone = '9876543210',
            PersonEmail = 'updatedemail@example.com',
            T_shirt_size__c = 'L',
            Shoe_size__c = '11.0',
            Customer_Date_Of_Birth__c = Date.today() - 900
        );
        
        GuestPersonAccountController.updatePersonAccount(updatedAccount);
        
        Account updatedFromDB = [SELECT FirstName, LastName, Phone, PersonEmail, T_shirt_size__c, Shoe_size__c FROM Account WHERE Id = :testAccount.Id];
        
    }
    
    @IsTest
    static void testSendLoyaltyInformation() {
        Account testAccount = createTestPersonAccount('testemail@example.com');
        List<Id> accountIds = new List<Id>{testAccount.Id};
        
        Test.startTest();
        
        // Use the mock class defined separately
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseLoyalty());

        GuestPersonAccountController.sendLoyaltyInformation(accountIds);
        
        Test.stopTest();
        
        Account updatedAccount = [SELECT Loyalty_Customer_ID__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('123456', updatedAccount.Loyalty_Customer_ID__c, 'The Loyalty Customer ID should be updated.');
    }


}