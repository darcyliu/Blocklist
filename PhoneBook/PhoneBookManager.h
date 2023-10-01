//
//  PhoneBookManager.h
//  PhoneBook
//
//  Created by Darcy Liu on 24/09/2022.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <IdentityLookup/IdentityLookup.h>

typedef NS_ENUM(NSUInteger, PBRuleType) {
    PBRuleTypeAny = 0,
    PBRuleTypeSender = 1,
    PBRuleTypeMessage = 2,
};
 
typedef NS_ENUM(NSUInteger, PBRuleAction) {
    PBRuleActionNone = ILMessageFilterActionNone,
    PBRuleActionAllow = ILMessageFilterActionAllow,
    PBRuleActionJunk = ILMessageFilterActionJunk,
    PBRuleActionPromotion = ILMessageFilterActionPromotion,
    PBRuleActionTransaction = ILMessageFilterActionTransaction,
};

NS_ASSUME_NONNULL_BEGIN

@interface PhoneBookManager : NSObject
//- (instancetype)init NS_UNAVAILABLE;
//- (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

- (NSManagedObjectContext *)context;

- (void)saveContext ;

- (NSFetchRequest *)fetchRequest:(BOOL)blocked withRemoved:(BOOL)includeRemoved afterDate:(nullable NSDate *)date;

- (NSArray *)getRecordsFor:(BOOL)blocked includeRemoved:(BOOL)includeRemoved afterDate:(nullable NSDate *)date;
- (NSArray *)getRecordsForPhoneNumber:(NSNumber *)number;
- (void)removeAllDeletedRecords;
- (NSFetchRequest *)fetchRequestForCallers;
- (NSFetchRequest *)fetchRequestForRules;
- (NSArray *)getRules;
- (NSArray *)getRulesForPattern:(NSString *)pattern type:(NSInteger)type action:(NSInteger)action subaction:(NSInteger)subaction;
- (NSArray *)getRulesForPattern:(NSString *)pattern;

- (void)exportAllCallers;
- (NSURL *_Nullable)exportCallers;
- (NSURL *_Nullable)exportRules;
- (void)addOrUpdateCallNumber:(NSNumber *)phoneNumber withName:(NSString *)name andBlocked:(BOOL)blocked;
- (void)importFile:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
