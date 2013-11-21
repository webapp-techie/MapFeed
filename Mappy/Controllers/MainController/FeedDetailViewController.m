//
//  FeedDetailViewController.m
//

#import "FeedDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "commentCell.h"
#import "MainController.h"
#import "AppDelegate.h"

@interface FeedDetailViewController ()

@end

@implementation FeedDetailViewController

@synthesize comments, isFacebook, isOffline, delegate;

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
    self.commentTextView.delegate = self;
   // self.commentTextView.inputAccessoryView = self.textViewContainer;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.commentTextView.text = @"";
    NSLog(@"TextView did begin editing");
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.pictureImageView setImageWithURL:[NSURL URLWithString:self.feedModel.pictureURLString] placeholderImage:nil];
    [self.profileImage setImageWithURL:[NSURL URLWithString:self.feedModel.profilePicture] placeholderImage:nil];
    self.messageTextView.text = self.feedModel.messageString;
    self.userNameLabel.text = self.feedModel.userName;
    if(self.feedModel.type == 0)
    {
        self.socialTagImageView.image = [UIImage imageNamed:@"twitter.png"];
    }
    else if(self.feedModel.type == 1)
    {
        self.socialTagImageView.image = [UIImage imageNamed:@"fb.png"];
    }
    else if(self.feedModel.type == 2)
    {
        self.socialTagImageView.image = [UIImage imageNamed:@"ig.png"];
    }
    
    if (self.feedModel.type == 0) {
        self.textViewContainer.hidden = YES;
    }
    
    if (self.feedModel.coordinates) {
        self.getDirectionButton.enabled = YES;
    }
    else
    {
        self.getDirectionButton.enabled = NO;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    
    if (IS_IPHONE5) {
        self.textViewContainer.frame = CGRectMake(0, 548-215-55, self.textViewContainer.frame.size.width, self.textViewContainer.frame.size.height);
    }
    else
    {
        self.textViewContainer.frame = CGRectMake(0, 460-215-55, self.textViewContainer.frame.size.width, self.textViewContainer.frame.size.height);
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    if (IS_IPHONE5) {
        self.textViewContainer.frame = CGRectMake(0, 548-55, self.textViewContainer.frame.size.width, self.textViewContainer.frame.size.height);
    }
    else
    {
        self.textViewContainer.frame = CGRectMake(0, 460-55, self.textViewContainer.frame.size.width, self.textViewContainer.frame.size.height);
    }
    
    [UIView commitAnimations];
}


- (void)viewDidUnload {
    [self setPictureImageView:nil];
    [self setProfileImage:nil];
    [self setMessageTextView:nil];
    [self setUserNameLabel:nil];
    [self setTheTableView:nil];
    [self setSocialTagImageView:nil];
    [self setCommentTextView:nil];
    [self setTextViewContainer:nil];
    [self setGetDirectionButton:nil];
    [super viewDidUnload];
}

#pragma mark - 
#pragma mark Event Handlers


- (IBAction)onComments:(id)sender {
    self.theTableView.hidden = NO;
}

- (IBAction)onGetDirection:(id)sender {
    
    [self.commentTextView resignFirstResponder];
    //Show Get Direction
    [((MainController *)self.delegate) showDirection:self.feedModel];
}

- (IBAction)onCloseButton:(id)sender {
    [self.commentTextView resignFirstResponder];
    [self.view removeFromSuperview];
}

#pragma mark - TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"commentCell";
    commentCell *cell = (commentCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil)
    {
        cell = [[commentCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    if (self.isOffline)
    {
        if (self.isFacebook) {
            cell.badgeImage.image = [UIImage imageNamed:@"fb.png"];
        }
        else
        {
            cell.badgeImage.image = [UIImage imageNamed:@"ig.png"];
        }
        cell.commentTextView.text = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"commentText"];
        cell.userNameTextView.text = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"userName"];
        [cell.profileImage setImageWithURL:[NSURL URLWithString:[[self.comments objectAtIndex:indexPath.row] objectForKey:@"profilePicture"]] placeholderImage:nil];
        
    }
    else if (self.feedModel.type == 1) {
        cell.badgeImage.image = [UIImage imageNamed:@"fb.png"];
        cell.commentTextView.text = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"message"];
        cell.userNameTextView.text = [[[self.comments objectAtIndex:indexPath.row] objectForKey:@"from"] objectForKey:@"name"];
        [cell.profileImage setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", [[[self.comments objectAtIndex:indexPath.row] objectForKey:@"from"] objectForKey:@"id"]]] placeholderImage:nil];
    }
    else
    {
        cell.badgeImage.image = [UIImage imageNamed:@"ig.png"];
        cell.commentTextView.text = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"text"];
        cell.userNameTextView.text = [[[self.comments objectAtIndex:indexPath.row] objectForKey:@"from"] objectForKey:@"username"];
        [cell.profileImage setImageWithURL:[NSURL URLWithString:[[[self.comments objectAtIndex:indexPath.row] objectForKey:@"from"] objectForKey:@"profile_picture"]] placeholderImage:nil];
    }
    
    return cell;
}


#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90.0;
}


- (void)addInstagramComment:(NSString *)feedId withText:(NSString *)commentText
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:commentText, @"text",@"addComment",@"commandName", nil];
    NSString *methodName = [NSString stringWithFormat:@"media/%@/comments",feedId];
    
    [appDelegate.instagram requestWithMethodName:methodName params:params1 httpMethod:@"POST" delegate:self];
}

- (void)getInstagramFeed
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"getFeed",@"commandName", nil];
    NSString *methodName = [NSString stringWithFormat:@"media/%@",self.feedModel.feedId];
    
    [appDelegate.instagram requestWithMethodName:methodName params:params1 httpMethod:@"GET" delegate:self];
    
}


