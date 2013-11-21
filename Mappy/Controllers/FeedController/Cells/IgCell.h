//
//  IgCell.h
//

#import <UIKit/UIKit.h>

@interface IgCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UISwitch *swtIg;
@property (strong, nonatomic) IBOutlet UITextField *txtUserName;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;

- (IBAction)performLogin:(id)sender;
- (IBAction)igValueChanged:(id)sender;
@end
