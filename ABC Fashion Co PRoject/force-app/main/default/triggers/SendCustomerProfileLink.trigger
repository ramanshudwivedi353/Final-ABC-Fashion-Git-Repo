trigger SendCustomerProfileLink on Account (before insert, after insert) {
    // BEFORE INSERT: Assign unique tokens
    if (Trigger.isBefore && Trigger.isInsert) {
        System.debug('BEFORE INSERT executed' + Trigger.isExecuting);
        for (Account acc : Trigger.new) {
            if (acc.IsPersonAccount) {
                // Generate UUID
                String uniqueToken = String.valueOf(UUID.randomUUID());
                // Set the token on the account (before insert allows modification)
                acc.Profile_Access_Token__c = uniqueToken;
            }
        }
    }
    
    // AFTER INSERT: Queue the job to send the email and loyalty information
    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('AFTER INSERT executed' + Trigger.isExecuting);
        List<Id> accountIdsToProcess = new List<Id>();
        List<Account> accountsToProcess = new List<Account>();
        for (Account acc : Trigger.new) {
            if (acc.IsPersonAccount && acc.PersonEmail != null) {
                accountIdsToProcess.add(acc.Id);
                accountsToProcess.add(acc);
            }
        }
        

        // Call the future method to send loyalty information
        if (!accountIdsToProcess.isEmpty()) {
            GuestPersonAccountController.sendLoyaltyInformation(accountIdsToProcess);
            
            // Enqueue job to send profile link email
            System.enqueueJob(new SendProfileLinkJob(accountsToProcess));
        }
    }
}