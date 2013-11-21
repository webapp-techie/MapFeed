#import "ReachabilityListener.h"

NSString* kDidStartOfflineModeNotification = @"kDidStartOfflineModeNotification";
NSString* kDidEndOfflineModeNotification = @"kDidEndOfflineModeNotification";

static const NSTimeInterval kDoubleCheckTimeInterval=2.0f;

static BOOL isInOfflineMode;

@interface ReachabilityListener (Private)

-(void)checkCurrentReachability;

-(void)startOffline;
-(void)stopOffline;

@end

@implementation ReachabilityListener
{
    BOOL isFirtsUpdate;
}

@synthesize reachability = _reachability;

#pragma mark - Initialization

- (id)initWithReachability:(Reachability *)aReachability {
    self = [super init];
    if(self) {
        isInOfflineMode=NO;
        isFirtsUpdate=YES;
        self.reachability=aReachability;
    }
    return self;
}

#pragma mark - Accessors

- (void)setReachability:(Reachability *)aReachability
{
    if(_reachability == aReachability)
        return;
    if (_reachability)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:_reachability];
    }
    
    _reachability = aReachability;
    if(_reachability) 
    {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(didChangeReachability:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:_reachability];
        [self checkCurrentReachability];
    }
}

#pragma mark - Notifications

- (void)didChangeReachability:(NSNotification *)n {
    NSLog(@"reachability notification: %@",n);
    if (!isFirtsUpdate)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCurrentReachability) object:nil];
        [self performSelector:@selector(checkCurrentReachability) withObject:nil afterDelay:kDoubleCheckTimeInterval];
    }
    else {
        isFirtsUpdate=NO;
        [self checkCurrentReachability];
    }
    
}

#pragma mark - Private

-(void)checkCurrentReachability
{
    if ([_reachability currentReachabilityStatus]==NotReachable&&!isInOfflineMode)
    {
        [self startOffline];
    }
    else if([_reachability currentReachabilityStatus]!=NotReachable&&isInOfflineMode)
    {
        [self stopOffline];
    }
}

-(void)startOffline
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    isInOfflineMode=YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidStartOfflineModeNotification object:self];
}

-(void)stopOffline
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    isInOfflineMode=NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidEndOfflineModeNotification object:self];
}

#pragma mark - Public

+ (BOOL)isOfflineModeActive
{
    return isInOfflineMode;
}

@end
