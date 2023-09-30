//
//  PBRecord+CoreDataProperties.m
//  Blocklist
//
//  Created by Darcy Liu on 25/09/2022.
//
//

#import "PBRecord+CoreDataProperties.h"

@implementation PBRecord (CoreDataProperties)

+ (NSFetchRequest<PBRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Record"];
}

@dynamic blocked;
@dynamic created;
@dynamic name;
@dynamic number;
@dynamic removed;
@dynamic updated;

@end
