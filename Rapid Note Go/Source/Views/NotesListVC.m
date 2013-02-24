//
//  NotesListVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NotesListVC.h"

#import "DataManager.h"
#import "NotificationsManager.h"

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
    self.tableVC = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    CGRect tableRect = self.view.frame;
    tableRect.origin.y = 0;
    self.tableVC.tableView.frame = tableRect;
    [self.view addSubview:self.tableVC.tableView];
    self.tableVC.tableView.dataSource = self;
    self.tableVC.tableView.delegate = self;
    UIView *tableBackgroundView = [[UIView alloc] initWithFrame:self.tableVC.tableView.frame];
    tableBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background Pattern Dark"]];
    self.tableVC.tableView.backgroundView = tableBackgroundView;
    self.view.backgroundColor = [UIColor blueColor];
}


- (void)setupNavigationButtonsForAdding
{
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Edit")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(editNotesListAction:)];
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(showNoteInputAction:)];
    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItem = addNoteButton;
}


- (void)setupNavigationButtonsForEditing
{
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Add")
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(addNoteAction:)];
    UIBarButtonItem *cancelNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(cancelNoteAction:)];
    self.navigationItem.rightBarButtonItem = addNoteButton;
    self.navigationItem.leftBarButtonItem = cancelNoteButton;
}


- (void)setupNavigationButtonsForListEditing
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Done")
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(finishEditingNotesListAction:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItem = nil;
}


- (void)setupNotesResultsController
{
    NSFetchRequest *notesFetchRequest = [[NSFetchRequest alloc] init];
    //entity
    NSEntityDescription *notesEntityDescription = [NSEntityDescription entityForName:@"Note"
                                                              inManagedObjectContext:[DataManager sharedInstance].notesContext];
    [notesFetchRequest setEntity:notesEntityDescription];
    //sorting
    NSSortDescriptor *notesSort = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO];
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
    //CGRect noteInputRect = self.noteInputView.frame;
    //noteInputRect.origin.y = -self.noteInputBackground.frame.size.height;
    //self.noteInputView.frame = noteInputRect;
    self.noteInputView.frame = self.view.frame;
    //hide the view for the moment
    self.noteInputView.alpha = 0.0;
}


#pragma mark - Internal Control
- (void)showInput
{
    //set original position
    CGRect originalNoteInputRect = self.noteInputView.frame;
    originalNoteInputRect.origin.y = -self.noteInputBackground.frame.size.height;
    self.noteInputView.frame = originalNoteInputRect;
    
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


- (void)editNotesList
{
    [self setupNavigationButtonsForListEditing];
    
    [self.tableVC.tableView setEditing:YES animated:YES];
}


- (void)finishEditingNotesList
{
    [self setupNavigationButtonsForAdding];
    
    [self.tableVC.tableView setEditing:NO animated:YES];
}


#pragma mark - Control
- (void)showNoteForTag:(NSString *)tag_
{
    NSArray *notes = [[DataManager sharedInstance] allNotes];
    for(int i=0; i<notes.count; i++) {
        Note *note = notes[i];
        if([note.tag isEqualToString:tag_]) {
            [self tableView:self.tableVC.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            return;
        }
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


- (CGFloat)tableView:(UITableView *)tableView_ heightForRowAtIndexPath:(NSIndexPath *)indexPath_
{
    return [NoteCell height];
}


- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath_
{
    [tableView_ deselectRowAtIndexPath:indexPath_ animated:YES];
    
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.noteDetailsVC configureWithNote:note];
    } else {
        if([self.navigationController.topViewController class] == [NoteDetailsVC class]) {
            [self.noteDetailsVC configureWithNote:note];
        } else {
            NoteDetailsVC *noteDetailsVC = [[NoteDetailsVC alloc] initWithNote:note];
            [self.navigationController pushViewController:noteDetailsVC animated:YES];
        }
    }
}


- (void)tableView:(UITableView *)tableView_ commitEditingStyle:(UITableViewCellEditingStyle)style_
        forRowAtIndexPath:(NSIndexPath *)indexPath_
{
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
    
    switch(style_) {
        case UITableViewCellEditingStyleDelete:
        {
            if(indexPath_.row == [self.tableVC.tableView indexPathForSelectedRow].row) {
                [self.noteDetailsVC configureWithNote:nil];
            }
            [[NotificationsManager sharedInstance] removeNotificationForNote:note];
            [[DataManager sharedInstance] deleteNote:note];
            break;
        }
        case UITableViewCellEditingStyleInsert:
            break;
        case UITableViewCellEditingStyleNone:
            break;
    }
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


- (void)controller:(NSFetchedResultsController *)controller_ didChangeObject:(id)object_ atIndexPath:(NSIndexPath *)oldIndexPath_
     forChangeType:(NSFetchedResultsChangeType)type_ newIndexPath:(NSIndexPath *)newIndexPath_
{
    switch(type_) {
        case NSFetchedResultsChangeInsert:
            [self.tableVC.tableView insertRowsAtIndexPaths:@[newIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableVC.tableView deleteRowsAtIndexPaths:@[oldIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
        {
            [self.tableVC.tableView reloadRowsAtIndexPaths:@[oldIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove:
            [self.tableVC.tableView deleteRowsAtIndexPaths:@[oldIndexPath_] withRowAnimation:UITableViewRowAnimationFade];
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


- (IBAction)editNotesListAction:(id)sender_
{
    [self editNotesList];
}


- (IBAction)finishEditingNotesListAction:(id)sender_
{
    [self finishEditingNotesList];
}

@end
