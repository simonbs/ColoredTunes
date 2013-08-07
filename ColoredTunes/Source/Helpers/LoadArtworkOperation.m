//
//  LoadArtworkOperation.m
//  NowPlaying
//
//  Created by Simon Støvring on 05/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "LoadArtworkOperation.h"

@implementation LoadArtworkOperation

#pragma mark -
#pragma mark Lifecycle

- (id)initWithTrack:(SpotifyClientTrack *)track
{
    if (self = [super init])
    {
        _track = track;
    }
    
    return self;
}

- (void)main
{
    @autoreleasepool {
        while (self.track.artwork == nil && !self.isCancelled);
    }
}

@end
