//
//  MapViewController.m
//

#import "MapViewController.h"
#import "CalloutMapAnnotationView.h"
#import "PlaceMark.h"
#import "UIImageView+WebCache.h"
#import "RegexKitLite.h"
#import "NSString_stripHtml.h"
#import "MKMapView+ZoomLevel.h"
#import "DataStorage.h"


#define deviceWidthInPortrate [[UIScreen mainScreen] bounds].size.width
#define deviceHeightInPortrate [[UIScreen mainScreen] bounds].size.height
#define deviceWidthInLandScape [[UIScreen mainScreen] bounds].size.height
#define deviceHeightInLandScape [[UIScreen mainScreen] bounds].size.width

@interface MapViewController ()
@property (nonatomic, retain) PlaceMark *placeMarkAnnotation;

@property (nonatomic, retain) MKAnnotationView *selectedAnnotationView;
@property(nonatomic,strong) NSMutableArray *placesArray;
@property(nonatomic,retain)UIView *customAnnotationView;
@property(nonatomic,strong)id <MapViewControllerDeligate> mapdeligate;
@property (strong, nonatomic) UIToolbar *mapToolBar;
@property(nonatomic,strong)CalloutMapAnnotationView *calloutMapAnnotationView;

- (void)CancelClicked:(id)sender;
-(void)setFramesAccordingtoOrientation:(UIInterfaceOrientation)orientation;
-(void)tapedOnDetailDislusureView;
-(BOOL)isModal;

@end

@implementation MapViewController
@synthesize placeMarkAnnotation;
@synthesize mapView ;
@synthesize selectedAnnotationView ;
@synthesize calloutMapAnnotationView;
@synthesize customAnnotationView;
@synthesize mapdeligate;
@synthesize placesArray;
@synthesize leftCalloutAccessoryView;
@synthesize rightCalloutAccessoryView;
@synthesize subTitleView;
@synthesize titleView;
@synthesize toolBarTitle;
@synthesize mapToolBar;
@synthesize isDirection;
@synthesize destinationLatitude;
@synthesize destinationLongitude;


#pragma mark - init 
- (id)initWithPlaces:(NSMutableArray *)places AddDeligate:(id)deligateObj
{
    self = [super init];//longitude and latitude
    if (self) {
        self.placesArray=places;
        self.mapdeligate=deligateObj;
        self.customAnnotationView=[[UIView alloc] init];
        
        //UIImage
        self.leftCalloutAccessoryView=[[UIImageView alloc] init];
        self.leftCalloutAccessoryView.tag=1;
        [self.leftCalloutAccessoryView setBackgroundColor:[UIColor clearColor]];
        [self.customAnnotationView addSubview:self.leftCalloutAccessoryView];
        
        //Title
        self.titleView=[[UILabel alloc] init];
        self.titleView.tag=2;
        //self.titleView.textAlignment=UITextAlignmentCenter;
        //titleLbl.text=self.calloutAnnotation.place.name;
        [self.titleView setBackgroundColor:[UIColor clearColor]];
        self.titleView.textColor=[UIColor whiteColor];
        self.titleView.shadowColor=[UIColor grayColor];
        self.titleView.shadowOffset=CGSizeMake(0, -1);
        self.titleView.font=[UIFont boldSystemFontOfSize:17.0];
        [self.customAnnotationView addSubview:self.titleView];
        
        //Description
        self.subTitleView=[[UILabel alloc] init];
        self.subTitleView.tag=3;
        //self.subTitleView.textAlignment=UITextAlignmentCenter;
        // descLbl.text=self.calloutAnnotation.place.description;
        self.subTitleView.textColor=[UIColor whiteColor];
        self.subTitleView.font = [UIFont systemFontOfSize:12];
        self.subTitleView.numberOfLines = 2;
        [self.subTitleView setBackgroundColor:[UIColor clearColor]];
        [self.customAnnotationView addSubview:self.subTitleView];
        
        //Detail Button
        self.rightCalloutAccessoryView=[UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        //[self.rightCalloutAccessoryView addTarget:self action:@selector(clickedOnDetailedDiscButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.customAnnotationView addSubview:self.rightCalloutAccessoryView];
        [self.rightCalloutAccessoryView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapedOnDetailDislusureView)]];
        
        self.toolBarTitle=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        //self.toolBarTitle.autoresizingMask =   UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.toolBarTitle.textColor=[UIColor whiteColor];
        self.toolBarTitle.shadowColor=[UIColor grayColor];
        self.toolBarTitle.shadowOffset=CGSizeMake(0, -1);
        self.toolBarTitle.font=[UIFont boldSystemFontOfSize:17.0];
        self.toolBarTitle.text=@"Maps";
        self.toolBarTitle.backgroundColor=[UIColor clearColor];
        
        self.mapView=[[MKMapView alloc] initWithFrame:CGRectMake(0, 44, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-64)];
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.mapToolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 44)];
        self.mapToolBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.mapToolBar.tintColor=[UIColor blackColor];
    }
    return self;
}
#pragma mark - hide the tool bar 
-(void)hideMapTopbar
{
    self.mapToolBar.hidden=YES;
    self.toolBarTitle.hidden=YES;
    self.mapView.frame=CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height+50);
}
#pragma mark - Viewcontroller methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    routeView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
    routeView.userInteractionEnabled = NO;
    [mapView addSubview:routeView];
    mapView.delegate = self;
    
