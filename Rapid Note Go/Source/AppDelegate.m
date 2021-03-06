//
//  AppDelegate.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 17.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "AppDelegate.h"

#import "DataManager.h"
#import "NotificationsManager.h"

#import "RootVC.h"


#pragma mark - Private properties
@interface AppDelegate()

@property (nonatomic, strong) UIViewController *rootVC;

@end


@implementation AppDelegate

#pragma mark - Initialization
- (BOOL)application:(UIApplication *)application_ didFinishLaunchingWithOptions:(NSDictionary *)options_
{
    if([DataManager sharedInstance].doesUserWantCloud == nil) {
        UIAlertView *questionAlert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:Localize(@"Do you want to enable iCloud and enjoy all the awesomeness that Rapid Note Go can give you?")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:Localize(@"Enable"), Localize(@"Don't Enable"), nil];
        [questionAlert show];
    }

    //propagate handling of notification
    UILocalNotification *notification = options_[UIApplicationLaunchOptionsLocalNotificationKey];
    if(notification != nil) {
        [self application:nil didReceiveLocalNotification:notification];
    }
    
    //reset all notifications
    [[NotificationsManager sharedInstance] removeAllNotifications];
    [[NotificationsManager sharedInstance] addNotificationsForNotes:[[DataManager sharedInstance] allNotes]];
    
    return YES;
}


#pragma mark - Application lifecycle
- (void)applicationWillResignActive:(UIApplication *)application_
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark - Local Notifications Delegate
- (void)application:(UIApplication *)application_ didReceiveLocalNotification:(UILocalNotification *)notification_
{
    [[UIApplication sharedApplication] cancelLocalNotification:notification_];
    
    NSString *tag = notification_.userInfo[@"tag"];
    if(tag == nil)
        return;

    RootVC *rootVC = (RootVC *)self.rootVC;
    [rootVC showNoteForTag:tag];
}


#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView_ clickedButtonAtIndex:(NSInteger)buttonIndex_
{
    switch(buttonIndex_) {
        case 0:
            [DataManager sharedInstance].doesUserWantCloud = @YES;
            break;
            
        case 1:
            [DataManager sharedInstance].doesUserWantCloud = @NO;
            break;
    }
    
    [[DataManager sharedInstance] reloadCloud];
}

@end
