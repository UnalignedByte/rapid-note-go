//
//  DataManager.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Note;


@interface DataManager : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *notesContext;
@property (nonatomic, readonly) BOOL isUsingCloud;
@property (nonatomic, readonly) BOOL shouldIgnoreUpdates;


//Singleton
+ (DataManager *)sharedInstance;

//Control
- (Note *)addNewNote;
- (void)deleteNote:(Note *)note_;
- (NSArray *)allNotes;
- (void)deleteAllNotes;

@end