//    [mapView addSubview:viewMap];
    
    UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(CancelClicked:)];
    [self.mapToolBar setItems:[NSArray arrayWithObject:cancelButton]];
    
    self.toolBarTitle.textAlignment=UITextAlignmentCenter;
    [self.mapToolBar addSubview:self.toolBarTitle];
    [self.view addSubview:self.mapToolBar];
    [self.view addSubview:self.mapView];
    
    if(self.isDirection)
    {
        UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 72)];
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [backButton setTitle:@"<" forState:UIControlStateNormal];
        [backButton setTitle:@"<" forState:UIControlStateSelected];
        backButton.frame = CGRectMake(7, 14, 33, 44);
        backButton.tag = 1;
        [theView addSubview:backButton];
        [backButton addTarget:self action:@selector(btnBackForthClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [nextButton setTitle:@">" forState:UIControlStateNormal];
        [nextButton setTitle:@">" forState:UIControlStateSelected];
        nextButton.frame = CGRectMake(281, 14, 33, 44);
        nextButton.tag = 2;
        [nextButton addTarget:self action:@selector(btnBackForthClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [theView addSubview:nextButton];
        
        lblDistance = [[UILabel alloc] initWithFrame:CGRectMake(49, 9, 220, 57)];
        lblDistance.numberOfLines = 3;
        lblDistance.textAlignment = UITextAlignmentCenter;
        lblDistance.font = [UIFont systemFontOfSize:12];
        lblDistance.adjustsFontSizeToFitWidth = YES;
        lblDistance.minimumFontSize = 12;
        lblDistance.backgroundColor = [UIColor clearColor];
        [theView addSubview:lblDistance];
        [self.view addSubview:theView];
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
    }

    
    MKCoordinateRegion region;
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 120;
	CLLocationDegrees minLon = 150;
    
    annotationsArray = [[NSMutableArray alloc] init];
    for(int i=0;i<[self.placesArray count];i++)
    {
        Place *home=(Place *)[self.placesArray objectAtIndex:i];
        PlaceMark *customAnnotation = [[PlaceMark alloc] initWithPlace:home] ;
        [annotationsArray addObject:customAnnotation];
        [self.mapView addAnnotation:customAnnotation];
		CLLocation* currentLocation = (CLLocation*)customAnnotation ;
		if(currentLocation.coordinate.latitude > maxLat)
			maxLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.latitude < minLat)
			minLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.longitude > maxLon)
			maxLon = currentLocation.coordinate.longitude;
		if(currentLocation.coordinate.longitude < minLon)
			minLon = currentLocation.coordinate.longitude;
    }
    
    region.center.latitude     = (maxLat + minLat) / 2;
    region.center.longitude    = (maxLon + minLon) / 2;
    region.span.latitudeDelta  =  maxLat - minLat;
    region.span.longitudeDelta = maxLon - minLon;
    [self.mapView setRegion:region animated:YES];

    if (IS_IPHONE5)
    {
        mapSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 400, 160, 40)];
        durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 390, 100, 20)];

    }
    else
    {
        mapSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 400-68, 160, 40)];
        durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 390-68, 100, 20)];

    }

    durationLabel.text = @"Last Week";
    durationLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:durationLabel];


    
    [mapSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    mapSlider.minimumValue = 0.5;
    mapSlider.maximumValue = 3;
    mapSlider.value = 1;
    [mapSlider setContinuous:NO];
    [self.view addSubview:mapSlider];
    
    [self setFramesAccordingtoOrientation:[UIApplication sharedApplication].statusBarOrientation];

    if(![self isModal])
        [self hideMapTopbar];
    
    countIndexOfPoint = 0;
}

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    NSLog(@"The slider value is...%f", slider.value);

    if (slider.value < 1) {
        [self showLastWeekData];
    }
    else if (slider.value < 2)
    {
        [self showLastMonthData];
    }
    else
    {
        [self showLastYearData];
    }
    
}

