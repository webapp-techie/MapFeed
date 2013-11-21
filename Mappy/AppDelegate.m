//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "FeedModel.h"
#import "DataStorage.h"

#define APP_ID @"fd725621c5e44198a5b8ad3f7a0ffa09"

@implementation AppDelegate
@synthesize userEmail,userId,userName;
@synthesize fbFeedReq, fbSession, facebook, facebookUserName, currentFaceBookID;
@synthesize instagram = _instagram;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.instagram = [[Instagram alloc] initWithClientId:APP_ID
                                                delegate:nil];
    self.instagram.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    self.instagram.sessionDelegate = self;
    [self authenticateFacebookWithoutUI];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //[FBSession.activeSession closeAndClearTokenInformation];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if (self.isFacebookHandle) {
        self.isInstagramHandle = NO;
        return [FBSession.activeSession handleOpenURL:url];
    }
    else if(self.isInstagramHandle)
    {
        self.isInstagramHandle = NO;
        return [self.instagram handleOpenURL:url];
    }
    return NO;
}


-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (self.isFacebookHandle) {
        self.isInstagramHandle = NO;
        return [FBSession.activeSession handleOpenURL:url];
    }
    else if(self.isInstagramHandle)
    {
        self.isInstagramHandle = NO;
        return [self.instagram handleOpenURL:url];
    }
    
    return NO;
}


-(void)authenticateFacebookWithoutUI
{
    if (!FBSession.activeSession.isOpen)
    {
        NSArray *permissions = [[NSArray alloc] initWithObjects:@"read_stream",@"user_photos",@"user_videos",nil];
        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"isInAuthenticationprocess"];
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
         {
             if (error)
             {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mappy" message:@"Facebook Login Failed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                 [alert show];
             }
             else if (FB_ISSESSIONOPENWITHSTATE(status))
             {
                 self.fbSession = session;
                 [FBSession setActiveSession:session];
                 [self requestToSetCurrentFacebookID];
                 
                 switch (status)
                 {
                     case FBSessionStateCreated:
                     {
                         NSLog(@"\nFBSessionStateCreated");
                         break;
                     }
                     case FBSessionStateCreatedTokenLoaded:
                     {
                         NSLog(@"\nFBSessionStateCreatedTokenLoaded");
                         break;
                     }
                     case FBSessionStateCreatedOpening:
                     {
                         NSLog(@"\nFBSessionStateCreatedOpening");
                         break;
                     }
                     case FBSessionStateOpen:
                     {
                         NSLog(@"\n%@",FBSession.activeSession.permissions);
                         NSLog(@"\nFBSessionStateOpen");
                         break;
                     }
                     case FBSessionStateOpenTokenExtended:
                     {
                         NSLog(@"\nFBSessionStateOpenTokenExtended");
                         break;
                     }
                     case FBSessionStateClosedLoginFailed:
                     {
                         [FBSession.activeSession closeAndClearTokenInformation];
                         NSLog(@"\nFBSessionStateClosedLoginFailed");
                         break;
                     }
                     case FBSessionStateClosed:
                     {
                         NSLog(@"\nFBSessionStateClosed");
                         break;
                     }
                     default:
                         break;
                 }
             }
         }];
    }
}


-(void)authenticateFacebookUser
{
    if (!FBSession.activeSession.isOpen)
    {
//        NSArray *permissions = [[NSArray alloc] initWithObjects:@"publish_actions",nil];
        NSArray *permissions = [[NSArray alloc] initWithObjects:@"read_stream",@"user_photos",@"user_videos",nil];

        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"isInAuthenticationprocess"];
        
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
         {
             if (error)
             {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mappy" message:@"Facebook Login Failed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                 [alert show];
             }
             else if (FB_ISSESSIONOPENWITHSTATE(status))
             {
                 self.fbSession = session;
                 
                 [FBSession setActiveSession:session];
                 [self requestToSetCurrentFacebookID];

                 switch (status)
                 {
                     case FBSessionStateCreated:
                     {
                         NSLog(@"\nFBSessionStateCreated");
                         break;
                     }
                     case FBSessionStateCreatedTokenLoaded:
                     {
                         NSLog(@"\nFBSessionStateCreatedTokenLoaded");
                         break;
                     }
                     case FBSessionStateCreatedOpening:
                     {
                         NSLog(@"\nFBSessionStateCreatedOpening");
                         break;
                     }
                     case FBSessionStateOpen:
                     {
                         NSLog(@"\n%@",FBSession.activeSession.permissions);
                         NSLog(@"\nFBSessionStateOpen");
                         break;
                     }
                     case FBSessionStateOpenTokenExtended:
                     {
                         NSLog(@"\nFBSessionStateOpenTokenExtended");
                         break;
                     }
                     case FBSessionStateClosedLoginFailed:
                     {
                         [FBSession.activeSession closeAndClearTokenInformation];
                         NSLog(@"\nFBSessionStateClosedLoginFailed");
                         break;
                     }
                     case FBSessionStateClosed:
                     {
                         NSLog(@"\nFBSessionStateClosed");
                         break;
                     }
                     default:
                         break;
                 }
             }
         }];
    }
}

-(void)requestToSetCurrentFacebookID
{
    FBRequest *me = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me"];
    [me startWithCompletionHandler:^(FBRequestConnection *connection,NSDictionary<FBGraphUser> *user, NSError *error) {
        [[NSUserDefaults standardUserDefaults] setValue:[user objectForKey:@"id"] forKey:facebookProfileID];
        [[NSUserDefaults standardUserDefaults] setValue:user.name forKey:facebookProfileName];
        facebookUserName = user.name;
        currentFaceBookID = [user objectForKey:@"id"];
    }];
}

-(void)logoutFacebook
{
    [self.fbSession closeAndClearTokenInformation];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:facebookProfileID];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:facebookProfileName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)twitterAccountnotSetMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mappy" message:@"Please setup at least one twitter account. Go to Settings->Twitter to setup account." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}


-(BOOL)isFacebookLogin
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    switch (delegate.fbSession.state)
    {
        case FBSessionStateCreated:
        {
            NSLog(@"\nFBSessionStateCreated");
            break;
        }
        case FBSessionStateCreatedTokenLoaded:
        {
            NSLog(@"\nFBSessionStateCreatedTokenLoaded");
            break;
        }
        case FBSessionStateCreatedOpening:
        {
            NSLog(@"\nFBSessionStateCreatedOpening");
            break;
        }
        case FBSessionStateOpen:
        {
            NSLog(@"\nFBSessionStateOpen");
            break;
        }
        case FBSessionStateOpenTokenExtended:
        {
            NSLog(@"\nFBSessionStateOpenTokenExtended");
            break;
        }
        case FBSessionStateClosedLoginFailed:
        {
            NSLog(@"\nFBSessionStateClosedLoginFailed");
            break;
        }
        case FBSessionStateClosed:
        {
            NSLog(@"\nFBSessionStateClosed");
            break;
        }
        default:
            break;
    }
    
    return (self.fbSession.isOpen);
}

-(void)igDidLogin {
    //Save Access Token
    [[NSUserDefaults standardUserDefaults] setObject:self.instagram.accessToken forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(void)igDidNotLogin:(BOOL)cancelled {
    NSString* message = nil;
    if (cancelled) {
        message = @"Access cancelled!";
    } else {
        message = @"Access denied!";
    }
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

-(void)igDidLogout {
    // remove the accessToken
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)igSessionInvalidated {
    NSLog(@"Instagram session was invalidated");
}

- (void)logoutInstagram
{
    [self.instagram logout];
}


@end
