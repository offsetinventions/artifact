//
//  ControlViewController.m
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import "ControlViewController.h"
#import "UARTPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MBProgressHUD.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface ControlViewController () <MBProgressHUDDelegate, MKMapViewDelegate, MKAnnotation, UITextFieldDelegate>


//Map
@property (strong, nonatomic) IBOutlet MKMapView *map;

//Joystick
@property (strong, nonatomic) IBOutlet UIImageView *joystick;
@property (strong, nonatomic) IBOutlet UIImageView *joystickBG;
@property (strong, nonatomic) IBOutlet UIImageView *joystickBGGlow;

//Alternate Joystick
@property (strong, nonatomic) IBOutlet UIImageView *altjoystick;
@property (strong, nonatomic) IBOutlet UIImageView *altjoystickBG;
@property (strong, nonatomic) IBOutlet UIImageView *altjoystickBGGlow;

//Motor Representations
@property (strong, nonatomic) IBOutlet UIView *motor1img;
@property (strong, nonatomic) IBOutlet UIView *motor2img;
@property (strong, nonatomic) IBOutlet UIView *motor3img;
@property (strong, nonatomic) IBOutlet UIView *motor4img;

//Debug
@property (strong, nonatomic) IBOutlet UIButton *powerButton;
@property (strong, nonatomic) IBOutlet UITextField *commandBox;
@property (strong, nonatomic) IBOutlet UIView *simpleview;

//Dynamic labels
@property (strong, nonatomic) IBOutlet UILabel *connectStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *headingLabel;
@property (strong, nonatomic) IBOutlet UILabel *satellitesLabel;
@property (strong, nonatomic) IBOutlet UILabel *batteryPercentLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedLabel;
@property (strong, nonatomic) IBOutlet UILabel *altitudeLabel;

//Static labels
@property (strong, nonatomic) IBOutlet UILabel *static_statuslabel;
@property (strong, nonatomic) IBOutlet UILabel *static_speedlabel;
@property (strong, nonatomic) IBOutlet UILabel *static_altitudelabel;
@property (strong, nonatomic) IBOutlet UILabel *static_batterylabel;
@property (strong, nonatomic) IBOutlet UILabel *static_headinglabel;
@property (strong, nonatomic) IBOutlet UILabel *static_satelliteslabel;

@end


@implementation ControlViewController

//Map
@synthesize map;

//Joystick
@synthesize joystick;
@synthesize joystickBG;
@synthesize joystickBGGlow;

//Alternate Joystick
@synthesize altjoystick;
@synthesize altjoystickBG;
@synthesize altjoystickBGGlow;

//Motor Representations
@synthesize motor1img;
@synthesize motor2img;
@synthesize motor3img;
@synthesize motor4img;

//Debug
@synthesize powerButton;
@synthesize commandBox;
@synthesize simpleview;

//Location Manager
@synthesize coordinate;
@synthesize locationManager;

//Dynamic labels
@synthesize connectStatusLabel;
@synthesize headingLabel;
@synthesize satellitesLabel;
@synthesize batteryPercentLabel;
@synthesize speedLabel;
@synthesize altitudeLabel;

//Static labels
@synthesize static_altitudelabel;
@synthesize static_batterylabel;
@synthesize static_headinglabel;
@synthesize static_satelliteslabel;
@synthesize static_speedlabel;
@synthesize static_statuslabel;

//Global Variables
int joysticksize = 27;
int joystickoffset = 31;

//Communication toggles
bool bluetoothEn = false;
bool wifiEn = true;

//Hud
MBProgressHUD *hud;

//Debug
CGPoint debuglocation;

//Timers
NSTimer *joystickTimer;
NSTimer *wifiConnectionStatusTimer;

//BLE
CBPeripheral *peripheral;
CBCentralManager    *cm;
UIAlertView         *currentAlertView;
UARTPeripheral      *currentPeripheral;
UIBarButtonItem     *infoBarButton;

//Wifi
NSInputStream *InputStream;
NSOutputStream *OutputStream;
NSMutableData *InputData;
NSString *datacache = @"";