- (void)showLastYearData
{
    durationLabel.text = @"Last Year";
    [self.mapView removeAnnotations:annotationsArray];
    
    NSArray *dataArray = [[DataStorage appstorage] getFeedRecordsByDays:365];
    NSMutableArray *pArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[dataArray count]; i++) {
        FeedModel *feedModal = [dataArray objectAtIndex:i];
        if (feedModal.coordinates) {
            Place *p1 = [[Place alloc] init];
            p1.placeName = feedModal.userName;
            p1.placeDescription = feedModal.messageString;
            p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
            p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
            p1.type = feedModal.type;
            p1.pictureURL = feedModal.profilePicture;
            [pArray addObject:p1];
        }
    }
    self.placesArray = pArray;
    
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90;
    CLLocationDegrees maxLon = -180;
    CLLocationDegrees minLat = 120;
    CLLocationDegrees minLon = 150;
    
    for(int i=0;i<[self.placesArray count];i++)
    {
        Place *home=(Place *)[self.placesArray objectAtIndex:i];
        PlaceMark *customAnnotation = [[PlaceMark alloc] initWithPlace:home];
        [annotationsArray addObject:customAnnotation];
        [self.mapView addAnnotation:customAnnotation];
        CLLocation* currentLocation = (CLLocation*)customAnnotation ;
        if(currentLocation.coordinate.latitude > maxLat)
            maxLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.latitude < minLat)
            minLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.longitude > maxLon)
            maxLon = currentLocation.coordinate.longitude;
        if(currentLocation.coordinate.longitude < minLon)
            minLon = currentLocation.coordinate.longitude;
    }
    
    region.center.latitude     = (maxLat + minLat) / 2;
    region.center.longitude    = (maxLon + minLon) / 2;
    region.span.latitudeDelta  =  maxLat - minLat;
    region.span.longitudeDelta = maxLon - minLon;
    [self.mapView setRegion:region animated:YES];
    

}

- (void)showLastMonthData
{
    durationLabel.text = @"Last Month";
    [self.mapView removeAnnotations:annotationsArray];
    
    NSArray *dataArray = [[DataStorage appstorage] getFeedRecordsByDays:30];
    NSMutableArray *pArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[dataArray count]; i++) {
        FeedModel *feedModal = [dataArray objectAtIndex:i];
        if (feedModal.coordinates) {
            Place *p1 = [[Place alloc] init];
            p1.placeName = feedModal.userName;
            p1.placeDescription = feedModal.messageString;
            p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
            p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
            p1.type = feedModal.type;
            p1.pictureURL = feedModal.profilePicture;
            [pArray addObject:p1];
        }
    }
    self.placesArray = pArray;
    
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90;
    CLLocationDegrees maxLon = -180;
    CLLocationDegrees minLat = 120;
    CLLocationDegrees minLon = 150;
    
    for(int i=0;i<[self.placesArray count];i++)
    {
        Place *home=(Place *)[self.placesArray objectAtIndex:i];
        PlaceMark *customAnnotation = [[PlaceMark alloc] initWithPlace:home];
        [annotationsArray addObject:customAnnotation];
        [self.mapView addAnnotation:customAnnotation];
        CLLocation* currentLocation = (CLLocation*)customAnnotation ;
        if(currentLocation.coordinate.latitude > maxLat)
            maxLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.latitude < minLat)
            minLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.longitude > maxLon)
            maxLon = currentLocation.coordinate.longitude;
        if(currentLocation.coordinate.longitude < minLon)
            minLon = currentLocation.coordinate.longitude;
    }
    
    region.center.latitude     = (maxLat + minLat) / 2;
    region.center.longitude    = (maxLon + minLon) / 2;
    region.span.latitudeDelta  =  maxLat - minLat;
    region.span.longitudeDelta = maxLon - minLon;
    [self.mapView setRegion:region animated:YES];
    

}

