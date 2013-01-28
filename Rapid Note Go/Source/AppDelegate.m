//
//  AppDelegate.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 17.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "AppDelegate.h"

#import "PhoneRootVC.h"
#import "PadRootVC.h"


#pragma mark - Private properties
@interface AppDelegate()

@property (nonatomic, strong) UIWindow *appWindow;
@property (nonatomic, strong) UIViewController *rootVC;

@end


@implementation AppDelegate

#pragma mark - Initialization
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.appWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.rootVC = [[PhoneRootVC alloc] init];
    else
        self.rootVC = [[PadRootVC alloc] init];
        
    
    self.appWindow.rootViewController = self.rootVC;
    [self.appWindow makeKeyAndVisible];
    
    return YES;
}

@end