//Motorvalues
int motorvalue1 = 0;
int motorvalue2 = 0;
int motorvalue3 = 0;
int motorvalue4 = 0;

//Movement factors
//Horizontal devides 100 by its value
int horizontalfactor = 3; //=33, 66 remaining
//Ratio between height and rotation from remaining horizontal
int verticalfactor = 1.5; //=44, 22 remaining

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Debug
    commandBox.delegate = self;
    commandBox.returnKeyType = UIReturnKeyDone;
    
    //Setup tab bar
    UITabBar *tabBar = self.tabBarController.tabBar;
    tabBar.translucent = true;
    
    //Setup Fonts
    [connectStatusLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [headingLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [speedLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [satellitesLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [batteryPercentLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [altitudeLabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    
    [static_statuslabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [static_speedlabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [static_headinglabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [static_satelliteslabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [static_batterylabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    [static_altitudelabel setFont:[UIFont fontWithName:@"Gotham-ExtraLight" size:18]];
    
    //Setup map
    map.delegate = self;
    
    //Setup Location Manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
    
    //Setup Searching Hud
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.hidden = true;
    
    //Initialize BLE CM
    if (bluetoothEn) cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    //Search for Artifact Comm
    [self beginSearch];
    
    joystickTimer = [NSTimer scheduledTimerWithTimeInterval:.0001 target:self selector:@selector(testMotorValues) userInfo:nil repeats:true];
}

- (void)beginSearch
{
    if (wifiEn)
    {
        wifiConnectionStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(testWifiConnection) userInfo:nil repeats:true];
    }
    
    if (bluetoothEn)
    {
        [self performSelector:@selector(searchBLE) withObject:nil afterDelay:1];
    }
}

/*--------------------*/
/*-------Wifi---------*/
/*--------------------*/


//Implement Wifi connection

- (void)TCPClientOpen
{
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray == nil) return;
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    if (myDict == nil) return;
    NSString *networkName = CFDictionaryGetValue(myDict, kCNNetworkInfoKeySSID);
    
    if (![networkName isEqualToString:@"Artifact"]) return;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.4.1", 701, &readStream, &writeStream);
    
    InputStream = (__bridge NSInputStream *)readStream;
    OutputStream = (__bridge NSOutputStream *)writeStream;
    
    [InputStream setDelegate:self];
    [OutputStream setDelegate:self];
    
    [InputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [OutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [InputStream open];
    [OutputStream open];
    
    /*
    InputStream = [InputStream initWithURL:[NSURL URLWithString:@"192.168.1.10:9750"]];
    [InputStream setDelegate:self];
    [InputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    OutputStream = [OutputStream initWithURL:[NSURL URLWithString:@"192.168.1.10:9750"] append:true];
    [OutputStream setDelegate:self];
    [OutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [InputStream open];
    [OutputStream open];
     */
}

- (void)TCPClientClose
{
    [InputStream close];
    [OutputStream close];
    InputStream = nil;
    OutputStream = nil;
    if (InputData != nil) InputData = nil;
}

- (void)testWifiConnection
{
    //Open Wifi TCP Stream if not open
    if (InputStream == nil)
    {
        //Update status label
        connectStatusLabel.text = @"Searching...";
        connectStatusLabel.textColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
        
        [self TCPClientOpen];
    }
    else
    {
        //Confirm connection to Artifact
        CFArrayRef myArray = CNCopySupportedInterfaces();
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict == nil)
        {
            [joystickTimer invalidate];
            [self TCPClientClose];
            connectStatusLabel.text = @"Searching...";
            connectStatusLabel.textColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
            return;
        }
        NSString *networkName = CFDictionaryGetValue(myDict, kCNNetworkInfoKeySSID);
        if (![networkName isEqualToString:@"Artifact"])
        {
            [joystickTimer invalidate];
            [self TCPClientClose];
            connectStatusLabel.text = @"Searching...";
            connectStatusLabel.textColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
            return;
        }
        
        //Run methods that happen when connected to drone
        //joystickTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(sendJoystickData) userInfo:nil repeats:true];
    }
}

- (IBAction)powerButtonPressed:(id)sender
{
    [self sendDataWifi:@"**"];
}

- (void)sendDataWifi:(NSString*)data
{
    NSData *newData = [data dataUsingEncoding:NSASCIIStringEncoding];
    
    //Send newdata through wifi
    [OutputStream write:[newData bytes] maxLength:[newData length]];
    //Returns actual number of bytes sent - check if trying to send a large number of bytes as they may well not have all gone in this write and will need sending once there is a hasspaceavailable event
}

- (void)receiveDataWifi:(NSString*)newData
{
    datacache = [datacache stringByAppendingString:newData];
    int startindex = (int)[datacache rangeOfString:@"!"].location+1;
    int endindex = (int)[datacache rangeOfString:@"*"].location;
    if ((startindex < 0) || (endindex < 0)) return;
    
    NSString *command = [[datacache substringFromIndex:startindex] substringToIndex:endindex];
    
    if (datacache.length > endindex+1) datacache = [datacache substringFromIndex:endindex+1];
    else datacache = @"";
    
    //Perform command
    [self receiveCommand:command];
}


/*--------------------*/
/*--------------------*/
/*--------------------*/




/*--------------------*/
/*-----BLUETOOTH------*/
/*--------------------*/

//Implement bluetooth connection

- (void)searchBLE
{
    //Search for first bluetooth device
    //Skip if already connected
    NSArray *connectedPeripherals = [cm retrieveConnectedPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]];
    if ([connectedPeripherals count] > 0)
        [self connectBLE:[connectedPeripherals objectAtIndex:0]];
    else
        [cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]
                                   options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
}

- (void)connectBLE:(CBPeripheral*)peripheral
{
    //Clear pending connections
    [cm cancelPeripheralConnection:peripheral];
    
    //Connect
    currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    [cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    
    //Display connected and change button to disconnect
    connectStatusLabel.text = @"Connected";
    connectStatusLabel.textColor = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:1];
}

- (void)disconnectBLE
{
    //Disconnect Bluetooth LE device
    [cm cancelPeripheralConnection:currentPeripheral.peripheral];
    connectStatusLabel.text = @"Searching...";
    connectStatusLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
}

- (void)sendDataBLE:(NSString*)data
{
    NSData *newData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [currentPeripheral writeRawData:newData];
}

- (void)receiveDataBLE:(NSData*)newData
{
    //Capture incoming data
    char data[20];
    int dataLength = (int)newData.length;
    [newData getBytes:&data length:dataLength];
    
    //Convert to String
    NSString *command = [[NSString alloc] initWithBytes:data length:dataLength encoding:NSUTF8StringEncoding];
    
    //Perform command
    [self receiveCommand:command];
}

/*--------------------*/
/*--------------------*/
/*--------------------*/



/*--------------------*/
/*-COMMAND MANAGEMENT-*/
/*--------------------*/

- (void)sendJoystickData
{
    //2D movement
    double x = (((joystick.frame.origin.x-joystickBG.frame.origin.x)/180)*2)-1+0.333333;
    double y = -(((joystick.frame.origin.y-joystickBG.frame.origin.y)/180)*2)+1-0.333333;
    if (((x + y) < 0.001) && ((x + y) > -0.001))
    {
        x = 0;
        y = 0;
    }
    
    //Rotational and Vertical Movement
    double altx = (((altjoystick.frame.origin.x-altjoystickBG.frame.origin.x)/180)*2)-1+0.333333;
    double alty = -(((altjoystick.frame.origin.y-altjoystickBG.frame.origin.y)/180)*2)+1-0.333333;
    if (((altx + alty) < 0.001) && ((altx + alty) > -0.001))
    {
        altx = 0;
        alty = 0;
    }
    
    //NSLog([NSString stringWithFormat:@"%f,%f",altx,alty]);
    
    [self calculateAndSendMotorValuesWithX:x Y:y AltX:altx AltY:alty];
}

- (void)calculateAndSendMotorValuesWithX:(double)x Y:(double)y AltX:(double)altx AltY:(double)alty
{
    //-----------------------//
    //-------PARAMETERS------//
    //-----------------------//
    
    //Motor values range from -100 to 100 and 100 is added before they are sent to drone
    
    //X and Y range is -1 to 1
    
    //Motor1 = front left
    //Motor2 = front right
    //Motor3 = back left
    //Motor4 = back right
    
    //Motor 1 and 4 are clockwise
    //Motor 2 and 3 are counter-clockwise
    
    //-----------------------//
    //------2D MOVEMENT------//
    //-----------------------//
    
    //Initialize motor powers
    motorvalue1 = 0;
    motorvalue2 = 0;
    motorvalue3 = 0;
    motorvalue4 = 0;
    
    //Set motor powers for Y-axis (forward/backward)
    motorvalue1 = -100*y;
    motorvalue2 = -100*y;
    motorvalue3 = 100*y;
    motorvalue4 = 100*y;
    
    //Add X-axis to motor powers
    motorvalue1 = (motorvalue1 + (100*x));
    motorvalue3 = (motorvalue3 + (100*x));
    motorvalue2 = (motorvalue2 + (-100*x));
    motorvalue4 = (motorvalue4 + (-100*x));
    
    //Divide 2D movement powers to keep room for rotation and height changes
    motorvalue1 = motorvalue1/horizontalfactor;
    motorvalue2 = motorvalue2/horizontalfactor;
    motorvalue3 = motorvalue3/horizontalfactor;
    motorvalue4 = motorvalue4/horizontalfactor;
    
    //-----------------------//
    //--HEIGHT AND ROTATION--//
    //-----------------------//
    
    //Get maximum motor value for 2D, the rest out of 100 is used to height and rotation
    int maxvalue = 0;
    if (motorvalue1 > maxvalue) maxvalue = motorvalue1;
    if (motorvalue2 > maxvalue) maxvalue = motorvalue2;
    if (motorvalue3 > maxvalue) maxvalue = motorvalue3;
    if (motorvalue4 > maxvalue) maxvalue = motorvalue4;
    int remainingpower = 100-maxvalue;
    
    //Height
    int heightallowance = remainingpower/verticalfactor;
    int heighttranslation = alty*heightallowance;
    motorvalue1 = motorvalue1 + heighttranslation;
    motorvalue2 = motorvalue2 + heighttranslation;
    motorvalue3 = motorvalue3 + heighttranslation;
    motorvalue4 = motorvalue4 + heighttranslation;
    
    //Rotation
    int rotationallowance = remainingpower - 44;
    int rotationspeed = altx*rotationallowance;
    motorvalue1 = motorvalue1 - rotationspeed;
    motorvalue4 = motorvalue4 - rotationspeed;
    motorvalue2 = motorvalue2 + rotationspeed;
    motorvalue3 = motorvalue3 + rotationspeed;
    
    //Assure values are within range
    if (motorvalue1 > 100) motorvalue1 = 100;
    if (motorvalue1 < -100) motorvalue1 = -100;
    if (motorvalue2 > 100) motorvalue2 = 100;
    if (motorvalue2 < -100) motorvalue2 = -100;
    if (motorvalue3 > 100) motorvalue3 = 100;
    if (motorvalue3 < -100) motorvalue3 = -100;
    if (motorvalue4 > 100) motorvalue4 = 100;
    if (motorvalue4 < -100) motorvalue4 = -100;
    
    //NSLog([NSString stringWithFormat:@"%i.%i.%i.%i",motorvalue1,motorvalue2,motorvalue3,motorvalue4]);
    
    motor1img.backgroundColor = [UIColor colorWithRed:((float)(125+motorvalue1)/255) green:(((float)(125-motorvalue1))/255) blue:0 alpha:.85];
    motor2img.backgroundColor = [UIColor colorWithRed:((float)(125+motorvalue2)/255) green:(((float)(125-motorvalue2))/255) blue:0 alpha:.85];
    motor3img.backgroundColor = [UIColor colorWithRed:((float)(125+motorvalue3)/255) green:(((float)(125-motorvalue3))/255) blue:0 alpha:.85];
    motor4img.backgroundColor = [UIColor colorWithRed:((float)(125+motorvalue4)/255) green:(((float)(125-motorvalue4))/255) blue:0 alpha:.85];
    
    motorvalue1 = motorvalue1 + 100;
    motorvalue2 = motorvalue2 + 100;
    motorvalue3 = motorvalue3 + 100;
    motorvalue4 = motorvalue4 + 100;
    
    //When sending, values will be added to the arduino power values needed to hover
    
    //Must make sure to subtract 100 once arduino reads it
    
    //[self sendMotorValues];
}

- (void)sendMotorValues
{
    NSString *motorvalues = [NSString stringWithFormat:@"%i%i%i%i",motorvalue1,motorvalue2,motorvalue3,motorvalue4];
    [self sendCommand:@"CM" withDataString:motorvalues];
}

float previousvalue = 0;
- (void)testMotorValues
{
    if (![connectStatusLabel.text isEqualToString:@"Connected"]) return;
    
    if (debuglocation.x == previousvalue) return;
    previousvalue = debuglocation.x;
    
    float power = previousvalue;
    
    power = 730 - power;
    power = power / 7.15;
    
    if (power < 0) power = 0;
    if (power > 100) power = 100;
    
    simpleview.backgroundColor = [UIColor colorWithRed:power/100 green:1-(power/100) blue:0 alpha:1];
    
    NSString *powerstring = [NSString stringWithFormat:@"%f",power];
    
    [self sendDataWifi:powerstring];
    
    NSLog([NSString stringWithFormat:@"%f",power]);
}

- (void)sendCommand:(NSString*)command withDataString:(NSString*)data
{
    /*
    ------------------- Commands ---------------------
    
    Type     String(Key)             Command
    ----------------------------------------------------------
    Power
                 PO                   Power On
                 PF                   Power Off
    GPS
          (data) GW          Add GPS Waypoint Coordinate
          (data) GL                Lock Altitude
                 GA                Unlock Altitude
                 GU              Remove Coordinate
                 GC        Clear GPS Waypoint Coordinates
                 GH           Set New Home Coordinates
                 GR                Return to Home
                 GS              Stop Return to Home
    Motors
          (data) CM               New Motor Values
    Stability
                 SM      Max Stability; Lowest Performance
                 SI    Increased Stability; Less Performance
                 SS   Standard Stability; Standard Performance
                 SD    Decreased Stability; More Performance
                 SL    Lowest Stability; Highest Performance
    Debug
                 DL           Toggle Flashing Lights
     ----------------------------------------------------------
    */
    
    //Commands start with ! and end with *
    
    if (wifiEn) [self sendDataWifi:[@"!" stringByAppendingString:[command stringByAppendingString:[data stringByAppendingString:@"*"]]]];
    
    if (bluetoothEn) [self sendDataBLE:[command stringByAppendingString:[data stringByAppendingString:@"*"]]];
}

- (void)receiveCommand:(NSString*)command
{
    /*
     ------------------- Commands ---------------------
     
     Type     String(Key)             Command
     ----------------------------------------------------------
     Stats
                SA                 Altitude Data
                SH                 Heading Data
                SS                  Speed Data
     GPS
         (data) GC            Current GPS Coordinates
                GS       Number of GPS Satellites Connected
     Errors
                EE            Emergency: Shutting Down
     ----------------------------------------------------------
     */
    
    NSString *commandkey = [[command substringFromIndex:0] substringToIndex:2];
    NSString *commanddata = [command substringFromIndex:2];
    
    if ([commandkey isEqual:@"GC"])
    {
        commanddata = @"";
    }
    else if ([commandkey isEqual:@"SA"])
    {
        
    }
    else if ([commandkey isEqual:@"SH"])
    {
        
    }
    else if ([commandkey isEqual:@"SS"])
    {
        
    }
    else if ([commandkey isEqual:@"GS"])
    {
        
    }
    else if ([commandkey isEqual:@"EM"])
    {
        
    }
    else if ([commandkey isEqual:@"EE"])
    {
        
    }
}

/*--------------------*/
/*--------------------*/
/*--------------------*/




/*--------------------*/
/*----TOUCH EVENTS----*/
/*--------------------*/

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Get touch point
    UITouch *touch1 = [touches anyObject];
    CGPoint location1 = [touch1 locationInView:simpleview];
    
    debuglocation = location1;
    
    return;
    
    
    //Get touch point
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:joystickBG];
    
    //Joystick
    double x = ((location.x/joystickBG.frame.size.width) * 2) - 1;
    double y = ((1 - location.y/joystickBG.frame.size.width) * 2) - 1;
    if (((x > -2) && (x < 2)) && ((y > -2) && (y < 2)))
    {
        if ((x >= 0) && (cos(atan(y/x)) < x))
        {
            x = cos(atan(y/x));
            y = sin(atan(y/x));
        }
        
        if ((x < 0) && (cos(atan(y/x)) < -x))
        {
            x = -cos(atan(y/x));
            y = -sin(atan(y/x));
        }
        
        if (fabs(x) > fabs(y)) joystickBGGlow.alpha = fabs(x);
        else joystickBGGlow.alpha = fabs(y);
        
        joystick.frame = CGRectMake((((x+1)/2)*joystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*joystickBG.frame.size.width)-joystickoffset, joystickBG.frame.size.width/2 - joysticksize, joystickBG.frame.size.width/2 - joysticksize);
    }
    
    //Alternate Joystick
    location = [touch locationInView:altjoystickBG];
    x = ((location.x/altjoystickBG.frame.size.width) * 2) - 1;
    y = ((1 - location.y/altjoystickBG.frame.size.width) * 2) - 1;
    if (((x > -2) && (x < 2)) && ((y > -2) && (y < 2)))
    {
        if ((x >= 0) && (cos(atan(y/x)) < x))
        {
            x = cos(atan(y/x));
            y = sin(atan(y/x));
        }
        
        if ((x < 0) && (cos(atan(y/x)) < -x))
        {
            x = -cos(atan(y/x));
            y = -sin(atan(y/x));
        }
        
        if (fabs(x) > fabs(y)) altjoystickBGGlow.alpha = fabs(x);
        else altjoystickBGGlow.alpha = fabs(y);
        
        altjoystick.frame = CGRectMake((((x+1)/2)*altjoystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*altjoystickBG.frame.size.width)-joystickoffset, altjoystickBG.frame.size.width/2 - joysticksize, altjoystickBG.frame.size.width/2 - joysticksize);
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //SEND COMMAND TO TURN OFF MOTORS
    
    return;
    
    //Get touch point
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:altjoystickBG];
    
    double x = 0;
    double y = 0;
    
    if (location.x < -100)
    {
        joystick.frame = CGRectMake((((x+1)/2)*joystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*joystickBG.frame.size.width)-joystickoffset, joystickBG.frame.size.width/2 - joysticksize, joystickBG.frame.size.width/2 - joysticksize);
        joystickBGGlow.alpha = 0;
    }
    else
    {
        altjoystick.frame = CGRectMake((((x+1)/2)*altjoystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*altjoystickBG.frame.size.width)-joystickoffset, altjoystickBG.frame.size.width/2 - joysticksize, altjoystickBG.frame.size.width/2 - joysticksize);
        altjoystickBGGlow.alpha = 0;
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //SEND COMMAND TO TURN OFF MOTORS
    
    return;
    
    
    //Get touch point
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:altjoystickBG];
    
    double x = 0;
    double y = 0;
    
    if (location.x < -100)
    {
        joystick.frame = CGRectMake((((x+1)/2)*joystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*joystickBG.frame.size.width)-joystickoffset, joystickBG.frame.size.width/2 - joysticksize, joystickBG.frame.size.width/2 - joysticksize);
        joystickBGGlow.alpha = 0;
    }
    else
    {
        altjoystick.frame = CGRectMake((((x+1)/2)*altjoystickBG.frame.size.width)-joystickoffset, ((-(((y+1)/2)-1))*altjoystickBG.frame.size.width)-joystickoffset, altjoystickBG.frame.size.width/2 - joysticksize, altjoystickBG.frame.size.width/2 - joysticksize);
        altjoystickBGGlow.alpha = 0;
    }
}

/*--------------------*/
/*--------------------*/
/*--------------------*/





//DELEGATE METHODS

/*--------------------*/
/*-------WIFI---------*/
/*--------------------*/

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch(streamEvent)
    {
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"data");
            
            if(!InputData) InputData = [NSMutableData data];
            
            uint8_t buffer[1024];
            unsigned int length = (int)[InputStream read:buffer maxLength:1024];
            
            if (length) [InputData appendBytes:(const void *)buffer length:length];
            
            NSString *str = [NSString stringWithUTF8String:(char*)buffer];
            
            if ((length > 1024) || (length < 1)) return;
            
            NSString *datastring = [str substringToIndex:length-1];
            
            if (datastring == nil) return;
            
            [self receiveDataWifi:datastring];
            
            break;
        }
            
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"opened");
            
            connectStatusLabel.text = @"Connected";
            connectStatusLabel.textColor = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:1];
            
            joystickTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(sendJoystickData) userInfo:nil repeats:true];
        }
            
        case NSStreamEventEndEncountered:
        {
            /*
            
            NSLog(@"end");
            
            //Close streams
            if (theStream == InputStream)
            {
                [InputStream close];
                [InputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                InputStream = nil;
            }
            else if (theStream == OutputStream)
            {
                [OutputStream close];
                [OutputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                OutputStream = nil;
            }
            
            //Stop sending data
            [joystickTimer invalidate];
             */
            
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"error");
        }
            
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"space");
        }
            
        case NSStreamEventNone:
        {
            NSLog(@"none");
        }
    }
}

