//
//  AppDelegate.m
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferencesWindowController.h"
#import "DPHue.h"
#import "DPHueLight.h"
#import "ColorCalculator.h"
#import "SpotifyClient.h"
#import "SLColorArt.h"
#import "LoadArtworkOperation.h"

#define kTwitterUsername @"simonbs"
#define kTweetbotAppBundleId "com.tapbots.TweetbotMac" // osascript -e 'id of app "Tweetbot"'
#define kSpotifyBundleIdentifier @"com.spotify.client"

#define kAmountOfColorTypes 4 // Amount of different color types (excluding random) That is: primary, secondary, background and details (€)

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) PreferencesWindowController *settingsController;
@property (nonatomic, strong) SpotifyClientApplication *spotify;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation AppDelegate

@synthesize settingsController = _settingsController;

#pragma mark -
#pragma mark Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChangedNotification:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorPreferencesChangedNotification:) name:CTColorPreferencesChangedNotification object:nil];
    
    NSString *host = [GVUserDefaults standardUserDefaults].host;
    if (!host)
    {
        [self showPreferences:self];
    }
    
    self.spotify = [SBApplication applicationWithBundleIdentifier:kSpotifyBundleIdentifier];
    if (self.spotify.playerState == SpotifyClientEPlSPlaying)
    {
        [self updateBulbColorsForCurrentTrack];
    }
    
    // Create status item
    NSString *quitMenuItemTitle = NSLocalizedStringFromTable(@"Quit", @"AppDelegate", @"Title for quit menu item");
    NSString *preferencesMenuItemTitle = NSLocalizedStringFromTable(@"Preferences...", @"AppDelegate", @"Title for preferences menu item");
    NSString *creditsMenuItemTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Developed by @%@", @"AppDelegate", @"Title for credits menu item. %@ is replaced with the Twitter username."), kTwitterUsername];
    
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:preferencesMenuItemTitle action:@selector(showPreferences:) keyEquivalent:@""];
    [menu addItemWithTitle:quitMenuItemTitle action:@selector(quitApp:) keyEquivalent:@"Q"];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:creditsMenuItemTitle action:@selector(openTwitter:) keyEquivalent:@""];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"StatusBarIcon"];
    self.statusItem.alternateImage = [NSImage imageNamed:@"StatusBarIconHighlighted"];
    self.statusItem.menu = menu;
    self.statusItem.highlightMode = YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.statusItem = nil;
    self.settingsController = nil;
    self.spotify = nil;
    self.operationQueue = nil;
}

#pragma mark -
#pragma mark Private Methods

- (void)showPreferences:(id)sender
{
    if (!self.settingsController)
    {
        self.settingsController = [[PreferencesWindowController alloc] init];
    }
    
    [self.settingsController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateBulbColorsForCurrentTrack
{
    if (self.spotify.currentTrack.artwork)
    {
        [self setBulbsToColorsOfArtwort:self.spotify.currentTrack.artwork];
    }
    else
    {
        [self loadArtwork];
    }
}

- (void)loadArtwork
{
    if (!self.operationQueue)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    else
    {
        [self.operationQueue cancelAllOperations];
    }
    
    LoadArtworkOperation *operation = [[LoadArtworkOperation alloc] initWithTrack:self.spotify.currentTrack];
    operation.completionBlock = ^{
        [self setBulbsToColorsOfArtwort:self.spotify.currentTrack.artwork];
    };
    [self.operationQueue addOperation:operation];
}

- (void)setBulbsToColorsOfArtwort:(NSImage *)artwork
{
    NSString *host = [GVUserDefaults standardUserDefaults].host;
    if (!host)
    {
        // If the host is not defined, then we can't communicate with the bulbs
        return;
    }
    
    NSDictionary *lightColors = [GVUserDefaults standardUserDefaults].lightColors;
    
    SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:artwork scaledSize:NSMakeSize(300.0f, 300.0f) edge:NSMaxYEdge];
    
    DPHue *hue = [[DPHue alloc] initWithHueHost:host username:kColoredTunesAPIUsername];
    [hue readWithCompletion:^(DPHue *hue, NSError *error) {
        if (!error)
        {
            NSUInteger count = [hue.lights count];
            for (NSUInteger i = 0; i < count; i++)
            {
                DPHueLight *light = [hue.lights objectAtIndex:i];
                NSString *lightKey = [light.number stringValue];
                
                if (![[lightColors allKeys] containsObject:lightKey])
                {
                    // Check if the light exists in the configurations, if it doesn't,
                    // then it is meant to be inactive and thus not controlled by the app
                    continue;
                }
                
                NSInteger lightColorValue = [[lightColors objectForKey:lightKey] integerValue];
                NSColor *color = [self colorForLightColorValue:lightColorValue inColorArt:colorArt];

                // Convert color
                NSPoint xy;
                float brightness;
                [ColorCalculator calculateXY:&xy andBrightness:&brightness fromColor:color forModel:light.modelid];
                
                // If the brightness is zero, then we turn off the light to avoid incorrenct colors
                if (brightness <= 0.0f)
                {
                    light.on = NO;
                }
                else
                {
                    light.on = YES;
                    light.xy = @[ @(xy.x), @(xy.y) ];
                    light.brightness = @(roundf(254.0f * brightness));
                }
                
                // Send the configurations to the light bulb
                [light write];
            }
        }
        else
        {
            NSLog(@"Failed reading hue: %@", error);
        }
    }];
}

- (NSColor *)colorForLightColorValue:(NSInteger)lightColorValue inColorArt:(SLColorArt *)colorArt
{
    NSColor *color = nil;
    if (lightColorValue == kColorBackground)
    {
        color = colorArt.backgroundColor;
    }
    else if (lightColorValue == kColorPrimary)
    {
        color = colorArt.primaryColor;
    }
    else if (lightColorValue == kColorSecondary)
    {
        color = colorArt.secondaryColor;
    }
    else if (lightColorValue == kColorDetails)
    {
        return colorArt.detailColor;
    }
    else if (lightColorValue == kColorRandom)
    {
        NSInteger random = arc4random_uniform(kAmountOfColorTypes); // Random number between 0 and 3
        color = [self colorForLightColorValue:random inColorArt:colorArt];
    }
    
    return color;
}

- (void)quitApp:(id)sender
{
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0f];
}

- (void)openTwitter:(id)sender
{
    OSStatus result = LSFindApplicationForInfo(kLSUnknownCreator, CFSTR(kTweetbotAppBundleId), NULL, NULL, NULL);
    switch (result) {
        case noErr:
            [self openTwitterInTweetbot];
            break;
        case kLSApplicationNotFoundErr:
            [self openTwitterInBrowser];
            break;
        default:
            break;
    }
}

- (void)openTwitterInTweetbot
{
    NSString *urlString = [NSString stringWithFormat:@"tweetbot:///user_profile/%@", kTwitterUsername];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (void)openTwitterInBrowser
{
    NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", kTwitterUsername];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

#pragma mark -
#pragma mark Notifications

- (void)playbackStateChangedNotification:(NSNotification *)notification
{
    if (self.spotify.playerState == SpotifyClientEPlSPlaying)
    {
        [self updateBulbColorsForCurrentTrack];
    }
}

- (void)colorPreferencesChangedNotification:(NSNotification *)notification
{
    if (self.spotify.playerState == SpotifyClientEPlSPlaying)
    {
        [self updateBulbColorsForCurrentTrack];
    }
}

@end
