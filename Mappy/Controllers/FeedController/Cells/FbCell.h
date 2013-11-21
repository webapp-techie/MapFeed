//
//  FbCell.h
//

#import <UIKit/UIKit.h>

@interface FbCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UITextField *txtUserName;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;
- (IBAction)fbSwitchChanged:(id)sender;
@property (strong, nonatomic) IBOutlet UISwitch *swtFb;
- (IBAction)performLogin:(id)sender;

@end
