//
//  MainController.m
//

#import "MainController.h"
#import "TextCell.h"
#import "ImageCell.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "FeedModel.h"
#import "CommentController.h"
#import "FacebookImageCell.h"
#import "InstagramCell.h"
#import "Facebook.h"
#import "Place.h"
#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "DataStorage.h"
#import <Twitter/Twitter.h>
#import "Reachability.h"

@interface MainController ()

@end

@implementation MainController

@synthesize dataArray, params, instaParams, mapControlller, isOffline, previousParams, previousInstaParams, min_id, twitterMaxId, twitterSinceId;

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
    
    Reachability *internetReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [internetReach currentReachabilityStatus];
    
    //check weather internet connection available or not
    if (netStatus == NotReachable)
    {
        self.isOffline = YES;
        self.tableData.tableFooterView = nil;
    }
    else
    {
        self.isOffline = NO;
        self.tableData.tableFooterView = self.loadMoreButton;
    }
    
    isFacebookLoaded = NO;
    isTwitterLoaded = NO;
    isInstagramLoaded = NO;
    isLoadRecentInsta = NO;
    self.dataArray = [[NSMutableArray alloc] init];
    theProgressBar = [[MBProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableData addSubview:refreshControl];
    
    
    BOOL isToShowIntroView = [[NSUserDefaults standardUserDefaults] boolForKey:@"isIntro"];

    if (!isToShowIntroView) {
        [self performSegueWithIdentifier:@"showIntroController" sender:self];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isIntro"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if ([delegate isFacebookLogin] && self.previousParams)
    {
        [self showProgressBar];
        [self loadLatestFacebook];
    }
    else if ([TWTweetComposeViewController canSendTweet] && self.twitterSinceId)
    {
        [self showProgressBar];
        [self loadLatestTwitterFeed];
    }
    else if ([delegate.instagram isSessionValid] && self.min_id)
    {
        [self showProgressBar];
        [self loadLatestInstagram];
    }
    else
    {
        [self hideProgressBar];
    }

    [refreshControl endRefreshing];
}

#pragma mark - Load Data

- (void)loadTwitterFeed
{
    __block NSString *userName;
    
    ACAccountStore * account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [account requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        
        NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
        if(arrayOfAccounts.count > 0)
        {
            if(granted == YES)
            {
                ACAccount *account = [arrayOfAccounts lastObject];
                userName = account.username;
                
                NSString *urlString = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
                
                NSDictionary *params1 = @{@"screen_name":[NSString stringWithFormat:@"%@",userName],@"count":@"20"};
                
                SLRequest *request2 = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:urlString] parameters:params1];
                
                request2.account = account;
                [request2 performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"The operation couldn’t be completed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                            
                            [alertView show];
                            self.dataArray = [[NSMutableArray alloc] init];
                        }
                    });
                    
                    if(error)
                    {
                        
                    }
                    else
                    {
                        isTwitterLoaded = YES;
                        NSDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                        NSArray *array = (NSArray *)dictResponse;
                        NSLog(@"The data array is....%@", array);
                        
                        if ([array isKindOfClass:[NSDictionary class]]) {
                            NSLog(@"No more records");
                            [self hideProgressBar];
                        }
                        else
                        {
                            for (int i=0; i<[array count]; i++)
                            {
                                FeedModel *feedModel = [[FeedModel alloc] init];
                                feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"name"];
                                if ([[array objectAtIndex:i] objectForKey:@"coordinates"] && ![[[array objectAtIndex:i] objectForKey:@"coordinates"] isKindOfClass:[NSNull class]])
                                {
                                    feedModel.coordinates = [[[array objectAtIndex:i] objectForKey:@"coordinates"] objectForKey:@"coordinates"];
                                }
                                else
                                {
                                    [self getLocationDetailForAddress:[[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"location"] foreedModel:feedModel];
                                }

                                NSArray *media = [[[array objectAtIndex:i] objectForKey:@"entities"] objectForKey:@"media"];

                                if (media && [media count]>0) {
                                    feedModel.pictureURLString = [[media objectAtIndex:0] objectForKey:@"media_url"];
                                }
                                
                                
                                feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                                feedModel.profilePicture = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"profile_image_url"];
                                feedModel.messageString =  [[array objectAtIndex:i] objectForKey:@"text"];
                                feedModel.type = 0;
                                
                                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
                                NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"created_at"]];
                                feedModel.date = date;
                                [self.dataArray addObject:feedModel];
                            }
                            
                            NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                                sortDescriptorWithKey:@"date"
                                                                ascending:NO];
                            NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
                            NSArray *sortedEventArray = [self.dataArray
                                                         sortedArrayUsingDescriptors:sortDescriptors];
                            [self.dataArray removeAllObjects];
                            [self.dataArray addObjectsFromArray:sortedEventArray];

                            self.twitterMaxId = [[[array objectAtIndex:[array count]-1] objectForKey:@"id"] description];
                            self.twitterSinceId = [[[array objectAtIndex:0] objectForKey:@"id"] description];
                            [[DataStorage appstorage] addFeedRecords:self.dataArray];
                            
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableData reloadData];
                            self.view.userInteractionEnabled = YES;

                            
                            AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                            if (!isInstagramLoaded && [delegate.instagram isSessionValid])
                            {
                                [self showProgressBar];
                                [self loadInstagramData];
                            }
                            else
                            {
                                [self hideProgressBar];
                            }

                        });
                    }
                }];
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressBar];
                AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [appDelegate twitterAccountnotSetMessage];
