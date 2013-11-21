//
//  PlaceMark.h
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Place.h"

@interface PlaceMark : MKPointAnnotation <MKAnnotation> {

	CLLocationCoordinate2D coordinate;
	Place* place;
}

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) Place* place;

-(id) initWithPlace: (Place*) p;

@end
