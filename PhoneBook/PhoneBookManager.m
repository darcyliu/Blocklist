//
//  PhoneBookManager.m
//  PhoneBook
//
//  Created by Darcy Liu on 24/09/2022.
//

#import "PhoneBookManager.h"
#import "PBRule+CoreDataProperties.h"
#import "PBRecord+CoreDataProperties.h"

#ifndef DEBUG
#define NSLog(...)
#endif

@interface PhoneBookManager()
@property (readonly, strong) NSPersistentContainer *persistentContainer;
@end

@implementation PhoneBookManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
    
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            NSString *momdName = @"Blocklist";
            NSString *dbName = @"db.sqlite";
            NSString *groupName = @"group.net.macspot.lma";
        
            NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:momdName withExtension:@"momd"];
            NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupName];
            NSURL *dbURL = [containerURL URLByAppendingPathComponent:dbName];
            NSPersistentStoreDescription *storeDescription = [[NSPersistentStoreDescription alloc] initWithURL:dbURL];
            NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:momdName managedObjectModel:model];
            _persistentContainer.persistentStoreDescriptions = @[storeDescription];
            
            //_persistentContainer = [[NSPersistentContainer alloc] initWithName:@"Blocklist"];
            
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

- (NSManagedObjectContext *)context {
    return self.persistentContainer.viewContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

#pragma mark -
- (NSFetchRequest *)fetchRequestForCallers {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Record"];

    NSMutableArray<NSPredicate *> *predicates = [[NSMutableArray alloc] initWithCapacity:3];
    [predicates addObject:[NSPredicate predicateWithFormat:@"removed == NO"]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"blocked == YES"]];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [request setPredicate:compoundPredicate];
    
    NSSortDescriptor *sortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    return request;
}

- (NSFetchRequest *)fetchRequest:(BOOL)blocked withRemoved:(BOOL)includeRemoved afterDate:(NSDate *)date {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Record"];

    NSMutableArray<NSPredicate *> *predicates = [[NSMutableArray alloc] initWithCapacity:3];
    
    if (blocked) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blocked == YES"];
        [predicates addObject:predicate];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blocked == NO"];
        [predicates addObject:predicate];
    }
    
    if (includeRemoved) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"removed == YES"];
        [predicates addObject:predicate];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"removed == NO"];
        [predicates addObject:predicate];
    }
    
    if (date) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"updated > %@", date];
        [predicates addObject:predicate];
    }
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [request setPredicate:compoundPredicate];
    
    NSSortDescriptor *phoneNumberSort = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
    [request setSortDescriptors:@[phoneNumberSort]];
    
    return request;
}

- (NSArray *)getRecordsFor:(BOOL)blocked includeRemoved:(BOOL)includeRemoved afterDate:(NSDate *)date {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [self fetchRequest:blocked withRemoved:includeRemoved afterDate:date];
    NSArray *results = [context executeFetchRequest:request error:&error];
    return results;
}

- (NSArray *)getRecordsForPhoneNumber:(NSNumber *)number {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Record"];

    NSMutableArray<NSPredicate *> *predicates = [[NSMutableArray alloc] initWithCapacity:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number = %@", number];
    [predicates addObject:predicate];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [request setPredicate:compoundPredicate];
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    return results;
}

- (void)removeAllDeletedRecords {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Record"];

    NSMutableArray<NSPredicate *> *predicates = [[NSMutableArray alloc] initWithCapacity:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"removed == YES"];
    [predicates addObject:predicate];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [request setPredicate:compoundPredicate];
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    for (PBRecord *record in results) {
        NSLog(@"delete: %lld", record.number);
        [context deleteObject:record];
    }
    [context save:&error];
}

- (NSFetchRequest *)fetchRequestForRules {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Rule"];
    NSSortDescriptor *createdTimeSort = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO];
    [request setSortDescriptors:@[createdTimeSort]];
    return request;
}

- (NSArray *)getRules {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [self fetchRequestForRules];
    NSArray *results = [context executeFetchRequest:request error:&error];
    return results;
}

- (NSArray *)getRulesForPattern:(NSString *)pattern type:(NSInteger)type action:(NSInteger)action subaction:(NSInteger)subaction {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Rule"];

    NSMutableArray<NSPredicate *> *predicates = [[NSMutableArray alloc] initWithCapacity:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pattern = %@ AND type = %d AND action = %d", pattern, type, action];
    [predicates addObject:predicate];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [request setPredicate:compoundPredicate];
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    return results;
}

- (NSArray *)getRulesForPattern:(NSString *)pattern {
    NSError *error = nil;
    NSManagedObjectContext *context = self.context;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Rule"];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pattern = %@"];
    [request setPredicate:predicate];
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    return results;
}

- (void)exportAllCallers {
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.net.macspot.lma"];
    NSURL *url = [containerURL URLByAppendingPathComponent:@"callers.txt"];

    NSMutableArray *contents = [[NSMutableArray alloc] init];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    [results addObjectsFromArray: [self getRecordsFor:YES includeRemoved:YES afterDate:nil]];
    [results addObjectsFromArray: [self getRecordsFor:NO includeRemoved:YES afterDate:nil]];

    for(PBRecord *r in results) {
        //NSLog(@"name: %@ %lld blocked:%d removed:%d %@ %@", r.name, r.number, r.blocked, r.removed,r.created, r.updated);
        [contents addObject:[NSString stringWithFormat:@"%d,%lld,%@,%d", r.blocked, r.number, r.name, r.removed]];
    }

    NSError *error;
    NSString *content = [contents componentsJoinedByString:@"\n"];
    [content writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error writing file at %@\n%@", url, [error localizedFailureReason]);
    }
}

