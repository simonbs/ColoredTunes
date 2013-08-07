//
//  GVUserDefaults+Settings.h
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "GVUserDefaults.h"

@interface GVUserDefaults (Settings)

@property (nonatomic, weak) NSString *host;
@property (nonatomic, weak) NSDictionary *lightColors;

@end
