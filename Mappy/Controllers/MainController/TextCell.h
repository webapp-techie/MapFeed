//
//  TextCell.h
//
//

#import <UIKit/UIKit.h>

@interface TextCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UITextView *storyTextView;
@property (weak, nonatomic) IBOutlet UIButton *getDirectionButton;

@end
