global without sharing class GuestPersonAccountController {

    Public static boolean isUpdateDone = false;
    // Method to get Person Account record by token
    @AuraEnabled
    global static Account getPersonAccount(String token) {
        System.debug('Token received: ' + token);
        
        if (String.isBlank(token)) {
            System.debug('Token is null or empty.');
            throw new AuraHandledException('Invalid token provided.');
        }

        List<Account> accounts = [
            SELECT Id, FirstName, LastName, Phone, PersonEmail, T_shirt_size__c, Shoe_size__c, Customer_Date_Of_Birth__c, IsPersonAccount, Profile_Access_Token__c
            FROM Account 
            WHERE Profile_Access_Token__c = :token AND IsPersonAccount = TRUE LIMIT 1
        ];
        
        if (accounts.isEmpty()) {
            System.debug('No person account found for token: ' + token);
            throw new AuraHandledException('No person account found for the provided token.');
        }
        
        System.debug('Person Account found: ' + JSON.serialize(accounts[0]));
        return accounts[0];
    }

    // Method to update Person Account record
    @AuraEnabled
    global static void updatePersonAccount(Account updatedAccount) {
        System.debug('Received updated account: ' + JSON.serialize(updatedAccount));

        if (updatedAccount == null || updatedAccount.Id == null) {
            System.debug('Invalid account details provided');
            throw new AuraHandledException('Invalid account details provided.');
        }

        try {
            // Only update the necessary fields
            Account accountToUpdate = [SELECT Id, Profile_Completed__c FROM Account WHERE Id = :updatedAccount.Id LIMIT 1];
            accountToUpdate.Profile_Completed__c = true;

            // Copy necessary fields from the input account
            accountToUpdate.FirstName = updatedAccount.FirstName;
            accountToUpdate.LastName = updatedAccount.LastName;
            accountToUpdate.Phone = updatedAccount.Phone;
            accountToUpdate.PersonEmail = updatedAccount.PersonEmail;
            accountToUpdate.T_shirt_size__c = updatedAccount.T_shirt_size__c;
            accountToUpdate.Shoe_size__c = updatedAccount.Shoe_size__c;
            accountToUpdate.Customer_Date_Of_Birth__c = updatedAccount.Customer_Date_Of_Birth__c;

            // Perform DML update
            update accountToUpdate;
            System.debug('Account successfully updated');
        } catch (DmlException e) {
            System.debug('Error updating account: ' + e.getMessage());
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
    }

    // FUTURE METHOD for sending Loyalty Information asynchronously
    @future(callout=true)
    public static void sendLoyaltyInformation(List<Id> accountIds) {
        system.debug('inside future method');
        if (accountIds == null || accountIds.isEmpty()) {
            System.debug('No account IDs provided.');
            return;
        }

        List<Account> updatedAccounts = [SELECT Id, PersonEmail, T_shirt_size__c, Shoe_size__c FROM Account WHERE Id IN :accountIds];
        Http http = new Http();
		
        for (Account updatedAccount : updatedAccounts) {
            try {
                // Prepare the request body for each account
                String jsonBody = JSON.serialize(new Map<String, Object>{
                    'email' => updatedAccount.PersonEmail,
                    'tshirtSize' => updatedAccount.T_shirt_size__c,
                    'shoeSize' => updatedAccount.Shoe_size__c
                });

                // Create an HTTP request for each account
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://integrations.commutatus.com/webhook/719ce78d-c2c5-47a8-986a-39d7e7a5652d');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonBody);
                System.debug('jsonBody====> ' + jsonBody);

                // Send the request
                HttpResponse res = http.send(req);
				
                if (res.getStatusCode() == 200) {
                    // Parse the response if successful
                    Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    System.debug('JSON.serialized(resMap)======>' + JSON.serialize(resMap));

                    if (resMap.get('status') == 'success' && resMap.containsKey('customer_id')) {
                        updatedAccount.Loyalty_Customer_ID__c = String.valueOf(resMap.get('customer_id'));
                        system.debug('updatedAccount====>'+ JSON.serialize(updatedAccount));
                    } else {
                        System.debug('Error in response: ' + JSON.serialize(res.getBody()));
                    }
                } else {
                    System.debug('Error in response: ' + JSON.serialize(res.getBody()));
                }
            } catch (Exception e) {
                System.debug('Error sending loyalty information: ' + e.getMessage());
            }
        }
        if(isUpdateDone == false){
            isUpdateDone = true;
            system.debug('JSON.serialize(updatedAccounts)===>'+JSON.serialize(updatedAccounts));
            update updatedAccounts; // Save the Loyalty Customer ID
        }
         
    }
}