//                [SVProgressHUD dismiss];
            });
        }
    }];

}


- (void)getLocationDetailForAddress:(NSString *)address foreedModel:(FeedModel *)feedModel;
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:address completionHandler:^(NSArray* placemarks, NSError* error) {
        if(error)
        {
            NSLog(@"Error is.....%@", error);
        }
        
        for (CLPlacemark* aPlacemark in placemarks)
        {
            NSLog(@"The placemark is....%@", aPlacemark.location);
            NSMutableArray *coordinatesArray = [[NSMutableArray alloc] init];
            NSString *longitude = [NSString stringWithFormat:@"%f", aPlacemark.location.coordinate.longitude];
            NSString *latitude = [NSString stringWithFormat:@"%f", aPlacemark.location.coordinate.latitude];

            [coordinatesArray addObject:longitude];
            [coordinatesArray addObject:latitude];
            feedModel.coordinates = coordinatesArray;
        }
        [[DataStorage appstorage] updateFeedRecord:feedModel];
    }];
}

- (void)addInstagramComment
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Good", @"text", nil];
    [appDelegate.instagram requestWithMethodName:@"media/574911037416824487_222966/comments" params:params1 httpMethod:@"POST" delegate:self];
    
//    [appDelegate.instagram requestWithParams:params1
//                                    delegate:self];
}



- (void)loadInstagramData
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"users/self/feed", @"method",@"loadFeed",@"commandName", nil];
    [appDelegate.instagram requestWithParams:params1
                                    delegate:self];
}


-(void)facebookRSSFeed
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:delegate.facebook.accessToken,@"access_token", nil];
    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:delegate.fbSession graphPath:@"me/home" parameters:params1 HTTPMethod:@"GET"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {

         if(fbFeedReq != nil)
         {
             NSDictionary *res = (NSDictionary *)result;
             NSArray *array = (NSArray *)[res valueForKey:@"data"];
             NSLog(@"\n%@",array);
             isFacebookLoaded = YES;
             
             NSDictionary *dict = [res valueForKey:@"paging"];
             
             if(dict && [dict valueForKey:@"next"]!=nil)
             {
                 NSString *myString = [dict valueForKey:@"next"];
                 NSArray *myArray = [myString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
                 
                 NSMutableDictionary *param = [self getParametersFromURLString:[myArray objectAtIndex:0] EntireURLString:[dict valueForKey:@"next"]];
                 self.params = param;
             }
             else
             {
                 self.params = nil;
             }
             
             if(dict && [dict valueForKey:@"previous"]!=nil)
             {
                 NSString *myString = [dict valueForKey:@"previous"];
                 NSArray *myArray = [myString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
                 
                 NSMutableDictionary *param = [self getParametersFromURLString:[myArray objectAtIndex:0] EntireURLString:[dict valueForKey:@"previous"]];
                 self.previousParams = param;
             }
             else
             {
                 self.previousParams = nil;
             }
             
             
             for (int i=0; i<[array count]; i++) {
                 FeedModel *feedModel = [[FeedModel alloc] init];
                 feedModel.type = 1;
                 feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"name"];
                 feedModel.userId = [[[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"id"] description];
                 
                 feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                 
                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                 [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                 NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"updated_time"]];
                 feedModel.date = date;
                 feedModel.profilePicture = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", feedModel.userId];
                 feedModel.comments = [[array objectAtIndex:i] objectForKey:@"comments"];
                 feedModel.likes = [[array objectAtIndex:i] objectForKey:@"likes"];
                 feedModel.pictureURLString = [[array objectAtIndex:i] objectForKey:@"picture"];
                 
                 if ([[array objectAtIndex:i] objectForKey:@"place"]) {
                     NSMutableArray *coordinates = [[NSMutableArray alloc] init];
                     [coordinates addObject:[[[[array objectAtIndex:i] objectForKey:@"place"] objectForKey:@"location"] objectForKey:@"longitude"]];
                     [coordinates addObject:[[[[array objectAtIndex:i] objectForKey:@"place"] objectForKey:@"location"] objectForKey:@"latitude"]];
                     
                     feedModel.coordinates = coordinates;
                 }
                 
                 if ([[array objectAtIndex:i] objectForKey:@"story"]) {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"story"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"message"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"message"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"name"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"name"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"caption"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"caption"];
                 }
                 
                 [self.dataArray addObject:feedModel];
                 
             }
             NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                 sortDescriptorWithKey:@"date"
                                                 ascending:NO];
             NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
             NSArray *sortedEventArray = [self.dataArray
                                          sortedArrayUsingDescriptors:sortDescriptors];
             [self.dataArray removeAllObjects];
             [self.dataArray addObjectsFromArray:sortedEventArray];
             [self.tableData reloadData];
             [[DataStorage appstorage] addFeedRecords:self.dataArray];
             
             if (!isTwitterLoaded && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
             {
                 NSLog(@"Twitter feed load is called");
                 [self showProgressBar];
                 [self loadTwitterFeed];
             }
             else if (!isInstagramLoaded && [delegate.instagram isSessionValid])
             {
                 [self showProgressBar];
                 [self loadInstagramData];
             }
             else
             {
                 [self hideProgressBar];
             }
         }
     }];
}


#pragma mark - IGRequestDelegate