-(void)showLastWeekData
{
    durationLabel.text = @"Last Week";
    
    [self.mapView removeAnnotations:annotationsArray];
    
    NSArray *dataArray = [[DataStorage appstorage] getFeedRecordsByDays:7];
    NSMutableArray *pArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[dataArray count]; i++) {
        FeedModel *feedModal = [dataArray objectAtIndex:i];
        if (feedModal.coordinates) {
            Place *p1 = [[Place alloc] init];
            p1.placeName = feedModal.userName;
            p1.placeDescription = feedModal.messageString;
            p1.longitude = [[feedModal.coordinates objectAtIndex:0] floatValue];
            p1.latitude = [[feedModal.coordinates objectAtIndex:1] floatValue];
            p1.type = feedModal.type;
            p1.pictureURL = feedModal.profilePicture;
            [pArray addObject:p1];
        }
    }
    self.placesArray = pArray;
    
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90;
    CLLocationDegrees maxLon = -180;
    CLLocationDegrees minLat = 120;
    CLLocationDegrees minLon = 150;
    
    for(int i=0;i<[self.placesArray count];i++)
    {
        Place *home=(Place *)[self.placesArray objectAtIndex:i];
        PlaceMark *customAnnotation = [[PlaceMark alloc] initWithPlace:home];
        [annotationsArray addObject:customAnnotation];
        [self.mapView addAnnotation:customAnnotation];
        CLLocation* currentLocation = (CLLocation*)customAnnotation ;
        if(currentLocation.coordinate.latitude > maxLat)
            maxLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.latitude < minLat)
            minLat = currentLocation.coordinate.latitude;
        if(currentLocation.coordinate.longitude > maxLon)
            maxLon = currentLocation.coordinate.longitude;
        if(currentLocation.coordinate.longitude < minLon)
            minLon = currentLocation.coordinate.longitude;
    }
    
    region.center.latitude     = (maxLat + minLat) / 2;
    region.center.longitude    = (maxLon + minLon) / 2;
    region.span.latitudeDelta  =  maxLat - minLat;
    region.span.longitudeDelta = maxLon - minLon;
    [self.mapView setRegion:region animated:YES];
    

}


