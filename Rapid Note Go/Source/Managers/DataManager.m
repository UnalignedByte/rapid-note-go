//
//  DataManager.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "DataManager.h"

#import "NotificationsManager.h"

#import "Note.h"

#import "APXML.h"


static NSString *kDoesUserWantCloudSetting = @"DoesUserWantCloud";


#pragma mark - Constants
static NSString *kLastCloudIdSetting = @"LastCloudId";


@interface DataManager()

@property (nonatomic, strong) NSManagedObjectModel *notesModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *notesStoreCoordinator;
@property (nonatomic, strong) NSPersistentStore *notesPersistentStore;
@property (nonatomic, strong) NSURL *notesStoreUrl;
@property (nonatomic, strong) NSURL *notesCloudUrl;
@property (nonatomic, strong) NSMetadataQuery *notesCloudQuery;
@property (nonatomic) id lastCloudId;
@property (nonatomic) BOOL shouldIgnoreNotesContextChanges;
@property (nonatomic) BOOL isUsingCloud;
@property (nonatomic) BOOL isCloudObserversAdded;
@property (nonatomic) BOOL isUploadingData;

@property (nonatomic, strong) void (^downloadBlock)();

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
    
    self.shouldIgnoreNotesContextChanges = NO;
    self.isCloudObserversAdded = NO;
    
    [self setupNotesModel];
    [self setupNotesStoreCoordinator];
    [self setupNotesContext];
    [self setupCloud];

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
    
    self.notesPersistentStore = [self.notesStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:self.notesStoreUrl
                                                                               options:nil
                                                                                 error:nil];
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
    
    self.notesCloudQuery = [[NSMetadataQuery alloc] init];
    self.notesCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K == 'notes.xml'", NSMetadataItemFSNameKey];
    self.notesCloudQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cloudDataChanged:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:self.notesCloudQuery];
    [self.notesCloudQuery startQuery];
    
    self.isCloudObserversAdded = YES;
}


- (void)removeCloudObservers
{
    if(self.isCloudObserversAdded) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUbiquityIdentityDidChangeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSMetadataQueryDidUpdateNotification
                                                      object:self.notesCloudQuery];
        [self.notesCloudQuery stopQuery];
    }
    
    self.isCloudObserversAdded = NO;
}


- (void)setupCloud
{
    _isUsingCloud = NO;
    
    if(self.doesUserWantCloud == nil || self.doesUserWantCloud.boolValue == NO)
        return;
    
    id cloudId = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if(cloudId == nil)
        return;
    
    NSURL *ubiquityUrl = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if(ubiquityUrl == nil)
        return;
    
    self.notesCloudUrl = [ubiquityUrl URLByAppendingPathComponent:@"Documents" isDirectory:YES];
    self.notesCloudUrl = [self.notesCloudUrl URLByAppendingPathComponent:@"notes.xml"];
    [self createDirectoryIfNecessary:self.notesCloudUrl];
    
    [self setupCloudObservers];
    
    //first time using iCloud
    if(self.lastCloudId == nil) {
        NSLog(@"First time");
        self.lastCloudId = cloudId;
        [self downloadCloudFileAtUrl:self.notesCloudUrl downloadFinished:^{
            BOOL shouldExportNotes = [self isThereNotUploadedNotes];
            [self mergeNotesFromCloud];
            if(shouldExportNotes)
                [self exportNotesToCloud];
        }];
    //same iCloud account as the last time
    } else if([self.lastCloudId isEqual:cloudId]) {
        NSLog(@"Again");
        [self downloadCloudFileAtUrl:self.notesCloudUrl downloadFinished:^{
            BOOL shouldExportNotes = [self isThereNotUploadedNotes];
            [self mergeNotesFromCloud];
            if(shouldExportNotes)
                [self exportNotesToCloud];
        }];
    //different iCloud account
    } else {
        NSLog(@"Other");
        self.lastCloudId = cloudId;
        self.shouldIgnoreNotesContextChanges = YES;
            [self deleteAllNotes];
            [_notesContext save:nil];
        self.shouldIgnoreNotesContextChanges = NO;
        
        [self downloadCloudFileAtUrl:self.notesCloudUrl downloadFinished:^{
            [self mergeNotesFromCloud];
        }];
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
- (id)lastCloudId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id lastUsedId = [defaults objectForKey:kLastCloudIdSetting];

    return lastUsedId;
}


- (void)setLastCloudId:(id)value_
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:value_ forKey:kLastCloudIdSetting];
}


- (NSNumber *)doesUserWantCloud
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kDoesUserWantCloudSetting];
}


- (void)setDoesUserWantCloud:(NSNumber *)value_
{
    [[NSUserDefaults standardUserDefaults] setValue:value_ forKey:kDoesUserWantCloudSetting];
}


#pragma mark - Notes Context Changes
- (void)notesContextChanged:(NSNotification *)notification_
{
    if(self.shouldIgnoreNotesContextChanges)
        return;
    
    NSLog(@"context changed and saved");
    [self.notesContext save:nil];
    
    if(_isUsingCloud)
        [self exportNotesToCloud];
}


