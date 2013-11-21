//
//  commentCell.h
//  Mappy
//

#import <UIKit/UIKit.h>

@interface commentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *userNameTextView;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UIImageView *badgeImage;

@end
