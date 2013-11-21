//
//  PlaceMark.m
//

#import "PlaceMark.h"


@implementation PlaceMark

@synthesize coordinate;
@synthesize place;

-(id) initWithPlace: (Place*) p
{
	self = [super init];
	if (self != nil) {
		coordinate.latitude = p.latitude;
		coordinate.longitude = p.longitude;
		self.place = p;
	}
	return self;
}

- (NSString *)subtitle
{
	return self.place.placeDescription;
}
- (NSString *)title
{
	return self.place.placeName;
}
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    coordinate.latitude = newCoordinate.latitude;
    coordinate.longitude = newCoordinate.longitude;
}


@end
