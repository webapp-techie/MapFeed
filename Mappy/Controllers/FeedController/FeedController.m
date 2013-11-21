//
//  FeedController.m
//

#import "FeedController.h"
#import "AppDelegate.h"
#import "FbCell.h"
#import "TwitterCell.h"
#import "VineCell.h"
#import "IgCell.h"
#import <Twitter/Twitter.h>
//#import <FacebookSDK/FacebookSDK.h>

NSString *const FBSessionStateChangedNotification = @"FBSessionStateChangedNotification";

@interface FeedController ()

@end

@implementation FeedController

@synthesize isOffline;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    selectedIndex = [[NSIndexPath alloc] init];
    isRowAlreadySelected = NO;
    
    [self isFacebookLogin];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)sendemail{
    MFMailComposeViewController *composer=[[MFMailComposeViewController alloc]init];
    [composer setMailComposeDelegate:self];
    if ([MFMailComposeViewController canSendMail]) {
        [composer setToRecipients:[NSArray arrayWithObjects:@"mappy@gmail.com", nil]];
        [composer setSubject:@"Feedback"];
        
        //    [composer.setSubject.placeholder = [NSLocalizedString(@"This is a placeholder",)];
        
        [composer setMessageBody:@"" isHTML:NO];
        [composer setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
//        [self presentModalViewController:composer animated:YES];
        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"error" message:[NSString stringWithFormat:@"error %@",[error description]] delegate:nil cancelButtonTitle:@"dismiss" otherButtonTitles:nil, nil];
        [alert show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark
#pragma mark - Event Handlers

- (IBAction)onContactUs:(id)sender {
    [self sendemail];
}

- (IBAction)onFeedback:(id)sender {
    [self sendemail];
}

- (IBAction)performBackOperation:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)fbValueChanged:(id)sender {
    UISwitch *switchButton = (UISwitch *)sender;
    if (switchButton.isOn) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.isFacebookHandle = YES;
        [delegate authenticateFacebookUser];
    }
    else
    {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate logoutFacebook];
    }
}

- (IBAction)twitterValueChanged:(id)sender {

    UISwitch *switchButton = (UISwitch *)sender;
    if (switchButton.isOn) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate twitterAccountnotSetMessage];
        [switchButton setOn:NO];
    }
}


- (IBAction)igValueChanged:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UISwitch *switchButton = (UISwitch *)sender;
    if (switchButton.isOn) {
        appDelegate.instagram.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
        appDelegate.instagram.sessionDelegate = appDelegate;
        if ([appDelegate.instagram isSessionValid]) {
            //success login
            
        } else {
            //authorize use
            appDelegate.isInstagramHandle = YES;
            [appDelegate.instagram authorize:[NSArray arrayWithObjects:@"comments", @"likes", nil]];
        }
    }
    else
    {
        [appDelegate logoutInstagram];
    }
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
    
    return (delegate.fbSession.isOpen);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"";
    
    if (indexPath.row == 0) {
        identifier = @"fbCell";
        
        FbCell *cell = (FbCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if(cell == nil)
        {
            cell = [[FbCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        
        if ([self isFacebookLogin]) {
            [cell.swtFb setOn:YES];
        }
        else
        {
            [cell.swtFb setOn:NO];
        }
        
        return cell;
    }
    else if (indexPath.row == 1) {
        identifier = @"twitterCell";
        
        TwitterCell *cell = (TwitterCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if(cell == nil)
        {
            cell = [[TwitterCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        
        //if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        if ([TWTweetComposeViewController canSendTweet])
        {
            [cell.swtTwitter setOn:YES];
        }
        else
        {
            [cell.swtTwitter setOn:NO];
        }
        return cell;
    }
    else if (indexPath.row == 2) {
        identifier = @"igCell";
        
        IgCell *cell = (IgCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        
        if(cell == nil)
        {
            cell = [[IgCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([appDelegate.instagram isSessionValid])
        {
            [cell.swtIg setOn:YES];
        }
        else
        {
            [cell.swtIg setOn:NO];
        }
        return cell;
    }
    
    
    return 0;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell configured");
}

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([selectedIndex isEqual:indexPath])
    {
        NSLog(@"height for index path :%@",selectedIndex);
        if(!isRowAlreadySelected) {
            isRowAlreadySelected = YES;
            return kTableCellSelectedHeight;
        }else {
            isRowAlreadySelected = NO;
            return kTableCellHeight;
        }
    }
    else
    {
        return kTableCellHeight;
    }
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will select index path :%@",indexPath);
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

/************************** FB Login ***********************************/

- (IBAction)performFbLogin:(id)sender {
    [self openSessionWithAllowLoginUI:YES];
}
#pragma mark - Facebook Handlers

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen: {
            NSLog(@"Session open");
            //            [super showProgressViewWithMessage:@""];
            
            [self fetchFbUserData];
        }
            break;
        case FBSessionStateClosed:
            NSLog(@"Session closed");
        case FBSessionStateClosedLoginFailed:
            NSLog(@"Session Login failed");
            
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Facebook Error"
                                  message:@"Please Enter Valid Credential"
                                  delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}
- (void)openSessionWithAllowLoginUI:(BOOL)allowUI
{
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            nil];
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:allowUI
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

-(void)fetchFbUserData {
    [FBRequestConnection
     startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                       id<FBGraphUser> fbuser,
                                       NSError *error) {
         if (!error) {
             NSLog(@"User info :%@",fbuser);
             
             NSString *userId = fbuser.id;
             NSString *userName = fbuser.username;
             NSString *emailId = [fbuser objectForKey:@"email"];
             
             AppDelegate *delegate = (id)[[UIApplication sharedApplication] delegate];
             [delegate setUserEmail:emailId];
             [delegate setUserId:userId];
             [delegate setUserName:userName];
             
             [self performSegueWithIdentifier:@"showMainTabController" sender:self];
         }
     }];
}


@end
