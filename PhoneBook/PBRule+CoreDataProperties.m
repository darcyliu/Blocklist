//
//  PBRule+CoreDataProperties.m
//  PhoneBook
//
//  Created by Darcy Liu on 16/11/2022.
//
//

#import "PBRule+CoreDataProperties.h"

@implementation PBRule (CoreDataProperties)

+ (NSFetchRequest<PBRule *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Rule"];
}

@dynamic action;
@dynamic created;
@dynamic pattern;
@dynamic subaction;
@dynamic type;
@dynamic updated;

@end
