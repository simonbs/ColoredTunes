//
//  LoadArtworkOperation.h
//  NowPlaying
//
//  Created by Simon Støvring on 05/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpotifyClient.h"

@interface LoadArtworkOperation : NSOperation

@property (nonatomic, readonly) SpotifyClientTrack *track;

- (id)initWithTrack:(SpotifyClientTrack *)track;

@end