- (void)request:(IGRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Instagram did fail: %@", error);
    [self hideProgressBar];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)request:(IGRequest *)request didLoad:(id)result {
    NSLog(@"Instagram did load: %@ and request....%@", result, request.params);
    NSString *commandName;
    if ([request.params count] > 0) {
        commandName = [[request params] objectForKey:@"commandName"];
    }
    
    if ([commandName isEqualToString:@"loadFeed"]) {
        isInstagramLoaded = YES;
        NSArray *array = (NSArray*)[result objectForKey:@"data"];
        NSDictionary *dict = [result valueForKey:@"pagination"];
        
        if(dict && [dict valueForKey:@"next_url"] !=nil )
        {
            NSString *myString = [dict valueForKey:@"next_url"];
            NSArray *myArray = [myString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
            
            NSMutableDictionary *param = [self getParametersFromURLString:[myArray objectAtIndex:0] EntireURLString:[dict valueForKey:@"next_url"]];
            
            self.instaParams = param;
        }
        
        for (int i=0; i<[array count]; i++)
        {
            FeedModel *feedModel = [[FeedModel alloc] init];
            feedModel.type = 2;
            feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"username"];
            feedModel.userId = [[[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"id"] description];
            
            feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
            
            if (self.min_id == nil) {
                self.min_id = feedModel.feedId;
            }
            
            if (isLoadRecentInsta) {
                self.min_id = feedModel.feedId;
            }
            
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[[array objectAtIndex:i] objectForKey:@"created_time"] doubleValue]];
            NSLog(@"Date is ....%@",date);
            feedModel.date = date;
            
            feedModel.profilePicture = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"profile_picture"];
            feedModel.comments = [[array objectAtIndex:i] objectForKey:@"comments"];
            feedModel.likes = [[array objectAtIndex:i] objectForKey:@"likes"];
            feedModel.pictureURLString = [[[[array objectAtIndex:i] objectForKey:@"images"] objectForKey:@"low_resolution"] objectForKey:@"url"];
            
            if ([[array objectAtIndex:i] objectForKey:@"location"] && ![[[array objectAtIndex:i] objectForKey:@"location"] isKindOfClass:[NSNull class]]) {
                NSMutableArray *coordinates = [[NSMutableArray alloc] init];
                [coordinates addObject:[[[array objectAtIndex:i] objectForKey:@"location"] objectForKey:@"longitude"]];
                [coordinates addObject:[[[array objectAtIndex:i] objectForKey:@"location"] objectForKey:@"latitude"]];
                
                feedModel.coordinates = coordinates;
            }
            
            
            if ([[array objectAtIndex:i] objectForKey:@"caption"] && ![[[array objectAtIndex:i] objectForKey:@"caption"] isKindOfClass:[NSNull class]]) {
                feedModel.messageString = [[[array objectAtIndex:i] objectForKey:@"caption"] objectForKey:@"text"];
            }
            [self.dataArray addObject:feedModel];
            
        }
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                            sortDescriptorWithKey:@"date"
                                            ascending:NO];
        
        NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
        NSArray *sortedEventArray = [self.dataArray
                                     sortedArrayUsingDescriptors:sortDescriptors];
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:sortedEventArray];
        
        [self.tableData reloadData];
        [[DataStorage appstorage] addFeedRecords:self.dataArray];
        [self hideProgressBar];
        
    }
    
}



- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"Text view did begin editing");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    [self addInstagramComment];
    if (self.isOffline)
    {
        self.dataArray = [[DataStorage appstorage] getFeedRecords];
        NSLog(@"Count of all data is...%d",[self.dataArray count]);
        [self.tableData reloadData];
    }
    else
    {
        [self loadFeedsData];
    }

}

- (void)viewDidAppear:(BOOL)animated
{

}

