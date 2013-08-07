//
//  ColorCalculator.h
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This is used to convert a UIColor to an XY color.
 * The class is taken from Philips iOS SDK.
 * https://github.com/PhilipsHue/PhilipsHueSDKiOS/blob/master/ApplicationDesignNotes/RGB%20to%20xy%20Color%20conversion.md
 */

@interface ColorCalculator : NSObject

+ (void)calculateXY:(NSPoint *)xy andBrightness:(float *)brightness fromColor:(NSColor *)color forModel:(NSString*)model;

@end
