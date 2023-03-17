//
//  WelcomeViewController.m
//  Artifact
//
//  Created by Kendall Toerner on 11/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import "WelcomeViewController.h"
#import <MapKit/MapKit.h>

@interface WelcomeViewController() <CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *readyButton;

@end


@implementation WelcomeViewController

@synthesize pageImages;
@synthesize pageTitles;
@synthesize welcomePageViewController;

CLLocationManager *locationManager;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //Ask for location permission
    //Setup Location Manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [locationManager requestWhenInUseAuthorization];
    
    pageTitles = @[@"Welcome to Artifact", @"Flight Control", @"Navigation", @"Extensive Options"];
    pageImages = @[@"welcome1.png", @"welcome2.png", @"welcome3.png", @"welcome4.png"];
    
    //Create page view controller
    welcomePageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WelcomePageViewController"];
    
    //Assign page view controller datasource
    welcomePageViewController.dataSource = self;
    
    //Create Content View Controller (Child)
    WelcomeContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [welcomePageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    welcomePageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-50);
    
    [self addChildViewController:welcomePageViewController];
    [self.view addSubview:welcomePageViewController.view];
    [welcomePageViewController didMoveToParentViewController:self];
}

- (IBAction)readyButtonPressed:(id)sender
{
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((WelcomeContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) return nil;
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((WelcomeContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (WelcomeContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) return nil;
    
    // Create a new view controller and pass suitable data.
    WelcomeContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WelcomeContentViewController"];
    pageContentViewController.imageFile = pageImages[index];
    pageContentViewController.titleText = pageTitles[index];
    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}


@end
