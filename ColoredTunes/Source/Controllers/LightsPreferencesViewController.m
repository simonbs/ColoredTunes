//
//  LightsPreferencesViewController.m
//  ColoredTunes
//
//  Created by Simon Støvring on 07/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "LightsPreferencesViewController.h"
#import "LightCell.h"
#import "DPHue.h"
#import "DPHueLight.h"

enum {
    kColorButtonIndexInactive = 0,
    kColorButtonIndexBackground,
    kColorButtonIndexPrimary,
    kColorButtonIndexSecondary,
    kColorButtonIndexDetails,
};

#define kTableViewLightCellIdentifier @"LightCell"

@interface LightsPreferencesViewController ()
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *colorButton;
@property (nonatomic, strong) NSArray *lights;
@end

@implementation LightsPreferencesViewController

#pragma mark -
#pragma mark Lifecycle

- (id)init
{
    return [super initWithNibName:@"LightsPreferencesView" bundle:nil];
}

- (void)viewWillAppear
{
    [self loadLights];
}

- (void)dealloc
{
    self.tableView = nil;
    self.colorButton = nil;
    self.lights = nil;
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)colorChanged:(id)sender
{
    DPHueLight *selectedLight = [self.lights objectAtIndex:[self.tableView selectedRow]];
    NSString *lightKey = [selectedLight.number stringValue];
    NSMutableDictionary *lightColors = [NSMutableDictionary dictionaryWithDictionary:[GVUserDefaults standardUserDefaults].lightColors];
    NSInteger index = [self.colorButton indexOfSelectedItem];
    switch (index) {
        case kColorButtonIndexInactive:
            if ([[lightColors allKeys] containsObject:lightKey])
            {
                [lightColors removeObjectForKey:lightKey];
            }
            break;
        case kColorButtonIndexBackground:
            [lightColors setValue:@(kColorBackground) forKey:lightKey];
            break;
        case kColorButtonIndexPrimary:
            [lightColors setValue:@(kColorPrimary) forKey:lightKey];
            break;
        case kColorButtonIndexSecondary:
            [lightColors setValue:@(kColorSecondary) forKey:lightKey];
            break;
        case kColorButtonIndexDetails:
            [lightColors setValue:@(kColorDetails) forKey:lightKey];
            break;
        default:
            break;
    }
    
    [GVUserDefaults standardUserDefaults].lightColors = lightColors;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CTColorPreferencesChangedNotification object:nil];
}

- (void)loadLights
{
    NSString *host = [GVUserDefaults standardUserDefaults].host;
    if (!host)
    {
        // If we don't have a host, then we aren't connected to a bridge and therefore
        // we don't know any lights. Remove all lights, if any were shown previously
        self.lights = nil;
        [self.tableView reloadData];
        [self noLightSelected];
        return;
    }
    
    DPHue *hue = [[DPHue alloc] initWithHueHost:host username:kColoredTunesAPIUsername];
    [hue readWithCompletion:^(DPHue *hue, NSError *error) {
        if (!error)
        {
            self.lights = hue.lights;
            [self.tableView reloadData];
            
            [self noLightSelected];
        }
        else
        {
            NSLog(@"Could not load lights: %@", error);
        }
    }];
}

- (void)lightSelectedAtIndex:(NSInteger)index
{
    self.colorButton.enabled = YES;
    
    DPHueLight *selectedLight = [self.lights objectAtIndex:[self.tableView selectedRow]];
    NSString *lightKey = [selectedLight.number stringValue];
    NSDictionary *lightColors = [GVUserDefaults standardUserDefaults].lightColors;
    if ([[lightColors allKeys] containsObject:lightKey])
    {
        NSInteger color = [[lightColors objectForKey:lightKey] integerValue];
        switch (color) {
            case kColorInactive:
                [self.colorButton selectItemAtIndex:kColorButtonIndexInactive];
                break;
            case kColorBackground:
                [self.colorButton selectItemAtIndex:kColorButtonIndexBackground];
                break;
            case kColorPrimary:
                [self.colorButton selectItemAtIndex:kColorButtonIndexPrimary];
                break;
            case kColorSecondary:
                [self.colorButton selectItemAtIndex:kColorButtonIndexSecondary];
                break;
            case kColorDetails:
                [self.colorButton selectItemAtIndex:kColorButtonIndexDetails];
                break;
            default:
                break;
        }
    }
    else
    {
        [self.colorButton selectItemAtIndex:kColorButtonIndexInactive];
    }
}

- (void)noLightSelected
{
    [self.colorButton selectItemAtIndex:kColorButtonIndexInactive];
    self.colorButton.enabled = NO;
}

#pragma mark -
#pragma mark Table View Data Source

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LightCell *cell = [tableView makeViewWithIdentifier:kTableViewLightCellIdentifier owner:self];
    
    DPHueLight *light = [self.lights objectAtIndex:row];
    cell.name = light.name;
    
    return cell;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.lights count];
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow == -1)
    {
        [self noLightSelected];
    }
    else
    {
        [self lightSelectedAtIndex:selectedRow];
    }
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"LightsPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedStringFromTable(@"Lights", @"LightsViewController", @"Title for item");
}

@end
