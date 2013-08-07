//
//  GVUserDefaults+Settings.m
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "GVUserDefaults+Settings.h"

@implementation GVUserDefaults (Settings)

@dynamic host, lightColors;

#pragma mark -
#pragma mark Lifecycle

- (NSDictionary *)setupDefaults
{
    return @{ @"lightColors" : [NSDictionary dictionary] };
}

@end
