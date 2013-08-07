//
//  ConnectPreferencesViewController.h
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "MASPreferencesViewController.h"
#import "DPHueDiscover.h"

@interface ConnectPreferencesViewController : NSViewController <DPHueDiscoverDelegate, MASPreferencesViewController>

@end