- (void)viewDidAppear:(BOOL)animated
{
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setFramesAccordingtoOrientation:toInterfaceOrientation];
}
#pragma mark - set frames according to device
-(void)setFramesAccordingtoOrientation:(UIInterfaceOrientation )orientation
{
    if(UIInterfaceOrientationIsPortrait(orientation))
    {
        self.toolBarTitle.frame=CGRectMake(0, 0, deviceWidthInPortrate, 44);
    }else{
        self.toolBarTitle.frame=CGRectMake(0, 0, deviceWidthInLandScape, 44);
    }
    if(self.selectedAnnotationView==nil||calloutMapAnnotationView==nil)
        return;
    [self.mapView removeAnnotation: self.placeMarkAnnotation];
    calloutMapAnnotationView=nil;
    [self mapView:self.mapView didSelectAnnotationView:self.selectedAnnotationView];
}
#pragma mark - Map view deligate methods

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
//    NSLog(@"view: %@",view.description);
    if(calloutMapAnnotationView!=nil)
    {
        [self.mapView removeAnnotation: self.placeMarkAnnotation];
        calloutMapAnnotationView=nil;
    }
    if (self.placeMarkAnnotation == nil) {
        self.placeMarkAnnotation = [[PlaceMark alloc] initWithPlace:((PlaceMark *)view.annotation).place];
        
    } else {
        [self.placeMarkAnnotation setCoordinate:view.annotation.coordinate];
        [self.placeMarkAnnotation setPlace:((PlaceMark *)view.annotation).place];
    }
    self.selectedAnnotationView = view;
    [self.mapView addAnnotation:self.placeMarkAnnotation];
}
//
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if(calloutMapAnnotationView==nil)
        return;
    
    [self.mapView removeAnnotation: self.placeMarkAnnotation];
    calloutMapAnnotationView=nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
  	if (annotation == self.placeMarkAnnotation) {
        calloutMapAnnotationView = [[CalloutMapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"hi"] ;
        calloutMapAnnotationView.contentHeight = 78.0f;
        [calloutMapAnnotationView.contentView addSubview:self.customAnnotationView];
        calloutMapAnnotationView.alpha = 0.7;
        
        self.customAnnotationView.frame=CGRectMake(5, 0, 320-20, 78.0f);
        if(self.placeMarkAnnotation.place.pictureURL!=nil)
        {
            self.leftCalloutAccessoryView.hidden=NO;
            self.rightCalloutAccessoryView.hidden=NO;
            self.titleView.textAlignment=UITextAlignmentLeft;
            self.subTitleView.textAlignment=UITextAlignmentLeft;
            [self.leftCalloutAccessoryView setImageWithURL:[NSURL URLWithString:self.placeMarkAnnotation.place.pictureURL] placeholderImage:nil];
            
//           ((UIImageView *)[self.customAnnotationView viewWithTag:1]).image=self.placeMarkAnnotation.place.placeImage;
            self.leftCalloutAccessoryView.frame=CGRectMake(2, 2, 72, 72);
            self.titleView.frame=CGRectMake(80, 13, 320-20-80-30, 21);
            self.subTitleView.frame=CGRectMake(80, 42, 320-20-80-30, 35);
            self.rightCalloutAccessoryView.frame=CGRectMake(320-20-30-3, 22, 29, 31);
        }else{
            self.leftCalloutAccessoryView.hidden=YES;
            self.titleView.frame=CGRectMake(5, 13, 320-20-80-30, 21);
            self.titleView.textAlignment=UITextAlignmentCenter;
            self.subTitleView.textAlignment=UITextAlignmentCenter;
            self.subTitleView.frame=CGRectMake(5, 42, 320-20-80-30, 35);
            self.rightCalloutAccessoryView.frame=CGRectMake(320-20-30-3, 22, 29, 31);
        }
        if(self.placeMarkAnnotation.place.isDisableRightCalloutAccessoryView)
        {
            self.rightCalloutAccessoryView.hidden=YES;
            if(self.placeMarkAnnotation.place.placeImage!=nil)
            {
                self.titleView.textAlignment=UITextAlignmentLeft;
                self.subTitleView.textAlignment=UITextAlignmentLeft;
                ((UIImageView *)[self.customAnnotationView viewWithTag:1]).image=self.placeMarkAnnotation.place.placeImage;
                self.leftCalloutAccessoryView.frame=CGRectMake(2, 2, 72, 72);
                self.titleView.frame=CGRectMake(80, 13, 320-20-80, 21);
                self.subTitleView.frame=CGRectMake(80, 42, 320-20-80, 35);
             }else{
                self.leftCalloutAccessoryView.hidden=YES;
                self.titleView.frame=CGRectMake(0, 13, 320-20, 21);
                self.titleView.textAlignment=UITextAlignmentCenter;
                self.subTitleView.textAlignment=UITextAlignmentCenter;
                self.subTitleView.frame=CGRectMake(0, 42, 320-20, 35);
            }
        }
        ((UILabel *)[self.customAnnotationView viewWithTag:2]).text=self.placeMarkAnnotation.place.placeName;
        ((UILabel *)[self.customAnnotationView viewWithTag:3]).text=self.placeMarkAnnotation.place.placeDescription;
        
        calloutMapAnnotationView.parentAnnotationView = self.selectedAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
        return calloutMapAnnotationView;
	} else {
        
        NSLog(@"Annotation is...%@",annotation);
        Place *place = ((PlaceMark *)annotation).place;
        
        if ([place isKindOfClass:[PlaceMark class]]) {
            place = ((PlaceMark *)place).place;
        }
        
        MKAnnotationView *annotationView = nil;
        static NSString *defaultPinID = @"CustomAnnotation";
        annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        if ( annotationView == nil )
            annotationView = [[MKAnnotationView alloc]
                       initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        
        annotationView.canShowCallout = YES;
        
        if (place.type == 0) {
            annotationView.image = [UIImage imageNamed:@"twitter_ano.png"];
        }
        else if(place.type == 1)
        {
            annotationView.image=[UIImage imageNamed:@"fb_ano.png"];
        }
        else if(place.type == 2)
        {
            annotationView.image=[UIImage imageNamed:@"ig_ano.png"];
        }
        
        annotationView.canShowCallout = NO;
        return annotationView;
    }
	return nil;
}
#pragma mark - callback methods
- (void)CancelClicked:(id)sender {
    if([self isModal])
        [self dismissModalViewControllerAnimated:YES];
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
    self.placeMarkAnnotation=nil;
    self.mapView =nil;
    self.selectedAnnotationView =nil;
    self.calloutMapAnnotationView=nil;
    self.customAnnotationView=nil;
    self.mapdeligate=nil;
    self.placesArray=nil;
    self.leftCalloutAccessoryView=nil;
    self.rightCalloutAccessoryView=nil;
    self.subTitleView=nil;
    self.titleView=nil;
    self.toolBarTitle=nil;
    self.mapToolBar=nil;
}

-(void)tapedOnDetailDislusureView
{
    
//    if(self.mapdeligate!=nil && [self.mapdeligate respondsToSelector:@selector(rightCalloutAccessoryViewClicked:)])
//    {
//        [self.mapdeligate rightCalloutAccessoryViewClicked:self.placeMarkAnnotation.place];
//    }
//    [self CancelClicked:nil];
}
-(BOOL)isModal {
    
    BOOL isModal = ((self.parentViewController && self.parentViewController.modalViewController == self) ||
                    //or if I have a navigation controller, check if its parent modal view controller is self navigation controller
                    ( self.navigationController && self.navigationController.parentViewController && self.navigationController.parentViewController.modalViewController == self.navigationController) ||
                    //or if the parent of my UITabBarController is also a UITabBarController class, then there is no way to do that, except by using a modal presentation
                    [[[self tabBarController] parentViewController] isKindOfClass:[UITabBarController class]]);
    
    //iOS 5+
    if (!isModal && [self respondsToSelector:@selector(presentingViewController)]) {
        
        isModal = ((self.presentingViewController && self.presentingViewController.modalViewController == self) ||
                   //or if I have a navigation controller, check if its parent modal view controller is self navigation controller
                   (self.navigationController && self.navigationController.presentingViewController && self.navigationController.presentingViewController.modalViewController == self.navigationController) ||
                   //or if the parent of my UITabBarController is also a UITabBarController class, then there is no way to do that, except by using a modal presentation
                   [[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]);
        
    }
    
    return isModal;        
    
}

#pragma mark mapView delegate functions
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	routeView.hidden = YES;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self updateRouteView];
	routeView.hidden = NO;
	[routeView setNeedsDisplay];
}