- (void)loadFeedsData
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!isFacebookLoaded && [delegate isFacebookLogin]) {
        [self showProgressBar];
        [self facebookRSSFeed];
    }
    else if (!isTwitterLoaded && [TWTweetComposeViewController canSendTweet])
    {
        NSLog(@"Twitter feed load is called");
        [self showProgressBar];
        [self loadTwitterFeed];
    }
    else if (!isInstagramLoaded && [delegate.instagram isSessionValid])
    {
        [self showProgressBar];
        [self loadInstagramData];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)performExploreOperation:(id)sender {

    if (!self.mapControlller) {
        [self.btnFriend setBackgroundColor:[UIColor blackColor]];
        [self.btnFriend setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.btnFriend setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [self.btnExplore setBackgroundColor:[UIColor whiteColor]];
        [self.btnExplore setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.btnExplore setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        NSMutableArray *placesArray = [[NSMutableArray alloc] init];
        for (int i=0; i<[self.dataArray count]; i++) {
            FeedModel *feedModal = [self.dataArray objectAtIndex:i];
            if (feedModal.coordinates) {
                Place *p1 = [[Place alloc] init];
                p1.placeName = feedModal.userName;
                p1.placeDescription = feedModal.messageString;
                p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
                p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
                p1.type = feedModal.type;
                p1.pictureURL = feedModal.profilePicture;
                [placesArray addObject:p1];
            }
        }
        
        self.mapControlller = [[MapViewController alloc] initWithPlaces:placesArray AddDeligate:self];
        self.mapControlller.isDirection = NO;
        [self.mapControlller hideMapTopbar];
        if (IS_IPHONE5) {
            self.mapControlller.view.frame = CGRectMake(0, 46, 320, 548-46);
        }
        else
        {
            self.mapControlller.view.frame = CGRectMake(0, 46, 320, 460-46);
        }
        
        [self.view addSubview:self.mapControlller.view];
    }
}

- (IBAction)performFriendsOperation:(id)sender {
    [self.btnExplore setBackgroundColor:[UIColor blackColor]];
    [self.btnExplore setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.btnExplore setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    [self.btnFriend setBackgroundColor:[UIColor whiteColor]];
    [self.btnFriend setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.btnFriend setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [self.mapControlller.view removeFromSuperview];
    self.mapControlller = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    FeedModel *feedModal = [self.dataArray objectAtIndex:indexPath.row];
    if(indexPath.row == [self.dataArray count] - 1)
    {
        [self loadMore:self];
    }
    
    if (feedModal.type == 0) {
        NSString *identifier = @"textCell";
        
        TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if(cell == nil)
        {
            cell = [[TextCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        
        //NSLog(@"The cell id is....%@",feedModal.feedId);
        cell.storyTextView.text = feedModal.messageString;
        cell.userName.text = feedModal.userName;
        [cell.profileImage setImageWithURL:[NSURL URLWithString:feedModal.profilePicture]placeholderImage:nil];
        
        CGSize size = [feedModal.messageString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(231, 800) lineBreakMode:NSLineBreakByWordWrapping];
        cell.storyTextView.frame = CGRectMake(cell.storyTextView.frame.origin.x, cell.storyTextView.frame.origin.y, cell.storyTextView.frame.size.width, size.height + 10);
        
        cell.getDirectionButton.frame = CGRectMake(cell.getDirectionButton.frame.origin.x, cell.storyTextView.frame.origin.y + cell.storyTextView.frame.size.height + 5, cell.getDirectionButton.frame.size.width, cell.getDirectionButton.frame.size.height);
        
        cell.getDirectionButton.tag = indexPath.row;
        [cell.getDirectionButton addTarget:self action:@selector(onGetDirection:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.getDirectionButton.hidden = YES;
//        if (feedModal.coordinates) {
//            cell.getDirectionButton.hidden = NO;
//        }
//        else
//        {
//            cell.getDirectionButton.hidden = YES;
//        }
        
        return cell;
    }
    else if(feedModal.type == 1)
    {
        if (feedModal.pictureURLString) {
            NSString * identifier = @"facebookimagecell";
            
            FacebookImageCell *cell = (FacebookImageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if(cell == nil)
            {
                cell = [[FacebookImageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            }
            
            cell.commentButton.hidden = YES;
            cell.storyTextView.text = feedModal.messageString;
            cell.userName.text = feedModal.userName;
            [cell.profileImage setImageWithURL:[NSURL URLWithString:feedModal.profilePicture]placeholderImage:nil];
            
            CGSize size = [feedModal.messageString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(231, 800) lineBreakMode:NSLineBreakByWordWrapping];

            cell.storyTextView.frame = CGRectMake(cell.storyTextView.frame.origin.x, cell.storyTextView.frame.origin.y, cell.storyTextView.frame.size.width, size.height + 10);
            
            cell.commentButton.tag = indexPath.row;
            [cell.commentButton addTarget:self action:@selector(onComment:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.getDirectionButton.tag = indexPath.row;
            [cell.getDirectionButton addTarget:self action:@selector(onGetDirection:) forControlEvents:UIControlEventTouchUpInside];

            cell.getDirectionButton.hidden = YES;
//            if (feedModal.coordinates) {
//                cell.getDirectionButton.hidden = NO;
//            }
//            else
//            {
//                cell.getDirectionButton.hidden = YES;
//            }
            
            if (feedModal.comments && [feedModal.comments count] > 0) {
                cell.commentButton.hidden = NO;
            }
            else
            {
                cell.commentButton.hidden = YES;
            }
            
            
            cell.pictureImageView.frame = CGRectMake(cell.pictureImageView.frame.origin.x, size.height + 10 + 33, cell.pictureImageView.frame.size.width, cell.pictureImageView.frame.size.height);
            
            cell.getDirectionButton.frame = CGRectMake(cell.getDirectionButton.frame.origin.x, cell.pictureImageView.frame.origin.y + cell.pictureImageView.frame.size.height + 5, cell.getDirectionButton.frame.size.width, cell.getDirectionButton.frame.size.height);
            
            [cell.pictureImageView setImageWithURL:[NSURL URLWithString:feedModal.pictureURLString]placeholderImage:nil];
            
            return cell;
        }
        else
        {
            NSString * identifier = @"imageCell";
            
            ImageCell *cell = (ImageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if(cell == nil)
            {
                cell = [[ImageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            }
            
            cell.commentButton.hidden = YES;
            cell.storyTextView.text = feedModal.messageString;
            cell.userName.text = feedModal.userName;
            [cell.profilePicture setImageWithURL:[NSURL URLWithString:feedModal.profilePicture]placeholderImage:nil];
            
            CGSize size = [feedModal.messageString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(231, 800) lineBreakMode:NSLineBreakByWordWrapping];
            cell.storyTextView.frame = CGRectMake(cell.storyTextView.frame.origin.x, cell.storyTextView.frame.origin.y, cell.storyTextView.frame.size.width, size.height + 10);
            
            cell.commentButton.tag = indexPath.row;
            [cell.commentButton addTarget:self action:@selector(onComment:) forControlEvents:UIControlEventTouchUpInside];
            
            if (feedModal.comments && [feedModal.comments count] > 0) {
                cell.commentButton.hidden = NO;
            }
            else
            {
                cell.commentButton.hidden = YES;
            }
            
            
            
            return cell;
            
        }
        
 
    }
    else if(feedModal.type == 2)
    {
        NSString * identifier = @"instagramcell";
        
        InstagramCell *cell = (InstagramCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if(cell == nil)
        {
            cell = [[InstagramCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        }
        
        cell.commentButton.hidden = YES;
        cell.storyTextView.text = feedModal.messageString;
        cell.userName.text = feedModal.userName;
        [cell.profileImage setImageWithURL:[NSURL URLWithString:feedModal.profilePicture]placeholderImage:nil];
        [cell.pictureImage setImageWithURL:[NSURL URLWithString:feedModal.pictureURLString] placeholderImage:nil];
        
        cell.commentButton.tag = indexPath.row;
        [cell.commentButton addTarget:self action:@selector(onComment:) forControlEvents:UIControlEventTouchUpInside];
        
        if (feedModal.comments && [feedModal.comments count] > 0) {
            cell.commentButton.hidden = NO;
        }
        else
        {
            cell.commentButton.hidden = YES;
        }
        
        CGSize size = [feedModal.messageString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(231, 800) lineBreakMode:NSLineBreakByWordWrapping];

        cell.storyTextView.frame = CGRectMake(cell.storyTextView.frame.origin.x, cell.storyTextView.frame.origin.y, cell.storyTextView.frame.size.width, size.height + 10);

        cell.pictureImage.frame = CGRectMake(cell.pictureImage.frame.origin.x, size.height + 10 + 33, cell.pictureImage.frame.size.width, cell.pictureImage.frame.size.height);
        
        cell.getDirectionButton.hidden = YES;
//        cell.getDirectionButton.frame = CGRectMake(cell.getDirectionButton.frame.origin.x, cell.pictureImage.frame.origin.y + cell.pictureImage.frame.size.height + 5, cell.getDirectionButton.frame.size.width, cell.getDirectionButton.frame.size.height);
        
        return cell;
    }
    
    if(indexPath.row == [self.dataArray count] - 1 )
    {
        [self loadMore:self];
    }
    
    return 0;
}

- (void)onGetDirection:(UIButton *)button
{
    NSMutableArray *placesArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[self.dataArray count]; i++) {
        FeedModel *feedModal = [self.dataArray objectAtIndex:i];
        if (feedModal.coordinates) {
            Place *p1 = [[Place alloc] init];
            p1.placeName = feedModal.userName;
            p1.placeDescription = feedModal.messageString;
            p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
            p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
            p1.type = feedModal.type;
            p1.pictureURL = feedModal.profilePicture;
            [placesArray addObject:p1];
        }
    }
    
    self.mapControlller = [[MapViewController alloc] initWithPlaces:placesArray AddDeligate:self];
    self.mapControlller.isDirection = YES;
    [self.mapControlller hideMapTopbar];
    if (IS_IPHONE5) {
        self.mapControlller.view.frame = CGRectMake(0, 46, 320, 548-46);
    }
    else
    {
        self.mapControlller.view.frame = CGRectMake(0, 46, 320, 460-46);
    }
    
    FeedModel *feedModel = [self.dataArray objectAtIndex:button.tag];
    
    self.mapControlller.destinationLatitude = [[feedModel.coordinates objectAtIndex:1] floatValue];
    self.mapControlller.destinationLongitude = [[feedModel.coordinates objectAtIndex:0] floatValue];
    
    [self.view addSubview:self.mapControlller.view];

    
}

- (void)onComment:(id)sender
{
    UIButton *button = (UIButton *)sender;
    FeedModel *feedModel = [self.dataArray objectAtIndex:button.tag];
    if (feedModel.comments) {
        NSArray *commentsData = [feedModel.comments objectForKey:@"data"];
        UIStoryboard *storyboard = self.storyboard;
        CommentController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"CommentController"];
        
        if (feedModel.type == 1) {
            viewController.isFacebook = YES;
        }
        else
        {
            viewController.isFacebook = NO;
        }
        
        viewController.isOffline = self.isOffline;
        viewController.comments = commentsData;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell configured");
}

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    FeedModel *feedModal = [self.dataArray objectAtIndex:indexPath.row];

    CGSize size = [feedModal.messageString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(231, 800) lineBreakMode:NSLineBreakByWordWrapping];
    
    //NSLog(@"The size is....%f",size.height + 45);
    //1 - twitter, 2 - facebook, 3 - instagram
    
    if(feedModal.type == 0)
    {
        return size.height + 45;
    }
    else if (feedModal.type == 1)
    {
        if (feedModal.pictureURLString) {
            if(size.height > 47)
            {
                int height = 128 + size.height + 40;
                return height;
            }
            else
            {
                return 223;
            }
        }
        else
        {
            return size.height + 45;
        }
    }
    else if (feedModal.type == 2)
    {
        if (feedModal.pictureURLString) {
            if(size.height > 47)
            {
                int height = 234 + size.height + 40;
                return height;
            }
            else
            {
                return 338;
            }
        }
        else
        {
            return size.height + 45;
        }
    }
    
    return size.height + 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected cell is...%d",indexPath.row);
    
//    FeedModel *feedModel = (FeedModel *)[self.dataArray objectAtIndex:indexPath.row];
//    if (feedModel.type != 0) {
        UIStoryboard *storyboard = self.storyboard;
        feedDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"feedDetailViewController"];
        feedDetailViewController.feedModel = [self.dataArray objectAtIndex:indexPath.row];
        feedDetailViewController.delegate = self;
        feedDetailViewController.comments = [feedDetailViewController.feedModel.comments objectForKey:@"data"];
        feedDetailViewController.view.frame = CGRectMake(0, 0, feedDetailViewController.view.frame.size.width, feedDetailViewController.view.frame.size.height);
        [self.view addSubview:feedDetailViewController.view];
//    }
}

- (void)showDirection:(FeedModel *)feedModel
{
    [feedDetailViewController.view removeFromSuperview];
    NSMutableArray *placesArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[self.dataArray count]; i++) {
        FeedModel *feedModal = [self.dataArray objectAtIndex:i];
        if (feedModal.coordinates) {
            Place *p1 = [[Place alloc] init];
            p1.placeName = feedModal.userName;
            p1.placeDescription = feedModal.messageString;
            p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
            p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
            p1.type = feedModal.type;
            p1.pictureURL = feedModal.profilePicture;
            [placesArray addObject:p1];
        }
    }
    
    self.mapControlller = [[MapViewController alloc] initWithPlaces:placesArray AddDeligate:self];
    self.mapControlller.isDirection = YES;
    [self.mapControlller hideMapTopbar];
    if (IS_IPHONE5) {
        self.mapControlller.view.frame = CGRectMake(0, 46, 320, 548-46);
    }
    else
    {
        self.mapControlller.view.frame = CGRectMake(0, 46, 320, 460-46);
    }
    
//    FeedModel *feedModel = [self.dataArray objectAtIndex:button.tag];
    
    self.mapControlller.destinationLatitude = [[feedModel.coordinates objectAtIndex:1] floatValue];
    self.mapControlller.destinationLongitude = [[feedModel.coordinates objectAtIndex:0] floatValue];
    
    [self.view addSubview:self.mapControlller.view];
}


- (void)showProgressBar
{
	theProgressBar.labelText = @"Loading...";
	[self.view addSubview:theProgressBar];
	[theProgressBar show:YES];
}

#pragma mark
#pragma mark - Common Methods


- (void)loadMoreInstagram
{
    if (self.instaParams) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [self.instaParams setObject:@"users/self/feed" forKey:@"method"];
        [self.instaParams setObject:@"loadFeed" forKey:@"commandName"];
        [appDelegate.instagram requestWithParams:self.instaParams
                                        delegate:self];
    }
}

- (void)loadLatestInstagram
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"users/self/feed", @"method",self.min_id, @"min_id",@"loadFeed",@"commandName", nil];
    [appDelegate.instagram requestWithParams:params1
                                    delegate:self];
}


- (void)loadMoreTwitter
{
    if ([dataArray count] > 0) {
        __block NSString *userName;
        
        ACAccountStore * account = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [account requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            
            NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
            if(arrayOfAccounts.count > 0)
            {
                if(granted == YES)
                {
                    ACAccount *account = [arrayOfAccounts lastObject];
                    userName = account.username;
                    
                    NSString *urlString = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
                    
//                    FeedModel *feedModal = [dataArray objectAtIndex:[dataArray count]-1];
//                    NSNumber *number = [NSNumber numberWithLongLong:[feedModal.feedId longLongValue]];
                    
                    NSDictionary *params1 = @{@"screen_name":[NSString stringWithFormat:@"%@",userName], @"count":@"20",@"max_id":self.twitterMaxId};
                    
                    SLRequest *request2 = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:urlString] parameters:params1];
                    
                    request2.account = account;
                    [request2 performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{

                            if(error)
                            {
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"The operation couldn’t be completed." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
                                [alertView show];
                                self.dataArray = [[NSMutableArray alloc] init];
                            }
                            else
                            {
                                isTwitterLoaded = YES;
                                NSDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                                NSArray *array = (NSArray *)dictResponse;
                                NSLog(@"The data array is....%@", array);
                                
                                if ([array isKindOfClass:[NSDictionary class]]) {
                                    NSLog(@"No more records");
                                    [self hideProgressBar];
                                }
                                else
                                {
                                    for (int i=1; i<[array count]; i++)
                                    {
                                        FeedModel *feedModel = [[FeedModel alloc] init];
                                        feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"name"];
                                        if ([[array objectAtIndex:i] objectForKey:@"coordinates"] && ![[[array objectAtIndex:i] objectForKey:@"coordinates"] isKindOfClass:[NSNull class]])
                                        {
                                            feedModel.coordinates = [[[array objectAtIndex:i] objectForKey:@"coordinates"] objectForKey:@"coordinates"];
                                        }
                                        else
                                        {
                                            [self getLocationDetailForAddress:[[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"location"] foreedModel:feedModel];
                                        }
                                        
                                        NSArray *media = [[[array objectAtIndex:i] objectForKey:@"entities"] objectForKey:@"media"];
                                        
                                        if (media && [media count]>0) {
                                            feedModel.pictureURLString = [[media objectAtIndex:0] objectForKey:@"media_url"];
                                        }
                                        
                                        feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                                        feedModel.profilePicture = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"profile_image_url"];
                                        feedModel.messageString =  [[array objectAtIndex:i] objectForKey:@"text"];
                                        feedModel.type = 0;
                                        
                                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                        [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
                                        NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"created_at"]];
                                        feedModel.date = date;
                                        [self.dataArray addObject:feedModel];
                                    }
                                    
                                    NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                                        sortDescriptorWithKey:@"date"
                                                                        ascending:NO];
                                    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
                                    NSArray *sortedEventArray = [self.dataArray
                                                                 sortedArrayUsingDescriptors:sortDescriptors];
                                    [self.dataArray removeAllObjects];
                                    [self.dataArray addObjectsFromArray:sortedEventArray];
                                    
                                    self.twitterMaxId = [[[array objectAtIndex:[array count]-1] objectForKey:@"id"] description];
                                    
                                    [[DataStorage appstorage] addFeedRecords:self.dataArray];
                                    [self.tableData reloadData];
                                    self.view.userInteractionEnabled = YES;
                                    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                                    
                                    if (self.instaParams && [delegate.instagram isSessionValid])
                                    {
                                        [self loadMoreInstagram];
                                    }
                                    else
                                    {
                                        [self hideProgressBar];
                                    }
                                }
                            }
                            
                        });
                                
                    }];
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressBar];
                    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                    [appDelegate twitterAccountnotSetMessage];
                });
            }
        }];
    }
    else
    {
        NSLog(@"No more twitter records available");
    }
}

- (void)loadMoreFacebook
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:delegate.fbSession graphPath:@"me/home" parameters:self.params HTTPMethod:@"GET"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {
         
         if(fbFeedReq != nil)
         {
             NSDictionary *res = (NSDictionary *)result;
             NSArray *array = (NSArray *)[res valueForKey:@"data"];
             NSLog(@"\n%@",array);
             isFacebookLoaded = YES;
             
             NSDictionary *dict = [res valueForKey:@"paging"];
             
             if(dict && [dict valueForKey:@"next"]!=nil)
             {
                 NSString *myString = [dict valueForKey:@"next"];
                 NSArray *myArray = [myString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
                 
                 NSMutableDictionary *param = [self getParametersFromURLString:[myArray objectAtIndex:0] EntireURLString:[dict valueForKey:@"next"]];
                 
                 
                 self.params = param;
             }
             else
             {
                 self.params = nil;
             }

             

             
             for (int i=0; i<[array count]; i++) {
                 FeedModel *feedModel = [[FeedModel alloc] init];
                 feedModel.type = 1;
                 feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"name"];
                 feedModel.userId = [[[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"id"] description];
                 
                 feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                 
                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                 [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                 NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"updated_time"]];
                 feedModel.date = date;
                 feedModel.profilePicture = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", feedModel.userId];
                 feedModel.comments = [[array objectAtIndex:i] objectForKey:@"comments"];
                 feedModel.likes = [[array objectAtIndex:i] objectForKey:@"likes"];
                 feedModel.pictureURLString = [[array objectAtIndex:i] objectForKey:@"picture"];
                 
                 
                 if ([[array objectAtIndex:i] objectForKey:@"story"]) {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"story"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"message"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"message"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"name"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"name"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"caption"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"caption"];
                 }
                 [self.dataArray addObject:feedModel];
                 
             }
             NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                 sortDescriptorWithKey:@"date"
                                                 ascending:NO];
             NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
             NSArray *sortedEventArray = [self.dataArray
                                          sortedArrayUsingDescriptors:sortDescriptors];
             [self.dataArray removeAllObjects];
             [self.dataArray addObjectsFromArray:sortedEventArray];
             [self.tableData reloadData];
             [[DataStorage appstorage] addFeedRecords:self.dataArray];
             
             if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
             {
                 [self loadMoreTwitter];
             }
             else if (self.instaParams && [delegate.instagram isSessionValid])
             {
                 [self loadMoreInstagram];
             }
             else
             {
                 [self hideProgressBar];
             }
         }
     }];
}


