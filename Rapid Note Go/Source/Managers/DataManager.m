//
//  DataManager.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "DataManager.h"

#import "Note.h"


#pragma mark - Constants
static NSString *kDefaultLastCloudId = @"";

static NSString *kLastCloudIdSetting = @"LastCloudId";


@interface DataManager()

@property (nonatomic, strong) NSManagedObjectModel *notesModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *notesStoreCoordinator;
@property (nonatomic, strong) NSPersistentStore *notesPersistentStore;
@property (nonatomic, strong) NSURL *notesStoreUrl;
@property (nonatomic, strong) NSURL *notesCloudUrl;
@property (nonatomic) NSString *lastCloudId;

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
    
    [self setupNotesModel];
    [self setupNotesStoreCoordinator];
    [self setupCloudObservers];
    [self setupCloud];
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
    self.notesStoreUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    self.notesStoreUrl = [self.notesStoreUrl URLByAppendingPathComponent:@"notes.sqlite"];
    [self createDirectoryIfNecessary:self.notesStoreUrl];
    
    self.notesStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.notesModel];
    
    NSError *error;
    self.notesPersistentStore = [self.notesStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:self.notesStoreUrl
                                                                               options:nil
                                                                                 error:&error];
    if(self.notesPersistentStore == nil) {
        abort();
    }
}


- (void)setupCloudObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloudAvailabilityChanged:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloudIdChanged:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloudDataChanged:)
                                                 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                               object:nil];
}


- (void)setupCloud
{
    _isUsingCloud = NO;
    
    id cloudId = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if(cloudId == nil)
        return;
    
    NSURL *ubiquityUrl = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if(ubiquityUrl == nil)
        return;
    
    self.notesCloudUrl = [ubiquityUrl URLByAppendingPathComponent:@"Documents" isDirectory:YES];
    self.notesCloudUrl = [self.notesCloudUrl URLByAppendingPathComponent:@"notes.xml"];
    [self createDirectoryIfNecessary:self.notesCloudUrl];
    
    //first time using iCloud
    if(self.lastCloudId == nil) {
        self.lastCloudId = cloudId;
        [self mergeNotesFromCloud];
        [self exportNotesToCloud];
    //same iCloud account as the last time
    } else if(self.lastCloudId == cloudId) {
        [self mergeNotesFromCloud];
        [self exportNotesToCloud];
    //different iCloud account
    } else if(self.lastCloudId) {
        self.lastCloudId = cloudId;
        [self importNotesFromCloud];
    }
    
    _isUsingCloud = YES;
}


- (void)setupNotesContext
{
    _notesContext = [[NSManagedObjectContext alloc] init];
    _notesContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    [_notesContext setPersistentStoreCoordinator:self.notesStoreCoordinator];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notesContextChanged:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.notesContext];
}


#pragma mark - Property getters/setters
- (NSString *)lastCloudId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastUsedId = [defaults objectForKey:kLastCloudIdSetting];
    
    if(lastUsedId == nil || lastUsedId.length == 0) {
        self.lastCloudId = kDefaultLastCloudId;
        return nil;
    }
    
    return lastUsedId;
}


- (void)setLastCloudId:(NSString *)value_
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(value_ == nil || value_.length == 0)
        [defaults setObject:@"" forKey:kLastCloudIdSetting];
    else
        [defaults setObject:value_ forKey:kLastCloudIdSetting];
}


#pragma mark - Notes Context Changes
- (void)notesContextChanged:(NSNotification *)notification_
{
    NSError *error;
    if(![self.notesContext save:&error]) {
        abort();
    }
}


#pragma mark - Internal Control
- (void)exportNotesToCloud
{
}


- (void)importNotesFromCloud
{
}


- (void)mergeNotesFromCloud
{
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


- (void)emptyNotesStore
{
    NSArray *notes = [self allNotes];
    for(Note *note in notes)
        [self deleteNote:note];
}


#pragma mark - iCloud support
- (void)cloudAvailabilityChanged:(NSNotification *)notification_
{
    NSLog(@"Availability changed");
    
    [self setupCloud];
}


- (void)cloudIdChanged:(NSNotification *)notification_
{
    NSLog(@"ID changed");
    
    [self setupCloud];
}


- (void)cloudDataChanged:(NSNotification *)notification_
{
    NSLog(@"Data changed");
    
    [self mergeNotesFromCloud];
}


#pragma mark - Utilities
- (void)createDirectoryIfNecessary:(NSURL *)url_
{
    NSString *dirPath;
    
    NSString *pathExtension = [url_ pathExtension];
    if(pathExtension != nil && pathExtension.length > 0)
        dirPath = [url_ URLByDeletingLastPathComponent].path;
    else
        dirPath = url_.path;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:NULL
                                                        error:NULL];
    }
}

@end
