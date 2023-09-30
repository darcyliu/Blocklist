//
//  MessageFilterExtension.m
//  MessageFilter
//
//  Created by Darcy Liu on 24/09/2022.
//

#import "MessageFilterExtension.h"
#import <PhoneBook/PhoneBook.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_16_0
@interface MessageFilterExtension () <ILMessageFilterQueryHandling, ILMessageFilterCapabilitiesQueryHandling>
@end
#else
@interface MessageFilterExtension () <ILMessageFilterQueryHandling>
@end
#endif

@implementation MessageFilterExtension
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_16_0
- (void)handleCapabilitiesQueryRequest:(ILMessageFilterCapabilitiesQueryRequest *)capabilitiesQueryRequest context:(ILMessageFilterExtensionContext *)context completion:(void (^)(ILMessageFilterCapabilitiesQueryResponse *))completion {
    ILMessageFilterCapabilitiesQueryResponse *response = [[ILMessageFilterCapabilitiesQueryResponse alloc] init];
    
    // TODO: Update subActions from ILMessageFilterSubAction enum
    // response.transactionalSubActions = @[ ... ];
    // response.promotionalSubActions = @[ ... ]
    
    completion(response);
}
#endif

- (void)handleQueryRequest:(ILMessageFilterQueryRequest *)queryRequest context:(ILMessageFilterExtensionContext *)context completion:(void (^)(ILMessageFilterQueryResponse *))completion {
    // First, check whether to filter using offline data (if possible).
    ILMessageFilterAction offlineAction = [self offlineActionForQueryRequest:queryRequest];
    switch (offlineAction) {
        case ILMessageFilterActionAllow:
        case ILMessageFilterActionJunk:
        case ILMessageFilterActionPromotion:
        case ILMessageFilterActionTransaction: {
            // Based on offline data, we know this message should either be Allowed, Filtered as Junk, Promotional or Transactional. Send response immediately.
            ILMessageFilterQueryResponse *response = [[ILMessageFilterQueryResponse alloc] init];
            response.action = offlineAction;
            
            completion(response);
            break;
        }
        case ILMessageFilterActionNone: {
            ILMessageFilterQueryResponse *response = [[ILMessageFilterQueryResponse alloc] init];
            response.action = offlineAction;
            
            completion(response);
            break;
        }
        default: {
            ILMessageFilterQueryResponse *response = [[ILMessageFilterQueryResponse alloc] init];
            response.action = ILMessageFilterActionNone;
            
            completion(response);
            break;
        }
    }
}
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_16_0
- (void)getOfflineAction:(ILMessageFilterAction *)offlineAction andOfflineSubAction:(ILMessageFilterSubAction *)offlineSubAction forQueryRequest:(ILMessageFilterQueryRequest *)queryRequest {
    NSParameterAssert(offlineAction != NULL);
    NSParameterAssert(offlineSubAction != NULL);
    
    // TODO: Replace with logic to perform offline check whether to filter first (if possible).
    
    *offlineAction = ILMessageFilterActionNone;
    *offlineSubAction = ILMessageFilterSubActionNone;
}

- (void)getNetworkAction:(ILMessageFilterAction *)networkAction andNetworkSubAction:(ILMessageFilterSubAction *)networkSubAction forNetworkResponse:(ILNetworkResponse *)networkResponse {
    NSParameterAssert(networkAction != NULL);
    NSParameterAssert(networkSubAction != NULL);
    
    // TODO: Replace with logic to parse the HTTP response and data payload of `networkResponse` to return an action.
    
    *networkAction = ILMessageFilterActionNone;
    *networkSubAction = ILMessageFilterSubActionNone;
}
#else
- (ILMessageFilterAction)offlineActionForQueryRequest:(ILMessageFilterQueryRequest *)queryRequest {
    NSString *message = queryRequest.messageBody;
    NSString *sender = queryRequest.sender;
    NSArray<PBRule *> *rules = [[PhoneBookManager sharedInstance] getRules];
    for(PBRule *rule in rules) {
        switch(rule.type) {
            case PBRuleTypeAny:
                if ([sender containsString: rule.pattern] || [message containsString: rule.pattern]) {
                    return (ILMessageFilterAction)rule.action;
                }
                break;
            case PBRuleTypeSender:
                if ([sender containsString: rule.pattern]) {
                    return (ILMessageFilterAction)rule.action;
                }
                break;
            case PBRuleTypeMessage:
                if ([message containsString: rule.pattern]) {
                    return (ILMessageFilterAction)rule.action;
                }
                break;
        }
    }
    
    return ILMessageFilterActionNone;
}

- (ILMessageFilterAction)actionForNetworkResponse:(ILNetworkResponse *)networkResponse {
    return ILMessageFilterActionNone;
}
#endif
@end
