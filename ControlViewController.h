//
//  ControlViewController.h
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "UARTPeripheral.h"
#import <MapKit/MapKit.h>

@interface ControlViewController : UIViewController <CBCentralManagerDelegate, UARTPeripheralDelegate, CLLocationManagerDelegate, NSStreamDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

