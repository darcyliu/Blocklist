//
//  PriorityQueue.m
//  PriorityQueue
//
//  Created by Darcy Liu on 2018/11/6.
//  Copyright © 2018 Darcy Liu. All rights reserved.
//

#import "PriorityQueue.h"

const void *PQRetain(CFAllocatorRef allocator, const void *ptr) {
    return (__bridge_retained const void *)(__bridge id)ptr;
}
void PQRelease(CFAllocatorRef allocator, const void *ptr) {
    (void)(__bridge_transfer id)ptr;
}
CFComparisonResult PQCompare(const void *ptr1, const void *ptr2, void *unused) {
    if (![(__bridge id)ptr1 respondsToSelector:@selector(compare:)] ||
        ![(__bridge id)ptr2 respondsToSelector:@selector(compare:)] ) {
        return kCFCompareEqualTo;
    }
    return (CFComparisonResult)[(__bridge id)ptr1 compare:(__bridge id)ptr2];
}

@interface PriorityQueue()
{
    CFBinaryHeapRef _pq;
}
@end

@implementation PriorityQueue
- (instancetype)init
{
    return [self initWithCapacity:0];
}

- (instancetype)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        CFBinaryHeapCallBacks callBacks = {0, PQRetain, PQRelease, NULL, PQCompare};
        _pq = CFBinaryHeapCreate(NULL, numItems, &callBacks, NULL);
    }
    return self;
}

- (void)dealloc
{
    CFBinaryHeapRemoveAllValues(_pq);
    CFRelease(_pq);
}

- (BOOL)isEmpty
{
    return 0 == [self size];
}

- (NSUInteger)size
{
    return CFBinaryHeapGetCount(_pq);
}

- (__kindof id)top
{
    return (id)CFBinaryHeapGetMinimum(_pq);
}

- (void)push:(__kindof id)item
{
    CFBinaryHeapAddValue(_pq, (__bridge const void *)item);
}

- (void)pop
{
    CFBinaryHeapRemoveMinimumValue(_pq);
}

- (NSArray *)allObjects
{
    NSUInteger n = [self size];
    const void ** values = malloc(n * sizeof(const void *));
    CFBinaryHeapGetValues(_pq, values);
    CFArrayRef objects = CFArrayCreate(kCFAllocatorDefault, values, n, &kCFTypeArrayCallBacks);
    free(values);
    NSArray *items = (__bridge_transfer NSArray *)objects;
    return items;
}

@end
