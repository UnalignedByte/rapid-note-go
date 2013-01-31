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

#import "NoteDetailsVC.h"


#define INPUT_ANIMATION_DURATION 0.3


#pragma mark - Private properties
@interface NotesListVC ()

@property (nonatomic, strong) UITableViewController *tableVC;
@property (nonatomic, strong) NSFetchedResultsController *notesResultsController;
@property (nonatomic, strong) IBOutlet UIView *noteInputView;
@property (nonatomic, strong) IBOutlet UITextView *noteInputText;
@property (nonatomic, strong) IBOutlet UIView *noteInputBackground;

@end


@implementation NotesListVC

#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;
    
    self.title = Localize(@"Notes");
    
    [self setupTable];
    [self setupNavigationButtonsForAdding];
    [self setupNotesResultsController];
    [self setupNoteInput];

    return self;
}


- (void)setupTable
{
    self.tableVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    CGRect tableRect = self.view.frame;
    tableRect.origin.y = 0;
    self.tableVC.tableView.frame = tableRect;
    [self.view addSubview:self.tableVC.tableView];
    self.tableVC.tableView.dataSource = self;
    self.tableVC.tableView.delegate = self;
}


- (void)setupNavigationButtonsForAdding
{
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(showNoteInputAction:)];
    self.navigationItem.rightBarButtonItem = addNoteButton;
    self.navigationItem.leftBarButtonItem = nil;
}


- (void)setupNavigationButtonsForEditing
{
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Add")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(addNoteAction:)];
    UIBarButtonItem *cancelNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancelNoteAction:)];
    self.navigationItem.rightBarButtonItem = addNoteButton;
    self.navigationItem.leftBarButtonItem = cancelNoteButton;
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


- (void)setupNoteInput
{
    [[NSBundle mainBundle] loadNibNamed:@"NoteInputView" owner:self options:nil];
    //[self.view addSubview:self.noteInputView];
    [self.view addSubview:self.noteInputView];
    [self.view bringSubviewToFront:self.noteInputView];
    //move input view up
    CGRect noteInputRect = self.noteInputView.frame;
    noteInputRect.origin.y = -self.noteInputBackground.frame.size.height;
    self.noteInputView.frame = noteInputRect;
    //hide the view for the moment
    self.noteInputView.alpha = 0.0;
}


#pragma mark - Internal Control
- (void)showInput
{
    self.inputView.userInteractionEnabled = YES;
    CGRect noteInputRect = self.noteInputView.frame;
    noteInputRect.origin.y = 0.0;
    [self.noteInputText becomeFirstResponder];
    
    [self setupNavigationButtonsForEditing];
    
    [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:INPUT_ANIMATION_DURATION];
        self.noteInputView.alpha = 1.0;
        self.noteInputView.frame = noteInputRect;
    [UIView commitAnimations];
}


- (void)hideInput
{
    self.inputView.userInteractionEnabled = NO;
    CGRect noteInputRect = self.noteInputView.frame;
    noteInputRect.origin.y = -self.noteInputBackground.frame.size.height;
    [self.noteInputText resignFirstResponder];
    
    [self setupNavigationButtonsForAdding];
    
    [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:INPUT_ANIMATION_DURATION];
        self.noteInputView.alpha = 0.0;
        self.noteInputView.frame = noteInputRect;
    [UIView commitAnimations];
    
    self.noteInputText.text = @"";
}


- (void)addNote
{
    //check if message entered is empty
    NSString *noSpaces = [self.noteInputText.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if(noSpaces.length > 0) {
        Note *note = [[DataManager sharedInstance] addNewNote];
        note.message = self.noteInputText.text;
        [self hideInput];
    }
}


- (void)cancelNote
{
    [self hideInput];
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


- (CGFloat)tableView:(UITableView *)tableView_ heightForRowAtIndexPath:(NSIndexPath *)indexPath_
{
    return [NoteCell height];
}


- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath_
{
    [tableView_ deselectRowAtIndexPath:indexPath_ animated:YES];
    
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
    
    NoteDetailsVC *noteDetailsVC = [[NoteDetailsVC alloc] initWithNote:note];
    [self.navigationController pushViewController:noteDetailsVC animated:YES];
}


#pragma mark - Fetched Results Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller_
{
    [self.tableVC.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller_ didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo_
           atIndex:(NSUInteger)sectionIndex_ forChangeType:(NSFetchedResultsChangeType)type_
{
    switch(type_) {
        case NSFetchedResultsChangeInsert:
            [self.tableVC.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex_]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableVC.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex_]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller_ didChangeObject:(id)object_ atIndexPath:(NSIndexPath *)indexPath_
     forChangeType:(NSFetchedResultsChangeType)type_ newIndexPath:(NSIndexPath *)newIndexPath_
{
    switch(type_) {
        case NSFetchedResultsChangeInsert:
            [self.tableVC.tableView insertRowsAtIndexPaths:@[newIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableVC.tableView deleteRowsAtIndexPaths:@[indexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
        {
            [self.tableVC.tableView cellForRowAtIndexPath:indexPath_];
            break;
        }
        case NSFetchedResultsChangeMove:
            [self.tableVC.tableView deleteRowsAtIndexPaths:@[indexPath_] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableVC.tableView insertRowsAtIndexPaths:@[newIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller_
{
    [self.tableVC.tableView endUpdates];
}


#pragma mark - Actions
- (IBAction)showNoteInputAction:(id)sender_
{
    [self showInput];
}


- (IBAction)hideNoteInputAction:(id)sender_
{
    [self hideInput];
}


- (IBAction)addNoteAction:(id)sender_
{
    [self addNote];
}


- (IBAction)cancelNoteAction:(id)sender_
{
    [self cancelNote];
}

@end
