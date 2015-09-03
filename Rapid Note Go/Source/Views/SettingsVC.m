//
//  SettingsVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 11.03.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "SettingsVC.h"

#import "DataManager.h"


@interface SettingsVC ()

@property (nonatomic, weak) IBOutlet UILabel *doesUserWantCloudLabel;
@property (nonatomic, weak) IBOutlet UISwitch *doesUserWantCloudSwitch;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton *homepageButton;

@end


@implementation SettingsVC

#pragma mark - Initializaiton
- (id)init
{
    if((self = [super initWithNibName:@"SettingsView" bundle:nil]) == nil)
        return nil;

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background Pattern Dark"]];
    self.title = Localize(@"Preferences + Info");
    [self setupNavigationButtons];
    
    return self;
}


- (void)viewDidLoad
{
    self.doesUserWantCloudSwitch.on = [DataManager sharedInstance].doesUserWantCloud.boolValue;
    [self setupTranslations];

    self.automaticallyAdjustsScrollViewInsets = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}


- (void)setupNavigationButtons
{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Close")
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(closeAction:)];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = closeButton;
}


- (void)setupTranslations
{
    self.doesUserWantCloudLabel.text = Localize(@"Use iCloud");
    self.versionLabel.text = [NSString stringWithFormat:@"%@ %@",
                              Localize(@"Version"),
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    self.descriptionLabel.text = Localize(@"Rapid Note Go has been designed and developed by Rafał Grodziński. Thanks for using :)\n\nGet Rapid Note for OS X to fully utilize power of Rapid Note Go\n\nDon't forget to rate app in the App Store and visit UnalignedByte homepage!");
    [self.homepageButton setTitle:Localize(@"UnalignedByte Homepage") forState:UIControlStateNormal];
}


#pragma mark - Internal Control
- (void)closeView
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void)cloudChangedTo:(BOOL)newCloudState_
{
    if(newCloudState_ != [DataManager sharedInstance].doesUserWantCloud.boolValue) {
        [DataManager sharedInstance].doesUserWantCloud = [NSNumber numberWithBool:newCloudState_];
        [[DataManager sharedInstance] reloadCloud];
    }
}


- (void)openHomepage
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://unalignedbyte.com/"]];
}


#pragma mark - Actions
- (IBAction)closeAction:(id)sender_
{
    [self closeView];
}


- (IBAction)cloudSwitchedAction:(id)sender_
{
    [self cloudChangedTo:[(UISwitch *)sender_ isOn]];
}


- (IBAction)openHomepageAction:(id)sender_
{
    [self openHomepage];
}

@end
