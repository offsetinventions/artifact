//
//  SettingsViewController.m
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *settingsLabel;
@property (strong, nonatomic) IBOutlet UIImageView *bgImage;

@end


@implementation SettingsViewController

@synthesize pageTitles;
@synthesize settingsPageViewController;
@synthesize settingsLabel;
@synthesize bgImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pageTitles = @[@"Control", @"Navigation", @"Features", @"Other"];
    
    //Create page view controller
    settingsPageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsPageViewController"];
    
    //Assign page view controller datasource
    settingsPageViewController.dataSource = self;
    
    //Create Content View Controller (Child)
    SettingsContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [settingsPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    settingsPageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-50);
    
    [self addChildViewController:settingsPageViewController];
    [self.view addSubview:settingsPageViewController.view];
    [settingsPageViewController didMoveToParentViewController:self];
    
    [self.view sendSubviewToBack:settingsPageViewController.view];
    [self.view sendSubviewToBack:bgImage];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((SettingsContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) return nil;
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((SettingsContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (SettingsContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) return nil;
    
    // Create a new view controller and pass suitable data.
    SettingsContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsContentViewController"];
    pageContentViewController.titleText = pageTitles[index];
    pageContentViewController.pageIndex = index;
    pageContentViewController.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

@end
