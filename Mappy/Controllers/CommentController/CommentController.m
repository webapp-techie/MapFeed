//
//  CommentController.m
//

#import "CommentController.h"
#import "commentCell.h"
#import "UIImageView+WebCache.h"

@interface CommentController ()

@end

@implementation CommentController
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
    NSLog(@"The commets are....%@", self.comments);
//    [self addCommentOnFacebook];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addCommentOnFacebook:(NSString *)feedId andMessage:(NSString *)message
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary* params1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:delegate.facebook.accessToken,@"access_token", nil];
    NSString *graphPath = [NSString stringWithFormat:@"%@/comments?message=%@", feedId, message];
    FBRequest *fbFeedReq = [[FBRequest alloc] initWithSession:delegate.fbSession graphPath:graphPath parameters:params1 HTTPMethod:@"POST"];
    
    [fbFeedReq startWithCompletionHandler:facebookRSSFeedCompletionHandler = ^
     (FBRequestConnection *connection, id result, NSError *error) {
         NSLog(@"The error is....%@", error);

         if(fbFeedReq != nil)
         {
             NSLog(@"The comment string is....\n%@",result);
         }
     }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

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
    else if (self.isFacebook) {
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

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell configured");
}

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90.0;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


- (IBAction)performBackOperation:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
