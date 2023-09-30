//
//  PBRecord+CoreDataProperties.h
//  Blocklist
//
//  Created by Darcy Liu on 25/09/2022.
//
//

#import "PBRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface PBRecord (CoreDataProperties)

+ (NSFetchRequest<PBRecord *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nonatomic) BOOL blocked;
@property (nullable, nonatomic, copy) NSDate *created;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int64_t number;
@property (nonatomic) BOOL removed;
@property (nullable, nonatomic, copy) NSDate *updated;

@end

NS_ASSUME_NONNULL_END