- (void)loadLatestFacebook
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:delegate.fbSession graphPath:@"me/home" parameters:self.previousParams HTTPMethod:@"GET"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {
         
         if(fbFeedReq != nil)
         {
             NSDictionary *res = (NSDictionary *)result;
             NSArray *array = (NSArray *)[res valueForKey:@"data"];
             NSLog(@"\n%@",array);
             isFacebookLoaded = YES;
             
             NSDictionary *dict = [res valueForKey:@"paging"];
             if(dict && [dict valueForKey:@"previous"]!=nil)
             {
                 NSString *myString = [dict valueForKey:@"previous"];
                 NSArray *myArray = [myString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
                 
                 NSMutableDictionary *param = [self getParametersFromURLString:[myArray objectAtIndex:0] EntireURLString:[dict valueForKey:@"previous"]];
                 self.previousParams = param;
             }

             
             for (int i=0; i<[array count]; i++) {
                 FeedModel *feedModel = [[FeedModel alloc] init];
                 feedModel.type = 1;
                 feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"name"];
                 feedModel.userId = [[[[array objectAtIndex:i] objectForKey:@"from"] objectForKey:@"id"] description];
                 
                 feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                 
                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                 [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                 NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"updated_time"]];
                 feedModel.date = date;
                 feedModel.profilePicture = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", feedModel.userId];
                 feedModel.comments = [[array objectAtIndex:i] objectForKey:@"comments"];
                 feedModel.likes = [[array objectAtIndex:i] objectForKey:@"likes"];
                 feedModel.pictureURLString = [[array objectAtIndex:i] objectForKey:@"picture"];
                 
                 
                 if ([[array objectAtIndex:i] objectForKey:@"story"]) {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"story"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"message"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"message"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"name"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"name"];
                 }
                 else if([[array objectAtIndex:i] objectForKey:@"caption"])
                 {
                     feedModel.messageString = [[array objectAtIndex:i] objectForKey:@"caption"];
                 }
                 [self.dataArray addObject:feedModel];
                 
             }
             
             if ([array count] > 0) {
                 NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                     sortDescriptorWithKey:@"date"
                                                     ascending:NO];
                 NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
                 NSArray *sortedEventArray = [self.dataArray
                                              sortedArrayUsingDescriptors:sortDescriptors];
                 [self.dataArray removeAllObjects];
                 [self.dataArray addObjectsFromArray:sortedEventArray];
                 [self.tableData reloadData];
                 [[DataStorage appstorage] addFeedRecords:self.dataArray];
             }

             if ([TWTweetComposeViewController canSendTweet])
             {
                 [self loadLatestTwitterFeed];
             }
             else if ([delegate.instagram isSessionValid] && self.min_id)
             {
                 [self loadLatestInstagram];
             }
             else
             {
                 [self hideProgressBar];
             }
         }
     }];
}

