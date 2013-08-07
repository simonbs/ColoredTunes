//
//  LightCell.m
//  ColoredTunes
//
//  Created by Simon Støvring on 07/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "LightCell.h"

@interface LightCell ()
@property (nonatomic, weak) IBOutlet NSTextField *nameLabel;
@end

@implementation LightCell

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc
{
    self.nameLabel = nil;
    self.name = nil;
}

#pragma mark -
#pragma mark Public Accessors

- (void)setName:(NSString *)name
{
    if (name != _name)
    {
        self.nameLabel.stringValue = name;
        
        _name = name;
    }
}

@end