#pragma mark - Internal Control
- (void)exportNotesToCloud
{
    NSLog(@"export");
    self.shouldIgnoreNotesContextChanges = YES;
    self.isUploadingData = YES;
    
    //create new xml and save it
    APElement *notesRootNode = [[APElement alloc] initWithName:@"rapid"];
    for(Note *note in [self allNotes]) {
        //new note element
        APElement *noteNode = [[APElement alloc] initWithName:@"note"];
        
        //add date element
        APElement *creationDateNode = [[APElement alloc] initWithName:@"date"];
        [creationDateNode appendValue:[note.creationDate description]];
        [noteNode addChild:creationDateNode];
        
        //add message node
        APElement *messageNode = [[APElement alloc] initWithName:@"message"];
        [messageNode appendValue:note.message];
        [noteNode addChild:messageNode];
        
        //add timer node (if timer date != 0)
        if(note.notificationDate != nil) {
            APElement *notificationDateNode = [[APElement alloc] initWithName:@"timer_date_time"];
            [notificationDateNode appendValue:[note.notificationDate description]];
            [noteNode addChild:notificationDateNode];
        }
        
        //add modification node (if modificaiton date !=)
        if(note.modificationDate != nil) {
            APElement *modificationDateNode = [[APElement alloc] initWithName:@"modification_date_time"];
            [modificationDateNode appendValue:[note.modificationDate description]];
            [noteNode addChild:modificationDateNode];
        }
        
        //add tag node
        APElement *tagNode = [[APElement alloc] initWithName:@"tag"];
        [tagNode appendValue:note.tag];
        [noteNode addChild:tagNode];
        
        //add note to the root
        [notesRootNode addChild:noteNode];
    }
    
    APDocument *notesDocument = [[APDocument alloc] initWithRootElement:notesRootNode];
    
    NSString *xmlString = [notesDocument xml];
    NSError *error;
    [xmlString writeToFile:self.notesCloudUrl.path atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if(error != nil) {
        NSLog(@"iCloud export failed: %d, %@", error.code, error.localizedDescription);
    }
    
    self.shouldIgnoreNotesContextChanges = NO;
}


- (void)mergeNotesFromCloud
{
    NSLog(@"merge");
    
    self.shouldIgnoreNotesContextChanges = YES;
    
    NSError *error;
    NSString *xmlString = [NSString stringWithContentsOfFile:self.notesCloudUrl.path encoding:NSUTF8StringEncoding error:&error];
    if(error != nil) {
        NSLog(@"iCloud merge failed: %d, %@", error.code, error.localizedDescription);
        return;
    }
    
    //this will be used to delete notes
    NSMutableArray *tagsFromXml = [NSMutableArray array];
    
    APDocument *notesDocument = [[APDocument alloc] initWithString:xmlString];
    
    NSArray *notes = [[notesDocument rootElement] childElements:@"note"];
    
    for(APElement *note in notes) {
        if([note childElements:@"message"].count <= 0)
            continue;
        if([note childElements:@"date"].count <= 0)
            continue;
        if([note childElements:@"tag"].count <= 0)
            continue;
        
        NSString *message = [(APElement *)[note childElements:@"message"][0] value];
        NSDate *creationDate = [self stringToDate:[(APElement *)[note childElements:@"date"][0] value]];
        NSString *tag = [(APElement *)[note childElements:@"tag"][0] value];
        NSDate *notificationDate = nil;
        NSDate *modificationDate = nil;
        
        //timer date & time
        if([note childElements:@"timer_date_time"].count >= 1) {
            notificationDate = [self stringToDate:[(APElement *)[note childElements:@"timer_date_time"][0] value]];
        }
        
        //modification date
        if([note childElements:@"modification_date_time"].count >= 1) {
            modificationDate = [self stringToDate:[(APElement *)[note childElements:@"modification_date_time"][0] value]];
        }
        
        [tagsFromXml addObject:tag];
        
        //Check if we already have note with the same tag
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_notesContext];
        fetchRequest.entity = entityDescription;
        fetchRequest.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"tag == '%@'", tag]];
        NSArray *fetchResult = [_notesContext executeFetchRequest:fetchRequest error:nil];
        //note exist, merge them together
        if(fetchResult != nil && fetchResult.count > 0) {
            Note *existingNote = fetchResult[0];
            existingNote.isUploaded = @YES;
            existingNote.modificationDate = modificationDate;
            existingNote.notificationDate = notificationDate;
            existingNote.message = message;
        //it's a new note, add it
        } else {
            Note *note = [self addNewNote];
            note.message = message;
            note.tag = tag;
            note.creationDate = creationDate;
            note.modificationDate = modificationDate;
            note.notificationDate = notificationDate;
            note.isUploaded = @YES;
        }
    }
    
    //remove all remotely deleted notes
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_notesContext];
    fetchRequest.entity = entityDescription;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"isUploaded == '%@'", @YES]];
    NSArray *fetchResult = [_notesContext executeFetchRequest:fetchRequest error:nil];
    for(Note *note in fetchResult) {
        if([tagsFromXml indexOfObject:note.tag] == NSNotFound) {
            [self deleteNote:note];
        }
    }
    
    
    [self.notesContext save:nil];
    
    //reset all notifications
    [[NotificationsManager sharedInstance] removeAllNotifications];
    [[NotificationsManager sharedInstance] addNotificationsForNotes:[self allNotes]];
    
    self.shouldIgnoreNotesContextChanges = NO;
    NSLog(@"merge finished");
}