- (void)loadLatestTwitterFeed
{
    if ([dataArray count] > 0) {
        __block NSString *userName;
        
        ACAccountStore * account = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [account requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            
            NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
            if(arrayOfAccounts.count > 0)
            {
                if(granted == YES)
                {
                    ACAccount *account = [arrayOfAccounts lastObject];
                    userName = account.username;
                    
                    NSString *urlString = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
                    
                    
                    NSDictionary *params1 = @{@"screen_name":[NSString stringWithFormat:@"%@",userName], @"count":@"20",@"since_id":self.twitterSinceId};

                    SLRequest *request2 = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:urlString] parameters:params1];
                    
                    request2.account = account;
                    [request2 performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            isTwitterLoaded = YES;
                            NSDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                            NSArray *array = (NSArray *)dictResponse;
                            NSLog(@"The data array is....%@", array);
                            
                            if ([array isKindOfClass:[NSDictionary class]]) {
                                NSLog(@"No more records");
                                [self hideProgressBar];
                            }
                            else
                            {
                                
                                
                                for (int i=0; i<[array count]; i++)
                                {
                                    FeedModel *feedModel = [[FeedModel alloc] init];
                                    feedModel.userName = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"name"];
                                    if ([[array objectAtIndex:i] objectForKey:@"coordinates"] && ![[[array objectAtIndex:i] objectForKey:@"coordinates"] isKindOfClass:[NSNull class]])
                                    {
                                        feedModel.coordinates = [[[array objectAtIndex:i] objectForKey:@"coordinates"] objectForKey:@"coordinates"];
                                    }
                                    else
                                    {
                                        [self getLocationDetailForAddress:[[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"location"] foreedModel:feedModel];
                                    }
                                    
                                    NSArray *media = [[[array objectAtIndex:i] objectForKey:@"entities"] objectForKey:@"media"];
                                    
                                    if (media && [media count]>0) {
                                        feedModel.pictureURLString = [[media objectAtIndex:0] objectForKey:@"media_url"];
                                    }
                                    
                                    
                                    feedModel.feedId = [[[array objectAtIndex:i] objectForKey:@"id"] description];
                                    feedModel.profilePicture = [[[array objectAtIndex:i] objectForKey:@"user"] objectForKey:@"profile_image_url"];
                                    feedModel.messageString =  [[array objectAtIndex:i] objectForKey:@"text"];
                                    feedModel.type = 0;
                                    
                                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                    [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
                                    NSDate *date = [df dateFromString:[[array objectAtIndex:i] objectForKey:@"created_at"]];
                                    feedModel.date = date;
                                    [self.dataArray addObject:feedModel];
                                }
                                
                                NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                                                    sortDescriptorWithKey:@"date"
                                                                    ascending:NO];
                                NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
                                NSArray *sortedEventArray = [self.dataArray
                                                             sortedArrayUsingDescriptors:sortDescriptors];
                                [self.dataArray removeAllObjects];
                                [self.dataArray addObjectsFromArray:sortedEventArray];
                                [[DataStorage appstorage] addFeedRecords:self.dataArray];
                                
                                [self.tableData reloadData];
                                self.view.userInteractionEnabled = YES;
                                AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                                
                                if ([delegate.instagram isSessionValid] && self.min_id)
                                {
                                    [self loadLatestInstagram];
                                }
                                else
                                {
                                    [self hideProgressBar];
                                }
                            }
                        });

                    }];
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressBar];
                    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                    [appDelegate twitterAccountnotSetMessage];
                });
            }
        }];
    }
    else
    {
        NSLog(@"No more twitter records available");
    }
}


