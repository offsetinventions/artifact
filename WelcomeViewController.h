//
//  WelcomeViewController.h
//  Artifact
//
//  Created by Kendall Toerner on 11/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WelcomeContentViewController.h"

@interface WelcomeViewController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *welcomePageViewController;
@property (strong, nonatomic) NSArray *pageTitles;
@property (strong, nonatomic) NSArray *pageImages;

@end
