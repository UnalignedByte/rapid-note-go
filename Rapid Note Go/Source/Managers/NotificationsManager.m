//
//  NotificationsManager.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 02.02.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NotificationsManager.h"

#import "Note.h"


#pragma mark - Private Properties
@interface NotificationsManager ()

@property (nonatomic, strong) NSMutableDictionary *notifications;

@end


@implementation NotificationsManager

#pragma mark - Singleton
+ (NotificationsManager *)sharedInstance
{
    static NotificationsManager *sharedInstance;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedInstance = [[NotificationsManager alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;
    
    self.notifications = [NSMutableDictionary dictionary];
    
    return self;
}


#pragma mark - Control
- (void)addNotificationForNote:(Note *)note_
{
    if([note_.notificationDate compare:[NSDate date]] != NSOrderedDescending) {
        note_.notificationDate = nil;
        return;
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = note_.message;
    notification.hasAction = YES;
    notification.alertAction = Localize(@"Show");
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.userInfo = @{@"tag" : note_.tag};
    notification.fireDate = note_.notificationDate;
    
    [self.notifications setObject:notification forKey:note_.tag];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}


- (void)addNotificationsForNotes:(NSArray *)notes_
{
    for(Note *note in notes_)
        [self addNotificationForNote:note];
}


- (void)removeNotificationForNote:(Note *)note_
{
    UILocalNotification *notification = self.notifications[note_.tag];
    
    if(notification == nil)
        return;
    
    [[UIApplication sharedApplication] cancelLocalNotification:notification];
}


- (void)removeAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end
