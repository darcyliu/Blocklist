//
//  CallDirectoryHandler.m
//  CallDirectory
//
//  Created by Darcy Liu on 23/09/2022.
//

#import "CallDirectoryHandler.h"

#import <PhoneBook/PhoneBook.h>
#import "PriorityQueue.h"

#define LOAD_FROM_FILE 1

@interface PBCaller : NSObject {
}
@property (nonatomic, assign, readonly) int64_t phoneNumber;
@property (nonatomic, assign, readonly) BOOL removed;
@property (nonatomic, strong) NSString *name;

- (instancetype)initWithPhoneNumber:(int64_t)phoneNumber andName:(NSString *)name andRemoved:(BOOL)removed;
- (NSComparisonResult)compare:(PBCaller *)other;
@end

@implementation PBCaller
- (instancetype)initWithPhoneNumber:(int64_t)phoneNumber andName:(NSString *)name andRemoved:(BOOL)removed {
    if ((self = [super init])) {
        _phoneNumber = phoneNumber;
        _name = [name copy];
        _removed = removed;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%lld, %@, %d", _phoneNumber, _name, _removed];
}

- (NSComparisonResult)compare:(PBCaller *)other {
    if (_phoneNumber == other.phoneNumber)
        return NSOrderedSame;
    else if (_phoneNumber < other.phoneNumber)
        return NSOrderedAscending;
    else
        return NSOrderedDescending;
}
@end


@interface CallDirectoryHandler () <CXCallDirectoryExtensionContextDelegate>
{
    PriorityQueue<PBCaller *> *_blockingPq;
    PriorityQueue<PBCaller *> *_idPq;
}
@property (strong) PhoneBookManager *pbManager;
@end

@implementation CallDirectoryHandler

- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context {
    context.delegate = self;

    // Check whether this is an "incremental" data request. If so, only provide the set of phone number blocking
    // and identification entries which have been added or removed since the last time this extension's data was loaded.
    // But the extension must still be prepared to provide the full set of data at any time, so add all blocking
    // and identification phone numbers if the request is not incremental.
    NSLog(@"context.isIncremental: %d", context.isIncremental);
    
#ifdef LOAD_FROM_FILE
    PriorityQueue<PBCaller *> *blockingPq = [[PriorityQueue alloc] init];
    PriorityQueue<PBCaller *> *idPq = [[PriorityQueue alloc] init];
    
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.net.macspot.lma"];
    NSURL *url = [containerURL URLByAppendingPathComponent:@"callers.txt"];
    if ([[NSFileManager defaultManager]  fileExistsAtPath:url.path]) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *lines = [text componentsSeparatedByString:@"\n"];
        
        for (NSString *line in lines) {
            NSArray *colums = [line componentsSeparatedByString:@","];
            //NSLog(@"%@", line);
            if (colums.count < 4) {
                continue;
            }
            NSInteger type = [colums[0] integerValue];
            int64_t number = [colums[1] longLongValue];
            NSString *name = colums[2];
            BOOL removed = [colums[3] boolValue];
            if (type == 1) {
                [blockingPq push:[[PBCaller alloc] initWithPhoneNumber:number andName:name andRemoved:removed]];
            } else {
                [idPq push:[[PBCaller alloc] initWithPhoneNumber:number andName:name andRemoved:removed]];
            }
        }
    }
    
    _blockingPq = blockingPq;
    _idPq = idPq;
#else
    _pbManager = [PhoneBookManager new];
    [_pbManager.context refreshAllObjects];
#endif
    if (context.isIncremental) {
        [context removeAllBlockingEntries];
        [context removeAllIdentificationEntries];
        [self addOrRemoveIncrementalBlockingPhoneNumbersToContext:context];

        [self addOrRemoveIncrementalIdentificationPhoneNumbersToContext:context];
    } else {
        [self addAllBlockingPhoneNumbersToContext:context];

        [self addAllIdentificationPhoneNumbersToContext:context];
    }
    
    [context completeRequestWithCompletionHandler:^(BOOL expired) {
        NSLog(@"expired: %d", expired);
    }];
}

