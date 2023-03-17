//
//  NavigateViewController.m
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import "NavigateViewController.h"
#import "MBProgressHUD.h"

@interface NavigateViewController () <MBProgressHUDDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *setHomeButton;
@property (strong, nonatomic) IBOutlet UIButton *returnHomeButton;
@property (strong, nonatomic) IBOutlet UIButton *clearWaypointsButton;

@end

@implementation NavigateViewController

@synthesize map;
@synthesize locationManager;
@synthesize coordinate;
@synthesize pressRecognizer;

UITouch *lastTouch;
MBProgressHUD *hud;
MKCircle *circle;
MKCircle *previouscircle = nil;

int waypointscount = 0;
bool userlocationcentered = false;

CLLocationCoordinate2D previouswaypoint;

NSInputStream *InputStream;
NSOutputStream *OutputStream;
NSMutableData *OutputData;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    map.delegate = self;
    
    //Setup Hud
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.hidden = true;
    
    //Setup gestures
    //Long Press
    pressRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [pressRecognizer setDelegate:self];
    
    //Setup Location Manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusAuthorizedWhenInUse) return;
    
    //Setup Map
    map.mapType = MKMapTypeHybrid;
    CLLocationCoordinate2D location = locationManager.location.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 650, 650);
    map.showsUserLocation = true;
    [map setRegion:region animated:NO];
}

-(IBAction)mapLongPressed:(UIGestureRecognizer *)longPress
{
    //Make sure the only gesture recognized is long press
    if (longPress.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint touchPoint = [lastTouch locationInView:map];
    CLLocationCoordinate2D location = [map convertPoint:touchPoint toCoordinateFromView:map];
    
    //Create point (circle) to put on map
    //Inner circle
    circle = [MKCircle circleWithCenterCoordinate:location radius:1.5];
    [map addOverlay:circle];
    //Green outer circle if beginning point
    if (waypointscount == 0)
    {
        circle = [MKCircle circleWithCenterCoordinate:location radius:3];
        [map addOverlay:circle];
    }
    else //Outer red endpoint circle for latest circle
    {
        circle = [MKCircle circleWithCenterCoordinate:location radius:3.1];
        [map addOverlay:circle];
    }
    //Cover red endpoint circle when new added
    if ((previouscircle != nil) && (waypointscount > 1))
    {
        circle = [MKCircle circleWithCenterCoordinate:previouswaypoint radius:2.9];
        [map addOverlay:circle];
    }
    
    waypointscount++;
    
    //Draw line between points
    if (waypointscount > 1)
    {
        
        CLLocationCoordinate2D points[] = {location, previouswaypoint};
        MKGeodesicPolyline *geodesic = [MKGeodesicPolyline polylineWithCoordinates:points count:2];
        [map addOverlay:geodesic];
    }
    
    previouswaypoint = location;
    previouscircle = circle;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id < MKOverlay >)overlay
{
    if (overlay == circle)
    {
        MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        if (circle.radius == 1.5) //Inner circle (constant)
        {
            circleRenderer.lineWidth = 2;
            circleRenderer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.7];
            circleRenderer.strokeColor = [UIColor colorWithRed:0 green:0.7 blue:1 alpha:.7];
        }
        else if (circle.radius == 3.1) //End point
        {
            circleRenderer.lineWidth = 2;
            circleRenderer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
            circleRenderer.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.7];
        }
        else if (circle.radius == 2.9) //Standard white outer circle
        {
            circleRenderer.lineWidth = 2.5;
            circleRenderer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
            circleRenderer.strokeColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        }
        else //Beginning point
        {
            circleRenderer.lineWidth = 2;
            circleRenderer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
            circleRenderer.strokeColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:.7];
        }
        
        return circleRenderer;
    }
    else
    {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.strokeColor = [UIColor colorWithRed:0 green:.7 blue:1 alpha:0.7];
        renderer.lineWidth = 3.0;
        return renderer;
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (userlocationcentered) return;
    CLLocationCoordinate2D location = locationManager.location.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 550, 550);
    [map setRegion:region animated:YES];
    userlocationcentered = true;
}

- (IBAction)clearWaypointsButtonPressed:(id)sender
{
    waypointscount = 0;
    previouscircle = nil;
    [map removeOverlays:[map overlays]];
    
    //TO DO -- Send command to stop moving to waypoint
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    lastTouch = [touches anyObject];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    lastTouch = [touches anyObject];
}

- (IBAction)setHomeButtonPressed:(id)sender
{
    //Setup Hud
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = @"Home Position Set";
    hud.detailsLabelText = @"Current position set as Home.\r\nTap hold house icon to move home position.";
    hud.labelFont = [UIFont fontWithName:@"Helvetica" size:25];
    hud.detailsLabelFont = [UIFont fontWithName:@"Helvetica" size:15];
    hud.margin = 20;
    
    //Show Hud
    hud.hidden = false;
    //Hide Hud
    [self performSelector:@selector(hideHud) withObject:nil afterDelay:3.3];
}

- (IBAction)returnHomeButtonPressed:(id)sender
{
    //Setup Hud
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = @"Artifact Returning Home";
    hud.labelFont = [UIFont fontWithName:@"Helvetica" size:25];
    hud.detailsLabelText = @"";
    hud.margin = 20;
    
    //Show Hud
    hud.hidden = false;
    //Hide Hud
    [self performSelector:@selector(hideHud) withObject:nil afterDelay:2];
}

- (void)hideHud
{
    hud.hidden = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

@end