/*--------------------*/
/*--------------------*/
/*--------------------*/


/*--------------------*/
/*-----BLUETOOTH------*/
/*--------------------*/

- (void) centralManagerDidUpdateState:(CBCentralManager*)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        //respond to powered on
        [self beginSearch];
    }
    
    else if (central.state == CBCentralManagerStatePoweredOff)
    {
        //respond to powered off
    }
    
}

- (void) centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
    [cm stopScan];
    
    [self connectBLE:peripheral];
}


- (void) centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
    if ([currentPeripheral.peripheral isEqual:peripheral])
    {
        if(peripheral.services) [currentPeripheral peripheral:peripheral didDiscoverServices:nil];
        else [currentPeripheral didConnect];
        
        connectStatusLabel.text = @"Connected";
        connectStatusLabel.textColor = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:1];
        
        joystickTimer = [NSTimer scheduledTimerWithTimeInterval:.06 target:self selector:@selector(sendJoystickData) userInfo:nil repeats:true];
    }
}


- (void) centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
    if ([currentPeripheral.peripheral isEqual:peripheral])
    {
        [currentPeripheral didDisconnect];
        [joystickTimer invalidate];
        connectStatusLabel.text = @"Searching...";
        connectStatusLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        [self beginSearch];
    }
}

