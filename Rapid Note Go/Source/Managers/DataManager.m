//
//  DataManager.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "DataManager.h"

#import "Note.h"


@interface DataManager()

@property (nonatomic, strong) NSManagedObjectModel *notesModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *notesStoreCoordinator;
@property (nonatomic, strong) NSURL *notesStoreUrl;

@end


@implementation DataManager

#pragma mark - Singleton
+ (DataManager *)sharedInstance
{
    static DataManager *sharedInstance;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedInstance = [[DataManager alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;
    
    self.notesStoreUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    self.notesStoreUrl = [self.notesStoreUrl URLByAppendingPathComponent:@"notes.sqlite"];
    
    [self setupNotesModel];
    [self setupNotesStoreCoordinator];
    [self setupNotesContext];

    return self;
}


- (void)setupNotesModel
{
    NSURL *notesModelUrl = [[NSBundle mainBundle] URLForResource:@"Notes" withExtension:@"momd"];
    self.notesModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:notesModelUrl];
}


- (void)setupNotesStoreCoordinator
{
    self.notesStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.notesModel];
    
    NSError *error;
    if(![self.notesStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                             configuration:nil
                                                       URL:self.notesStoreUrl
                                                   options:nil
                                                          error:&error]) {
        abort();
    }
}


- (void)setupNotesContext
{
    _notesContext = [[NSManagedObjectContext alloc] init];
    [_notesContext setPersistentStoreCoordinator:self.notesStoreCoordinator];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notesContextChanged:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.notesContext];
}


#pragma mark - Notes Context Changes
- (void)notesContextChanged:(NSNotification *)notification_
{
    NSError *error;
    if(![self.notesContext save:&error]) {
        abort();
    }
}


#pragma mark - Control
- (Note *)addNewNote
{
    Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                               inManagedObjectContext:_notesContext];
    
    note.creationDate = [NSDate date];
    note.modificationDate = note.creationDate;
    
    //tag  uniquely identify each note
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    note.tag = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    
    return note;
}


- (void)deleteNote:(Note *)note_
{
    [_notesContext deleteObject:note_];
}


- (NSArray *)allNotes
{
    NSFetchRequest *notesFetchRequest = [[NSFetchRequest alloc] init];
    //entity
    NSEntityDescription *notesEntityDescription = [NSEntityDescription entityForName:@"Note"
                                                              inManagedObjectContext:[DataManager sharedInstance].notesContext];
    [notesFetchRequest setEntity:notesEntityDescription];
    //sorting
    NSSortDescriptor *notesSort = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO];
    [notesFetchRequest setSortDescriptors:@[notesSort]];
    
    NSError *error;
    NSArray *notes = [_notesContext executeFetchRequest:notesFetchRequest error:&error];

    return notes;
}

@end
