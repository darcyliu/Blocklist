//
//  CallDirectoryHandler.m
//  CallDirectory
//
//  Created by Darcy Liu on 23/09/2022.
//

#import "CallDirectoryHandler.h"

#import <PhoneBook/PhoneBook.h>

@interface CallDirectoryHandler () <CXCallDirectoryExtensionContextDelegate>
@end

@implementation CallDirectoryHandler

- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context {
    context.delegate = self;

    // Check whether this is an "incremental" data request. If so, only provide the set of phone number blocking
    // and identification entries which have been added or removed since the last time this extension's data was loaded.
    // But the extension must still be prepared to provide the full set of data at any time, so add all blocking
    // and identification phone numbers if the request is not incremental.
    if (context.isIncremental) {
        [context removeAllBlockingEntries];
        [context removeAllIdentificationEntries];
        [self addOrRemoveIncrementalBlockingPhoneNumbersToContext:context];

        [self addOrRemoveIncrementalIdentificationPhoneNumbersToContext:context];
    } else {
        [self addAllBlockingPhoneNumbersToContext:context];

        [self addAllIdentificationPhoneNumbersToContext:context];
    }
    
    [context completeRequestWithCompletionHandler:nil];
}

- (void)addAllBlockingPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Numbers must be provided in numerically ascending order.
    NSArray<PBRecord *> *records = [[PhoneBookManager sharedInstance] getRecordsFor:YES includeRemoved:NO afterDate:nil];
    for(PBRecord *record in records) {
        [context addBlockingEntryWithNextSequentialPhoneNumber:record.number];
    }
}

- (void)addOrRemoveIncrementalBlockingPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve any changes to the set of phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Record the most-recently loaded set of blocking entries in data store for the next incremental load...
    NSArray<PBRecord *> *records = [[PhoneBookManager sharedInstance] getRecordsFor:YES includeRemoved:YES afterDate:nil];
    for(PBRecord *record in records) {
        if (record.removed) {
            [context removeBlockingEntryWithPhoneNumber:record.number];
        } else {
            [context addBlockingEntryWithNextSequentialPhoneNumber:record.number];
        }
    }
}

- (void)addAllIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Numbers must be provided in numerically ascending order.
    NSArray<PBRecord *> *records = [[PhoneBookManager sharedInstance] getRecordsFor:NO includeRemoved:NO afterDate:nil];
    for(PBRecord *record in records) {
        [context addIdentificationEntryWithNextSequentialPhoneNumber:record.number label:record.name];
    }
}

- (void)addOrRemoveIncrementalIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve any changes to the set of phone numbers to identify (and their identification labels) from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Record the most-recently loaded set of identification entries in data store for the next incremental load...
    NSArray<PBRecord *> *records = [[PhoneBookManager sharedInstance] getRecordsFor:NO includeRemoved:YES afterDate:nil];
    for(PBRecord *record in records) {
        if (record.removed) {
            [context removeIdentificationEntryWithPhoneNumber:record.number];
        } else {
            [context addIdentificationEntryWithNextSequentialPhoneNumber:record.number label:record.name];
        }
    }
}

#pragma mark - CXCallDirectoryExtensionContextDelegate

- (void)requestFailedForExtensionContext:(CXCallDirectoryExtensionContext *)extensionContext withError:(NSError *)error {
    // An error occurred while adding blocking or identification entries, check the NSError for details.
    // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
    //
    // This may be used to store the error details in a location accessible by the extension's containing app, so that the
    // app may be notified about errors which occurred while loading data even if the request to load data was initiated by
    // the user in Settings instead of via the app itself.
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:nil];
    
    [userDefaults setObject:error forKey:@"LastError"];
    [userDefaults synchronize];
}

@end
