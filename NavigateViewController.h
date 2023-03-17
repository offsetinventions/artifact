//
//  NavigateViewController.h
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface NavigateViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, MKAnnotation, NSStreamDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *map;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) UILongPressGestureRecognizer *pressRecognizer;

@end

