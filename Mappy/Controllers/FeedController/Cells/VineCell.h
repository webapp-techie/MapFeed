//
//  VineCell.h
//

#import <UIKit/UIKit.h>

@interface VineCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UITextField *txtUserName;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;
@property (strong, nonatomic) IBOutlet UISwitch *swtVine;
- (IBAction)performLogin:(id)sender;
- (IBAction)vineValueChanged:(id)sender;

@end
