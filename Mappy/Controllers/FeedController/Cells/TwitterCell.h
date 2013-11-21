//
//  TwitterCell.h
//

#import <UIKit/UIKit.h>

@interface TwitterCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UITextField *txtUserName;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;
@property (strong, nonatomic) IBOutlet UISwitch *swtTwitter;

- (IBAction)performLogin:(id)sender;
- (IBAction)twitterValueChanged:(id)sender;

@end
