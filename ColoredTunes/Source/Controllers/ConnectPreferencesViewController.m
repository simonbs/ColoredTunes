//
//  ConnectPreferencesViewController.m
//  ColoredTunes
//
//  Created by Simon Støvring on 06/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "ConnectPreferencesViewController.h"
#import "DPHue.h"

@interface ConnectPreferencesViewController ()
@property (nonatomic, strong) DPHueDiscover *discover;
@property (nonatomic, strong) NSString *foundHost;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) IBOutlet NSButton *searchButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *disconnectButton;
@property (nonatomic, weak) IBOutlet NSTextField *statusLabel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@end

@implementation ConnectPreferencesViewController

#pragma mark -
#pragma mark Lifecycle

- (id)init
{
    return [super initWithNibName:@"ConnectPreferencesView" bundle:nil];
}

- (void)loadView
{
    [super loadView];
    
    [self showCurrentHostInStatusLabel];
    
    if ([GVUserDefaults standardUserDefaults].host)
    {
        self.searchButton.hidden = YES;
        self.cancelButton.hidden = YES;
        self.disconnectButton.hidden = NO;
    }
    else
    {
        self.searchButton.hidden = NO;
        self.cancelButton.hidden = YES;
        self.disconnectButton.hidden = YES;
    }
}

- (void)dealloc
{
    self.discover = nil;
    self.foundHost = nil;
    self.timer = nil;
    self.searchButton = nil;
    self.cancelButton = nil;
    self.statusLabel = nil;
    self.progressIndicator = nil;
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)startDiscovery:(id)sender
{
    self.statusLabel.stringValue = NSLocalizedStringFromTable(@"Searching for bridge...", @"ConnectPreferencesViewController", @"Text in status label when searching for a bridge.");
    
    [self.progressIndicator startAnimation:self];
    
    self.searchButton.hidden = YES;
    self.cancelButton.hidden = NO;
    self.disconnectButton.hidden = YES;
    
    self.foundHost = nil;
    
    self.discover = [[DPHueDiscover alloc] initWithDelegate:self];
    [self.discover discoverForDuration:30 withCompletion:^(NSMutableString *log) {
        [self discoveryTimeHasElapsed];
    }];
}

- (IBAction)cancelDiscovery:(id)sender
{
    [self showCurrentHostInStatusLabel];
    
    [self.discover stopDiscovery];
    self.discover = nil;
    
    [self.timer invalidate];
    
    [self.progressIndicator stopAnimation:self];
    
    self.searchButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.disconnectButton.hidden = YES;
}

- (IBAction)disconnect:(id)sender
{
    self.foundHost = nil;
    [GVUserDefaults standardUserDefaults].host = nil;
    [GVUserDefaults standardUserDefaults].lightColors = [NSDictionary dictionary]; // Reset any previous configurations
    
    [self showCurrentHostInStatusLabel];
    
    self.searchButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.disconnectButton.hidden = YES;
}

- (void)discoveryTimeHasElapsed
{
    self.discover = nil;
    
    [self.timer invalidate];
    
    [self.progressIndicator stopAnimation:self];
    
    if (!self.foundHost)
    {
        self.statusLabel.stringValue = NSLocalizedStringFromTable(@"Failed finding host. Please try agian.", @"ConnectPreferencesViewController", @"Text in status label when the discovery timed out.");
        
        self.searchButton.hidden = NO;
        self.cancelButton.hidden = YES;
        self.disconnectButton.hidden = YES;
    }
}

- (void)saveDiscovery
{
    [self.progressIndicator stopAnimation:self];
    
    self.searchButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.disconnectButton.hidden = YES;
    
    NSLog(@"Save: %@", self.foundHost);
    
    [GVUserDefaults standardUserDefaults].host = self.foundHost;
}

- (void)createUsernameAt:(NSTimer *)timer
{
    NSString *host = timer.userInfo;
    DPHue *someHue = [[DPHue alloc] initWithHueHost:host username:kColoredTunesAPIUsername];
    [someHue readWithCompletion:^(DPHue *hue, NSError *error) {
        if (hue.authenticated) {
            [self saveDiscovery];
            
            [self.timer invalidate];
            
            self.searchButton.hidden = YES;
            self.cancelButton.hidden = YES;
            self.disconnectButton.hidden = NO;
            
            [self.progressIndicator stopAnimation:self];
            
            self.foundHost = hue.host;
            
            self.statusLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Found bridge at %@", @"ConnectPreferencesViewController", @"Text in status label when a hue is found and authenticated. %@ is replaced with the host."), host];
        }
        else
        {
            [someHue registerUsername];
            
            self.statusLabel.stringValue = NSLocalizedStringFromTable(@"Press button on bridge...", @"ConnectPreferencesViewController", @"Text in status label when the user must press the button on the bridge.");
        }
    }];
}

- (void)showCurrentHostInStatusLabel
{
    NSString *host = [GVUserDefaults standardUserDefaults].host;
    if (host)
    {
        self.statusLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Connected to bridge at %@", @"ConnectPreferencesViewController", @"Text in status label when a bridge is saved. %@ is replaced with the host."), host];
    }
    else
    {
        self.statusLabel.stringValue = NSLocalizedStringFromTable(@"Not connected to a bridge", @"ConnectPreferencesViewController", @"Text in status label when there is no connection to a brdige.");
    }
}

#pragma mark -
#pragma mark Hue Discover Delegate

- (void)foundHueAt:(NSString *)host discoveryLog:(NSString *)log
{
    if (!self.foundHost)
    {
        self.foundHost = host;
        
        self.statusLabel.stringValue = NSLocalizedStringFromTable(@"Bridge found! Authenticating...", @"ConnectPreferencesViewController", @"Text in status label when a hue is found.");

        DPHue *someHue = [[DPHue alloc] initWithHueHost:host username:kColoredTunesAPIUsername];
        [someHue readWithCompletion:^(DPHue *hue, NSError *error) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(createUsernameAt:) userInfo:host repeats:YES];
        }];
    }
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"ConnectPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameNetwork];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedStringFromTable(@"Connect", @"ConnectViewController", @"Title for item");
}

@end
