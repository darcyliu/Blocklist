//
//  PriorityQueue.h
//  PriorityQueue
//
//  Created by Darcy Liu on 2018/11/6.
//  Copyright © 2018 Darcy Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PriorityQueue<__covariant T> : NSObject
- (instancetype)initWithCapacity:(NSUInteger)numItems NS_DESIGNATED_INITIALIZER;

- (BOOL)isEmpty;
- (NSUInteger)size;
- (__kindof T)top;
- (void)push:(__kindof T)item;
- (void)pop;
- (NSArray<__kindof T> *)allObjects;
@end

NS_ASSUME_NONNULL_END