/*
- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation{
	MKPinAnnotationView *annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
    if(annotation==addAnnotation3)
    {
        annView.draggable=TRUE;
        annView.pinColor = MKPinAnnotationColorPurple;
    }
    else
        annView.pinColor = MKPinAnnotationColorGreen;
    
	annView.animatesDrop=TRUE;
	annView.canShowCallout = YES;
    annView.enabled = TRUE;
	annView.calloutOffset = CGPointMake(-5, 5);
	return annView;
}
/*/ 

- (void)mapView:(MKMapView *)mapVieww annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    addAnnotation3.coordinate = [mapView convertPoint:viewMap.point toCoordinateFromView:mapView];
    MKReverseGeocoder *geocoder = [[MKReverseGeocoder alloc] initWithCoordinate:currentlocation.coordinate];
    geocoder.delegate = self;
    [geocoder start];
}

-(MKOverlayView *)mapView: (MKMapView *)mapView viewForOverlay : (id)overlay{
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleView* circleView = [[MKCircleView alloc] initWithCircle : (MKCircle*)overlay];
        circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        circleView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:1];
        circleView.lineWidth = 0.6;
        return circleView;
    }
    return nil;
}


-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation
{
    currentlocation =  newLocation;
    [manager stopUpdatingLocation];
    manager.delegate = nil;
    [self addressLocation:currentlocation];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    MKPlacemark * myPlacemark = placemark;
    NSLog(@"%@",myPlacemark.addressDictionary);
    
    // with the placemark you can now retrieve the city name
    //  NSString *city = [myPlacemark.addressDictionary objectForKey:(NSString*) kABPersonAddressCityKey];
}

