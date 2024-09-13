trigger SendCustomerProfileLink on Account (before insert, after insert, before update, after update) {

    // BEFORE INSERT: Assign unique tokens
    if (Trigger.isBefore && Trigger.isInsert) {
        System.debug('BEFORE INSERT executed: ' + Trigger.isExecuting);
        for (Account acc : Trigger.new) {
            if (acc.IsPersonAccount) {
                // Generate UUID
                String uniqueToken = String.valueOf(UUID.randomUUID());
                // Set the token on the account (before insert allows modification)
                acc.Profile_Access_Token__c = uniqueToken;
            }
        }
    }

   
    /*if (Trigger.isBefore && Trigger.isUpdate) {
        System.debug('BEFORE UPDATE executed: ' + Trigger.isExecuting);
        for (Account acc : Trigger.new) {
            if (acc.IsPersonAccount) {
                // Only update Profile Access Token if it's empty
                if (String.isBlank(acc.Profile_Access_Token__c)) {
                    String uniqueToken = String.valueOf(UUID.randomUUID());
                    acc.Profile_Access_Token__c = uniqueToken;
                }
            }
        }
    }*/

    // AFTER INSERT: Queue the job to send the email and loyalty information
    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('AFTER INSERT executed: ' + Trigger.isExecuting);
        List<Account> accountsToProcess = new List<Account>();
        for (Account acc : Trigger.new) {
            if (acc.IsPersonAccount && acc.PersonEmail != null) {
                accountsToProcess.add(acc);
            }
        }

        // Enqueue job to send profile link email (only after insert)
        if (!accountsToProcess.isEmpty()) {
            System.enqueueJob(new SendProfileLinkJob(accountsToProcess));
        }
    }

    // AFTER UPDATE: Call loyalty information method when the account is updated
    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('AFTER UPDATE executed: ' + Trigger.isExecuting);
        List<Id> accountIdsToProcess = new List<Id>();
		system.debug('Trigger.new===>'+Trigger.new);
        for (Account acc : Trigger.new) {
            system.debug('inside for loop ===>');
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            // Call the method when loyalty information needs to be sent (PersonAccount, valid email, and token is updated)
            if (acc.IsPersonAccount && acc.PersonEmail != null && acc.Profile_Access_Token__c == oldAcc.Profile_Access_Token__c) {
                accountIdsToProcess.add(acc.Id);
            }
        }
		system.debug(' accountIdsToProcess====>'+accountIdsToProcess);
        // Call the future method to send loyalty information on update
        if (!accountIdsToProcess.isEmpty()) {
            if(!System.isFuture()){
                GuestPersonAccountController.sendLoyaltyInformation(accountIdsToProcess);
            }
        }
    }
}