- (IBAction)loadMore:(id)sender {
    NSLog(@"load more is called");
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (self.params && [delegate isFacebookLogin])
    {
        [self showProgressBar];
        [self loadMoreFacebook];
    }
    else if ([TWTweetComposeViewController canSendTweet])
    {
        [self showProgressBar];
        [self loadMoreTwitter];
    }
    else if (self.instaParams && [delegate.instagram isSessionValid])
    {
        [self showProgressBar];
        [self loadMoreInstagram];
    }
    else
    {
        [self hideProgressBar];
    }

}

- (void)hideProgressBar
{
	[theProgressBar hide:YES];
	[theProgressBar removeFromSuperview];
}


- (void)viewDidUnload {
    [self setLoadMoreButton:nil];
    [super viewDidUnload];
}

-(NSMutableDictionary *)getParametersFromURLString:(NSString *)baseURL EntireURLString:(NSString *)entireURL
{
    NSString *str = [entireURL stringByReplacingOccurrencesOfString:baseURL withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"?" withString:@""];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if([str rangeOfString:@"&"].location!=NSNotFound)
    {
        NSArray *array1 = [str componentsSeparatedByString:@"&"];
        for(int i = 0;i<array1.count;i++)
        {
            NSString *str1 = [array1 objectAtIndex:i];
            if([str1 rangeOfString:@"="].location!=NSNotFound)
            {
                NSArray *array2 = [str1 componentsSeparatedByString:@"="];
                NSString *key = [array2 objectAtIndex:0];
                NSString *val = [array2 objectAtIndex:1];
                [dictionary setValue:val forKey:key];
            }
        }
    }
    return dictionary;
}


@end
