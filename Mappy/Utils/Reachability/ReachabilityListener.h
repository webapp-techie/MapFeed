#import <Foundation/Foundation.h>
#import "Reachability.h"

extern NSString* kDidStartOfflineModeNotification;
extern NSString* kDidEndOfflineModeNotification;


/**
 @brief Reachability listener service
 */
@interface ReachabilityListener : NSObject 

@property (nonatomic, strong) Reachability *reachability;

- (id)initWithReachability:(Reachability *)aReachability;

+ (BOOL)isOfflineModeActive;

@end