- (NSURL *)exportCallers {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"YYYYMMddmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@/LMA-caller-%@.blc", documentsDirectory, [dateFormatter stringFromDate:[NSDate date]]];
    NSMutableArray *contents = [[NSMutableArray alloc] init];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    [results addObjectsFromArray: [self getRecordsFor:YES includeRemoved:NO afterDate:nil]];
    [results addObjectsFromArray: [self getRecordsFor:NO includeRemoved:NO afterDate:nil]];
    
    for(PBRecord *r in results) {
        //NSLog(@"name: %@ %lld blocked:%d removed:%d %@ %@", r.name, r.number, r.blocked, r.removed,r.created, r.updated);
        [contents addObject:[NSString stringWithFormat:@"%d,%lld,%@", r.blocked, r.number, r.name]];
    }
    
    NSError *error;
    NSString *content = [contents componentsJoinedByString:@"\n"];
    [content writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error writing file at %@\n%@", fileName, [error localizedFailureReason]);
    } else {
        NSURL *url = [NSURL fileURLWithPath:fileName];
        return url;
    }
    return nil;
}

- (NSURL *)exportRules {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"MMddYYYYmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@/LMA-rules-%@.blm", documentsDirectory, [dateFormatter stringFromDate:[NSDate date]]];
    NSMutableArray *contents = [[NSMutableArray alloc] init];
    
    NSArray<PBRule *> *rules = [self getRules];
    for(PBRule *rule in rules) {
        //NSLog(@"%d,%@,%d,%d", rule.type, rule.pattern, rule.action, rule.subaction);
        [contents addObject:[NSString stringWithFormat:@"%d,%@,%d,%d", rule.type, rule.pattern, rule.action, rule.subaction]];
    }
    
    NSError *error;
    NSString *content = [contents componentsJoinedByString:@"\n"];
    [content writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error writing file at %@\n%@", fileName, [error localizedFailureReason]);
    } else {
        NSURL *url = [NSURL fileURLWithPath:fileName];
        return url;
    }
    return nil;
}

- (void)importMessageFilterRules:(NSURL *)url {
    if ([url startAccessingSecurityScopedResource]){
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *lines = [text componentsSeparatedByString:@"\n"];
        
        for (NSString *line in lines) {
            NSArray *colums = [line componentsSeparatedByString:@","];
            NSLog(@"%@", colums);
            if (colums.count < 4) {
                continue;
            }
            NSInteger type = [colums[0] integerValue];
            NSString *pattern = colums[1];
            NSInteger action = [colums[2] integerValue];
            NSInteger subaction = [colums[3] integerValue];
            
            //NSLog(@"%d,%@,%d,%d", rule.type, rule.pattern, rule.action, rule.subaction);
            NSArray *records = [self getRulesForPattern:pattern type:type action:action subaction:subaction];
            if (records.count == 0) {
                NSManagedObjectContext *context = self.context;
                PBRule *rule = [NSEntityDescription insertNewObjectForEntityForName:@"Rule" inManagedObjectContext:context];
                rule.type = type;
                rule.action = action;
                rule.pattern = pattern;
                rule.created = [NSDate date];
                rule.updated = [NSDate date];
                [context save:nil];
            } else {
                NSLog(@"rule exists.");
            }
        }
    } else {
        NSLog(@"unable to read.");
    }
    [url stopAccessingSecurityScopedResource];
}

- (void)importCallers:(NSURL *)url {
    if ([url startAccessingSecurityScopedResource]){
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *lines = [text componentsSeparatedByString:@"\n"];
        
        for (NSString *line in lines) {
            NSArray *colums = [line componentsSeparatedByString:@","];
            NSLog(@"%@", colums);
            if (colums.count < 3) {
                continue;
            }
            NSInteger type = [colums[0] integerValue];
            NSInteger number = [colums[1] integerValue];
            NSString *name = colums[2];
            NSLog(@"type: %ld number: %ld name: %@", (long)type, number, name);
            NSNumber *phoneNumber = [[NSNumber alloc] initWithInteger: number];
            [self addOrUpdateCallNumber:phoneNumber withName:name andBlocked:type==1];
        }
    } else {
        NSLog(@"Unable to read.");
    }
    [url stopAccessingSecurityScopedResource];
}

- (void)addOrUpdateCallNumber:(NSNumber *)phoneNumber withName:(NSString *)name andBlocked:(BOOL)blocked {
    NSArray *records = [self getRecordsForPhoneNumber:phoneNumber];
    PBRecord *record = nil;
    NSManagedObjectContext *context = self.context;
    if (records.count == 0) {
        record = [NSEntityDescription insertNewObjectForEntityForName:@"Record" inManagedObjectContext:context];
        record.created = [NSDate date];
    } else {
        record = [records firstObject];
    }
    record.name =  name;
    record.number = [phoneNumber integerValue];
    record.blocked = blocked;
    record.removed = NO;
    record.updated = [NSDate date];
    [context save:nil];
}

- (void)importFile:(NSURL *)url {
    if ([url.pathExtension isEqual:@"blc"]) {
        [self importCallers:url];
    } else if ([url.pathExtension isEqual:@"blm"]) {
        [self importMessageFilterRules:url];
    } else {
        NSLog(@"Unable to recognize the imported file.");
    }
}
@end