- (void)request:(IGRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Instagram did fail: %@", error);
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
    
    if ([commandName isEqualToString:@"addComment"]) {
        self.commentTextView.text = @"";
        [self getInstagramFeed];
    }
    else{
        NSDictionary *resDictionary = [result objectForKey:@"data"];
        self.feedModel.type = 2;
        self.feedModel.userName = [[resDictionary objectForKey:@"user"] objectForKey:@"username"];
        self.feedModel.userId = [[[resDictionary objectForKey:@"user"] objectForKey:@"id"] description];
        
        self.feedModel.feedId = [[resDictionary objectForKey:@"id"] description];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[resDictionary objectForKey:@"created_time"] doubleValue]];
        NSLog(@"Date is ....%@",date);
        self.feedModel.date = date;
        
        self.feedModel.profilePicture = [[resDictionary objectForKey:@"user"] objectForKey:@"profile_picture"];
        self.feedModel.comments = [resDictionary objectForKey:@"comments"];
        self.feedModel.likes = [resDictionary objectForKey:@"likes"];
        self.feedModel.pictureURLString = [[[resDictionary objectForKey:@"images"] objectForKey:@"low_resolution"] objectForKey:@"url"];
        
        if ([resDictionary objectForKey:@"location"] && ![[resDictionary objectForKey:@"location"] isKindOfClass:[NSNull class]]) {
            NSMutableArray *coordinates = [[NSMutableArray alloc] init];
            [coordinates addObject:[[resDictionary objectForKey:@"location"] objectForKey:@"longitude"]];
            [coordinates addObject:[[resDictionary objectForKey:@"location"] objectForKey:@"latitude"]];
            
            self.feedModel.coordinates = coordinates;
        }
        
        if ([resDictionary objectForKey:@"caption"] && ![[resDictionary objectForKey:@"caption"] isKindOfClass:[NSNull class]]) {
            self.feedModel.messageString = [[resDictionary objectForKey:@"caption"] objectForKey:@"text"];
        }
        self.comments = [self.feedModel.comments objectForKey:@"data"];

        [self.theTableView reloadData];
    }
}

- (void)addCommentOnFacebook:(NSString *)feedId andMessage:(NSString *)message
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:appDelegate.facebook.accessToken,@"access_token", nil];
    NSString *graphPath = [NSString stringWithFormat:@"%@/comments?message=%@", feedId, message];
    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:appDelegate.fbSession graphPath:graphPath parameters:params1 HTTPMethod:@"POST"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {
         NSLog(@"The error is....%@", error);
         
         if(fbFeedReq != nil)
         {
             NSLog(@"The comment string is....\n%@",result);
         }
         self.commentTextView.text = @"";
         [self facebookRSSFeed:self.feedModel.feedId];
     }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqual:@"\n"]) {
        [textView resignFirstResponder];
        if ([self.commentTextView.text length] > 0) {
            if (self.feedModel.type == 1) {
                [self addCommentOnFacebook:self.feedModel.feedId andMessage:self.commentTextView.text];
            }
            else if(self.feedModel.type == 2)
            {
                [self addInstagramComment:self.feedModel.feedId withText:self.commentTextView.text];
            }
        }
        
        return NO;
    }
    return YES;
}


-(void)facebookRSSFeed:(NSString *)feedId
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:appDelegate.facebook.accessToken,@"access_token", nil];
    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:appDelegate.fbSession graphPath:feedId parameters:params1 HTTPMethod:@"GET"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {
         
         if(fbFeedReq != nil)
         {
             NSDictionary *res = (NSDictionary *)result;
             NSLog(@"\n%@",res);

             self.feedModel.type = 1;
             self.feedModel.userName = [[res objectForKey:@"from"] objectForKey:@"name"];
             self.feedModel.userId = [[[res objectForKey:@"from"] objectForKey:@"id"] description];
             
             self.feedModel.feedId = [[res objectForKey:@"id"] description];
             
             NSDateFormatter *df = [[NSDateFormatter alloc] init];
             [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
             NSDate *date = [df dateFromString:[res objectForKey:@"updated_time"]];
             self.feedModel.date = date;
             self.feedModel.profilePicture = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", self.feedModel.userId];
             self.feedModel.comments = [res objectForKey:@"comments"];
             self.feedModel.likes = [res objectForKey:@"likes"];
             self.feedModel.pictureURLString = [res objectForKey:@"picture"];
             
             if ([res objectForKey:@"place"]) {
                 NSMutableArray *coordinates = [[NSMutableArray alloc] init];
                 [coordinates addObject:[[[res objectForKey:@"place"] objectForKey:@"location"] objectForKey:@"longitude"]];
                 [coordinates addObject:[[[res objectForKey:@"place"] objectForKey:@"location"] objectForKey:@"latitude"]];
                 
                 self.feedModel.coordinates = coordinates;
             }
             
             if ([res objectForKey:@"story"]) {
                 self.feedModel.messageString = [res objectForKey:@"story"];
             }
             else if([res objectForKey:@"message"])
             {
                 self.feedModel.messageString = [res objectForKey:@"message"];
             }
             else if([res objectForKey:@"name"])
             {
                 self.feedModel.messageString = [res objectForKey:@"name"];
             }
             else if([res objectForKey:@"caption"])
             {
                 self.feedModel.messageString = [res objectForKey:@"caption"];
             }
             
             self.comments = [self.feedModel.comments objectForKey:@"data"];
             [self.theTableView reloadData];
             
         }
     }];
}


@end
