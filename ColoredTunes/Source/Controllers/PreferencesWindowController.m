//
//  PreferencesWindowController.m
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ConnectPreferencesViewController.h"
#import "LightsPreferencesViewController.h"

@implementation PreferencesWindowController

#pragma mark -
#pragma mark Lifecycle

- (id)init
{
    NSArray *viewControllers = @[ [[ConnectPreferencesViewController alloc] init],
                                  [[LightsPreferencesViewController alloc] init] ];
    if (self = [super initWithViewControllers:viewControllers])
    {
        
    }
    
    return self;
}

@end