- (void)downloadCloudFileAtUrl:(NSURL *)url_ downloadFinished:(void (^)())block_
{
    if(block_ == nil)
        return;

    //check if file exists
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.notesCloudUrl.path]) {
        return;
    }
    
    NSError *error;
    NSNumber *isDownloaded;
    
    [url_ getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:&error];
    if(error != nil) {
        NSLog(@"iCloud download failed: %d, %@", error.code, error.localizedDescription);
        return;
    }
    
    NSLog(@"Is downloaded: %d", isDownloaded.boolValue);
    
    if(isDownloaded.boolValue)
        return;
    
    self.downloadBlock = block_;
    
    //start downloading
    BOOL started = [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url_ error:&error];
    NSLog(@"started: %d", started);
    if(error != nil) {
        NSLog(@"iCloud download failed: %d, %@", error.code, error.localizedDescription);
        return;
    }
}

- (BOOL)isThereNotUploadedNotes
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_notesContext];
    fetchRequest.entity = entityDescription;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"isUploaded == '%@'", @NO]];
    NSArray *fetchResult = [_notesContext executeFetchRequest:fetchRequest error:nil];
    
    return fetchResult.count > 0;
}


#pragma mark - Control
- (void)reloadCloud
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self removeCloudObservers];
    [self setupCloud];
}


- (Note *)addNewNote
{
    Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                               inManagedObjectContext:_notesContext];
    
    NSDate *nowDate = [NSDate date];
    note.creationDate = nowDate;
    note.modificationDate = nowDate;
    note.isUploaded = @NO;
    
    //tag  uniquely identify each note
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    note.tag = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    
    return note;
}


- (NSArray *)allNotes
{
    NSFetchRequest *notesFetchRequest = [[NSFetchRequest alloc] init];
    //entity
    NSEntityDescription *notesEntityDescription = [NSEntityDescription entityForName:@"Note"
                                                              inManagedObjectContext:_notesContext];
    [notesFetchRequest setEntity:notesEntityDescription];
    //sorting
    NSSortDescriptor *notesSort = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO];
    [notesFetchRequest setSortDescriptors:@[notesSort]];
    
    NSArray *notes = [_notesContext executeFetchRequest:notesFetchRequest error:nil];

    return notes;
}


- (void)deleteNote:(Note *)note_
{
    [_notesContext deleteObject:note_];
}


- (void)deleteAllNotes
{
    NSArray *notes = [self allNotes];
    for(Note *note in notes) {
        [[NotificationsManager sharedInstance] removeNotificationForNote:note];
        [self deleteNote:note];
    }
}


#pragma mark - iCloud support
- (void)cloudAvailabilityChanged:(NSNotification *)notification_
{
    NSLog(@"Availability changed");
    
    [self reloadCloud];
}


- (void)cloudDataChanged:(NSNotification *)notification_
{
    if(!_isUsingCloud)
        return;

    if([notification_.object resultCount] <= 0)
        return;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSLog(@"Data changed");
    NSMetadataItem *metadataItem =  (NSMetadataItem *)[[notification_ object] resultAtIndex:0];
    
    BOOL isDownloading = [[metadataItem valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey] boolValue];
    BOOL isDownloaded = [[metadataItem valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey] boolValue];
    
    BOOL isUploading = [[metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey] boolValue];
    BOOL isUploaded = [[metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey] boolValue];
    
    NSLog(@"Downloaded: %d, Downloading: %d", isDownloaded, isDownloading);
    NSLog(@"Uploaded: %d, Uploading: %d", isUploaded, isUploading);

    //new data is downloaded
    if(isDownloaded && isUploaded && self.downloadBlock != nil) {
        self.downloadBlock();
        self.downloadBlock = nil;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else if(isDownloaded && isUploaded) {
        if(self.isUploadingData) {
            self.shouldIgnoreNotesContextChanges = YES;
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_notesContext];
            fetchRequest.entity = entityDescription;
            fetchRequest.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"isUploaded == '%@'", @NO]];
            NSArray *fetchResult = [_notesContext executeFetchRequest:fetchRequest error:nil];
            for(Note *note in fetchResult) {
                note.isUploaded = @YES;
            }
            
            _shouldIgnoreUpdates = YES;
            [_notesContext save:nil];
            _shouldIgnoreUpdates = NO;

            self.shouldIgnoreNotesContextChanges = NO;
            self.isUploadingData = NO;
        } else {
            [self mergeNotesFromCloud];
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
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


- (NSString *)dateToString:(NSDate *)date_
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    NSString *string = [dateFormatter stringFromDate:date_];
    return string;
}


- (NSDate *)stringToDate:(NSString *)string_
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    NSDate *date = [dateFormatter dateFromString:string_];
    return date;
}

@end