- (void)didReadHardwareRevisionString:(NSString*)string
{
    //Once hardware revision string is read, connection is complete
}

- (void)uartDidEncounterError:(NSString*)error
{
    //Error happened
}

- (void)didReceiveData:(NSData*)newData
{
    [self receiveDataBLE:newData];
}
/*--------------------*/
/*--------------------*/
/*--------------------*/



/*--------------------*/
/*-------MAPKIT-------*/
/*--------------------*/

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusAuthorizedWhenInUse) return;
    
    //Setup Map
    map.mapType = MKMapTypeHybrid;
    CLLocationCoordinate2D location = locationManager.location.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 550, 550);
    map.showsUserLocation = true;
    [map setRegion:region animated:NO];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocationCoordinate2D location = locationManager.location.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 550, 550);
    [map setRegion:region animated:YES];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id < MKOverlay >)overlay
{
    MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
    circleRenderer.lineWidth = 2;
    circleRenderer.fillColor = [UIColor colorWithRed:0 green:.8 blue:0 alpha:0];
    circleRenderer.strokeColor = [UIColor colorWithRed:0 green:.7 blue:1 alpha:.8];
    
    return circleRenderer;
}

/*--------------------*/
/*--------------------*/
/*--------------------*/


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Dismiss the keyboard
    [commandBox resignFirstResponder];
    
    return true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self TCPClientClose];
}

@end
