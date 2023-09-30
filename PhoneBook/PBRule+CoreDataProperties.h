//
//  PBRule+CoreDataProperties.h
//  PhoneBook
//
//  Created by Darcy Liu on 16/11/2022.
//
//

#import "PBRule+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface PBRule (CoreDataProperties)

+ (NSFetchRequest<PBRule *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nonatomic) int16_t action;
@property (nullable, nonatomic, copy) NSDate *created;
@property (nullable, nonatomic, copy) NSString *pattern;
@property (nonatomic) int16_t subaction;
@property (nonatomic) int16_t type;
@property (nullable, nonatomic, copy) NSDate *updated;

@end

NS_ASSUME_NONNULL_END
