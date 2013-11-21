//
//  FeedModel.h
//

#import <Foundation/Foundation.h>

@interface FeedModel : NSObject

@property (nonatomic, strong) NSString *messageString;
@property (nonatomic, strong) NSDictionary *comments;
@property (nonatomic, strong) NSArray *likes;
@property (nonatomic, strong) NSString *profilePicture;
@property (nonatomic, strong) NSString *pictureURLString;
@property (nonatomic, assign) int type;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *feedId;
@property (nonatomic, strong) NSArray *coordinates;

@end
