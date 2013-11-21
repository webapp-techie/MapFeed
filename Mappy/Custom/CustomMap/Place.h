//
//  Place.h
//

#import <Foundation/Foundation.h>


@interface Place : NSObject {

	NSString* placeName;
	NSString* placeDescription;
	double latitude;
	double longitude;
    UIImage *placeImage;
    
}
@property(nonatomic) BOOL isDisableRightCalloutAccessoryView;
@property (nonatomic, retain) NSString* placeName;
@property (nonatomic, retain) NSString* placeDescription;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic,strong) UIImage *placeImage;
@property (nonatomic, strong) NSString *pictureURL;
@property (nonatomic, assign) int type; 

@end
