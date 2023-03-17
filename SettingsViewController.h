//
//  SettingsViewController.h
//  Artifact
//
//  Created by Kendall Toerner on 10/10/14.
//  Copyright (c) 2014 KTDesignStudios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsContentViewController.h"

@interface SettingsViewController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *settingsPageViewController;
@property (strong, nonatomic) NSArray *pageTitles;


@end

