//
//  NotificationsManager.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 02.02.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Note;


@interface NotificationsManager : NSObject

//Singleton
+ (NotificationsManager *)sharedInstance;

//Control
- (void)addNotificationForNote:(Note *)note_;
- (void)addNotificationsForNotes:(NSArray *)notes_;
- (void)removeNotificationForNote:(Note *)note_;
- (void)removeAllNotifications;

@end
