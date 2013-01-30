//
//  NotesListVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NotesListVC.h"

#import "DataManager.h"

#import "Note.h"

#import "NoteCell.h"


#pragma mark - Private properties
@interface NotesListVC ()

@property (nonatomic, strong) NSFetchedResultsController *notesResultsController;

@end


@implementation NotesListVC

#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;
    
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addNoteAction:)];
    self.navigationItem.rightBarButtonItem = addNoteButton;
    
    [self setupNotesResultsController];

    return self;
}


- (void)setupNotesResultsController
{
    NSFetchRequest *notesFetchRequest = [[NSFetchRequest alloc] init];
    //entity
    NSEntityDescription *notesEntityDescription = [NSEntityDescription entityForName:@"Note"
                                                              inManagedObjectContext:[DataManager sharedInstance].notesContext];
    [notesFetchRequest setEntity:notesEntityDescription];
    //sorting
    NSSortDescriptor *notesSort = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    [notesFetchRequest setSortDescriptors:@[notesSort]];
    //fetch size
    [notesFetchRequest setFetchBatchSize:10];
    
    self.notesResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:notesFetchRequest
                                                                  managedObjectContext:[DataManager sharedInstance].notesContext
                                                                    sectionNameKeyPath:nil
                                                                             cacheName:@"notes"];
    self.notesResultsController.delegate = self;
    
    NSError *err;
    
    if(![self.notesResultsController performFetch:&err]) {
        abort();
    }
}


#pragma mark - Table View Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView_
{
    return self.notesResultsController.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView_ numberOfRowsInSection:(NSInteger)section_
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.notesResultsController.sections[section_];
    return  [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath_
{
    NoteCell *noteCell = [tableView_ dequeueReusableCellWithIdentifier:kNoteCellIdentifier];
    
    if(noteCell == nil)
        noteCell = [[NoteCell alloc] init];
    
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
    [noteCell configureWithNote:note];
    
    return noteCell;
}


- (void)tableView:(UITableView *)tableView_ didDeselectRowAtIndexPath:(NSIndexPath *)indexPath_
{
    [tableView_ deselectRowAtIndexPath:indexPath_ animated:YES];
    
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
}


#pragma mark - Fetched Results Controller Delegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller_
{
    [self.tableView reloadData];
}


#pragma mark - Actions
- (void)addNoteAction:(id)sender_
{
    Note *note = [[DataManager sharedInstance] createNote];
}

@end