// this delegate is called when the reversegeocoder fails to find a placemark
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    NSLog(@"reverseGeocoder:%@ didFailWithError:%@", geocoder, error);
}

#pragma mark routeDisplay-Calculate methods

-(void) addressLocation : (CLLocation *) location
{
	NSString* saddr =[NSString stringWithFormat:@"%lf,%lf",location.coordinate.latitude, location.coordinate.longitude];
	NSString* daddr =[NSString stringWithFormat:@"%lf,%lf",self.destinationLatitude, self.destinationLongitude];
    NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%@&destination=%@&mode=%@&sensor=true",saddr,daddr,strTravelmode];
    
    NSString *locationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:nil];
    
    NSData *jsonData = [locationString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *listItems = [NSJSONSerialization JSONObjectWithData:jsonData
                                                              options:0 error:nil];
    NSLog(@"The routes are...%@", listItems);

	if(![[listItems valueForKey:@"status"]  isEqualToString:@"OK"])
    {
        UIAlertView *alrt = [[UIAlertView alloc] initWithTitle:@"Map" message:@"No directions found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alrt show];
        lblDistance.text=@"";
        return;
    }
    
    arrPoints = [[[listItems valueForKey:@"routes"] valueForKey:@"legs"] valueForKey:@"steps"];
    arrROuteDescription = [[[arrPoints objectAtIndex:0] valueForKey:@"html_instructions"] objectAtIndex:0];
    arrRouteDistance = [[[arrPoints objectAtIndex:0] valueForKey:@"distance"] objectAtIndex:0];
    arrRouteDuration = [[[arrPoints objectAtIndex:0] valueForKey:@"duration"] objectAtIndex:0];
    
    routes = [self decodePolyLine:arrPoints];
    

    NSString *urlString1 =  [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@", saddr, daddr];
    NSString *locationString1 = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString1] encoding:NSUTF8StringEncoding error:nil];

    NSString* encodedPoints = [locationString1 stringByMatching:@"points:\\\"([^\\\"]*)\\\"" capture:1L];
    
    NSMutableString *points = [[NSMutableString alloc] initWithString:encodedPoints];
    routes1 = [self decodePolyLineV2:points];
    
    NSMutableDictionary *dic = [[listItems valueForKey:@"routes"] valueForKey:@"legs"];
    
    lblDistance.text = [NSString stringWithFormat:@"%@     %@",[[[[dic valueForKey:@"distance"] objectAtIndex:0]objectAtIndex:0]valueForKey:@"text"],[[[[dic valueForKey:@"duration"] objectAtIndex:0]objectAtIndex:0]valueForKey:@"text"]];
    
    [self updateRouteView];
    [routeView setNeedsDisplay];
    [self centerMap];
}

-(void) updateRouteView {

	CGContextRef context = 	CGBitmapContextCreate(nil,
												  routeView.frame.size.width,
												  routeView.frame.size.height,
												  8,
												  4 * routeView.frame.size.width,
												  CGColorSpaceCreateDeviceRGB(),
												  kCGImageAlphaPremultipliedLast);
	
    if(routes1!=nil)
    {
        CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.4);
        CGContextSetLineWidth(context,3.0);
        
        for(int i = 0; i < [routes1 count]; i++)
        {
            CLLocation* location = [routes1 objectAtIndex:i];
            CGPoint point = [mapView convertCoordinate:location.coordinate toPointToView:routeView];
            
            if(i == 0) {
                CGContextMoveToPoint(context, point.x, routeView.frame.size.height - point.y);
            } else {
                CGContextAddLineToPoint(context, point.x, routeView.frame.size.height - point.y);
            }
        }
    }
	
	CGContextStrokePath(context);
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	UIImage* img = [UIImage imageWithCGImage:image];
	
	routeView.image = img;
	CGContextRelease(context);
    
}

