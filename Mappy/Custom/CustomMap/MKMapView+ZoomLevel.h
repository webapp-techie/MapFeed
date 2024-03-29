//
//  MKMapView+ZoomLevel.h
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
				  zoomLevel:(NSUInteger)zoomLevel
				   animated:(BOOL)animated;

@end 