- (void)addAllBlockingPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Numbers must be provided in numerically ascending order.
#ifdef LOAD_FROM_FILE
    while([_blockingPq size] > 0) {
        PBCaller *pbCaller = [_blockingPq top];
        //NSLog(@"_blockingPq %@", pbCaller);
        [context addBlockingEntryWithNextSequentialPhoneNumber:pbCaller.phoneNumber];
        [_blockingPq pop];
    }
#else
    NSArray<PBRecord *> *records = [_pbManager getRecordsFor:YES includeRemoved:NO afterDate:nil];
    for(PBRecord *record in records) {
        //NSLog(@"record.number: %ld", record.number);
        [context addBlockingEntryWithNextSequentialPhoneNumber:record.number];
    }
#endif
}

- (void)addOrRemoveIncrementalBlockingPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve any changes to the set of phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Record the most-recently loaded set of blocking entries in data store for the next incremental load...
#ifdef LOAD_FROM_FILE
    while([_blockingPq size] > 0) {
        PBCaller *pbCaller = [_blockingPq top];
        //NSLog(@"Incremental _blockingPq %@", pbCaller);
        if (pbCaller.removed) {
            [context removeBlockingEntryWithPhoneNumber:pbCaller.phoneNumber];
        } else {
            [context addBlockingEntryWithNextSequentialPhoneNumber:pbCaller.phoneNumber];
        }
        [_blockingPq pop];
    }
#else
    NSArray<PBRecord *> *records = [_pbManager getRecordsFor:YES includeRemoved:YES afterDate:nil];
    for(PBRecord *record in records) {
        //NSLog(@"Incremental .number: %ld  %d", record.number,record.removed);
        if (record.removed) {
            [context removeBlockingEntryWithPhoneNumber:record.number];
        } else {
            [context addBlockingEntryWithNextSequentialPhoneNumber:record.number];
        }
    }
#endif
}

- (void)addAllIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Numbers must be provided in numerically ascending order.
#ifdef LOAD_FROM_FILE
    while([_idPq size] > 0) {
        PBCaller *pbCaller = [_idPq top];
        //NSLog(@"_idPq %@", pbCaller);
        if (pbCaller.name == nil || pbCaller.name.length == 0) {
            continue;
        }
        [context addIdentificationEntryWithNextSequentialPhoneNumber:pbCaller.phoneNumber label:pbCaller.name];
        [_idPq pop];
    }
#else
    NSArray<PBRecord *> *records = [_pbManager getRecordsFor:NO includeRemoved:NO afterDate:nil];
    for(PBRecord *record in records) {
        if (record.name.length == 0) {
            continue;
        }
        //NSLog(@"record.number: %ld record.name: %@", record.number, record.name);
        [context addIdentificationEntryWithNextSequentialPhoneNumber:record.number label:record.name];
    }
#endif
}

- (void)addOrRemoveIncrementalIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // Retrieve any changes to the set of phone numbers to identify (and their identification labels) from data store. For optimal performance and memory usage when there are many phone numbers,
    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
    //
    // Record the most-recently loaded set of identification entries in data store for the next incremental load...
#ifdef LOAD_FROM_FILE
    while([_idPq size] > 0) {
        PBCaller *pbCaller = [_idPq top];
        //NSLog(@"Incremental _idPq %@", pbCaller);
        if (pbCaller.name == nil || pbCaller.name.length == 0) {
            continue;
        }
        if (pbCaller.removed) {
            [context removeIdentificationEntryWithPhoneNumber:pbCaller.phoneNumber];
            
        } else {
            [context addIdentificationEntryWithNextSequentialPhoneNumber:pbCaller.phoneNumber label:pbCaller.name];
        }
        [_idPq pop];
    }
#else
    NSArray<PBRecord *> *records = [_pbManager getRecordsFor:NO includeRemoved:YES afterDate:nil];
    for(PBRecord *record in records) {
        //NSLog(@"Incremental .number: %ld record.name: %@ %d", record.number, record.name,record.removed);
        if (record.removed) {
            [context removeIdentificationEntryWithPhoneNumber:record.number];
        } else {
            [context addIdentificationEntryWithNextSequentialPhoneNumber:record.number label:record.name];
        }
    }
#endif
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