-(NSMutableArray *)decodePolyLine: (NSArray *)arr
{
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSMutableArray *temp1 = [[[[arr objectAtIndex:0] valueForKey:@"end_location"] valueForKey:@"lat"] objectAtIndex:0];
    NSMutableArray *temp2 = [[[[arr objectAtIndex:0] valueForKey:@"end_location"] valueForKey:@"lng"] objectAtIndex:0];
    int count = [temp1 count];
    for(int i=0;i<count;i++)
    {
        
        NSNumber *latitude= [temp1 objectAtIndex:i];
        NSNumber *longitude= [temp2 objectAtIndex:i];
        
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        
        if(i==0)
        {
            
            if(addAnnotation1)
            {
                [mapView removeAnnotation:addAnnotation1];
                addAnnotation1=nil;
            }
//            addAnnotation1 = [[AddressAnnotation alloc] initWithCoordinate:loc.coordinate];
//            [mapView addAnnotation:addAnnotation1];
            
            if(circle)
            {
                [mapView removeOverlay:circle];
                circle=nil;
            }
            
            circle = [MKCircle circleWithCenterCoordinate:loc.coordinate radius:200];
            [mapView addOverlay:circle];
            
            //[circle setco]
        }
        else if(i==count-1)
        {
            if(addAnnotation2)
            {
                [mapView removeAnnotation:addAnnotation2];
                addAnnotation2=nil;
            }
            
//            addAnnotation2 = [[AddressAnnotation alloc] initWithCoordinate:loc.coordinate];
            //[mapView addAnnotation:addAnnotation2];
            
        }
        
        [array addObject:loc];
    }
	
	return array;
}


-(NSMutableArray *)decodePolyLineV2: (NSMutableString *)encoded {
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    while (index < len) {
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        printf("[%f,", [latitude doubleValue]);
        printf("%f]", [longitude doubleValue]);
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:loc];
    }
    
    return array;
}


-(void) centerMap {
    
    MKCoordinateRegion region;
	
    CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;
	
    for(int idx = 0; idx < routes.count; idx++)
	{
		CLLocation* currentLocation = [routes objectAtIndex:idx];
		if(currentLocation.coordinate.latitude > maxLat)
			maxLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.latitude < minLat)
			minLat = currentLocation.coordinate.latitude;
		if(currentLocation.coordinate.longitude > maxLon)
			maxLon = currentLocation.coordinate.longitude;
		if(currentLocation.coordinate.longitude < minLon)
			minLon = currentLocation.coordinate.longitude;
	}
    
	region.center.latitude     = (maxLat + minLat) / 2;
	region.center.longitude    = (maxLon + minLon) / 2;
	region.span.latitudeDelta  = maxLat - minLat;
	region.span.longitudeDelta = maxLon - minLon;
	
	[mapView setRegion:region animated:YES];
}

-(IBAction)btnBackForthClicked:(id)sender
{
    if(routes==nil)
    {
        return;
    }
    
    UIButton *btn = (UIButton*)sender;
    
    if(btn.tag==1 && countIndexOfPoint>0)
    {
        countIndexOfPoint--;
    }
    else if(btn.tag==2 && countIndexOfPoint<[routes count]-1)
    {
        countIndexOfPoint++;
    }
    
    NSString *str = [NSString stringWithFormat:@"%@",[arrROuteDescription objectAtIndex:countIndexOfPoint]];
    str = [str stripHtml];
    
    lblDistance.text = [NSString stringWithFormat:@"%@ %@\n%@",str,[[arrRouteDistance objectAtIndex:countIndexOfPoint] valueForKey:@"text"],[[arrRouteDuration objectAtIndex:countIndexOfPoint]valueForKey:@"text"]];
    
    if(circle)
    {
        [mapView removeOverlay:circle];
        //[circle release];
        circle = nil;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    CLLocation *loc = [routes objectAtIndex:countIndexOfPoint];
    circle = [MKCircle circleWithCenterCoordinate:loc.coordinate radius:200];
    [mapView addOverlay:circle];
    
    [mapView setCenterCoordinate:loc.coordinate animated:YES];
    [self updateRouteView];
    [routeView setNeedsLayout];
	[mapView setCenterCoordinate:loc.coordinate zoomLevel:14 animated:YES];
    [UIView commitAnimations];
}

@end
