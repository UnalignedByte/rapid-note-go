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

#import "KSCustomPopoverBackgroundView.h"

#import "NoteDetailsVC.h"
#import "SettingsVC.h"


#define INPUT_ANIMATION_DURATION 0.3
#define SETTINGS_BUTTON_HEIGHT 20.0


#pragma mark - Private properties
@interface NotesListVC ()

@property (nonatomic, strong) UITableViewController *tableVC;
@property (nonatomic, strong) NSFetchedResultsController *notesResultsController;
@property (nonatomic, strong) IBOutlet UIView *noteInputView;
@property (nonatomic, strong) IBOutlet UITextView *noteInputText;
@property (nonatomic, strong) IBOutlet UIView *noteInputBackground;

@property (nonatomic) BOOL isEditingSingleRow;

@property (nonatomic, strong) NSString *currentNoteTag;

//note input for iPad
@property (nonatomic, weak) IBOutlet UIDatePicker *setNotificationDatePicker;
@property (nonatomic, weak) IBOutlet UIView *setNotificationDatePickerOverlayView;
@property (nonatomic, strong) UIViewController *noteInputPadVC;
@property (nonatomic, strong) UIPopoverController *noteInputPadPopover;

@end


@implementation NotesListVC

#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;

    return self;
}


- (void)viewDidLoad
{
    [self setupTable];
    [self setupSettingsButton];
    [self setupNavigationButtonsForAdding];
    [self setupNotesResultsController];
    [self setupNoteInput];
}


- (void)setupTable
{
    self.tableVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    CGRect tableRect = self.view.frame;
    tableRect.origin.y = 0;
    tableRect.size.height -= SETTINGS_BUTTON_HEIGHT * 2.0;
    self.tableVC.tableView.frame = tableRect;
    [self.view addSubview:self.tableVC.tableView];
    self.tableVC.tableView.dataSource = self;
    self.tableVC.tableView.delegate = self;

    self.tableVC.tableView.backgroundView = nil;
    self.tableVC.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background Pattern Dark"]];

    self.automaticallyAdjustsScrollViewInsets = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}


- (void)setupSettingsButton
{
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, SETTINGS_BUTTON_HEIGHT)];
    
    CGRect settingsButtonRect = settingsButton.frame;
    settingsButtonRect.origin.x = (self.view.frame.size.width - settingsButtonRect.size.width)/2.0;
    settingsButtonRect.origin.y = self.view.frame.size.height - settingsButton.frame.size.height*1.5;
    settingsButton.frame = settingsButtonRect;

    [settingsButton setBackgroundImage:[UIImage imageNamed:@"Setings and Info"] forState:UIControlStateNormal];
    settingsButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [settingsButton addTarget:self
                       action:@selector(settingsButtonAction:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:settingsButton];
}


- (void)setupNavigationButtonsForAdding
{
    [self.navigationController setNavigationBarHidden:NO];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Edit")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(editNotesListAction:)];
    UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(showNoteInputAction:)];
    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItem = addNoteButton;
    self.title = Localize(@"Notes");
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
    self.title = Localize(@"New Note");
}


- (void)setupNavigationButtonsForListEditing
{
    
    UIBarButtonItem *doneButton;
    if(self.isEditingSingleRow) {
        doneButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                      style:UIBarButtonItemStyleDone
                                                     target:self
                                                     action:@selector(finishEditingNotesListAction:)];
    } else {
        doneButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Done")
                                                      style:UIBarButtonItemStyleDone
                                                     target:self
                                                     action:@selector(finishEditingNotesListAction:)];
    }
    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItem = nil;
    self.title = Localize(@"Notes");
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
    [self.view addSubview:self.noteInputView];
    [self.view bringSubviewToFront:self.noteInputView];
    //move input view up
    self.noteInputView.frame = self.view.frame;
    //hide the view for the moment
    self.noteInputView.alpha = 0.0;
}


- (void)viewWillAppear:(BOOL)animated_
{
    [super viewWillAppear:animated_];
    
    self.currentNoteTag = nil;
}


#pragma mark - Internal Control
- (void)showInput
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self showInputForPhone];
    else
        [self showInputForPad];
}


- (void)showInputForPhone
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


- (void)showInputForPad
{
    if(self.noteInputPadPopover != nil && self.noteInputPadPopover.isPopoverVisible) {
        [self hideInputForPad];
    }
    
    if(self.noteInputPadVC == nil) {
        UIViewController *noteInpuVC = [[UIViewController alloc] init];
        noteInpuVC.view = self.noteInputText;
        self.noteInputText.backgroundColor = [UIColor whiteColor];
        
        UIBarButtonItem *addNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Add")
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(addNoteAction:)];
        addNoteButton.tintColor = [UIColor blackColor];
        UIBarButtonItem *cancelNoteButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelNoteAction:)];
        cancelNoteButton.tintColor = [UIColor blackColor];
        noteInpuVC.navigationItem.rightBarButtonItem = addNoteButton;
        noteInpuVC.navigationItem.leftBarButtonItem = cancelNoteButton;
        noteInpuVC.title = Localize(@"New Note");
        
        self.noteInputPadVC = [[UINavigationController alloc] initWithRootViewController:noteInpuVC];
    }
    
    if(self.noteInputPadPopover == nil) {
        self.noteInputPadPopover = [[UIPopoverController alloc] initWithContentViewController:self.noteInputPadVC];
        self.noteInputPadPopover.delegate = self;
        self.noteInputPadPopover.popoverBackgroundViewClass = [KSCustomPopoverBackgroundView class];
        CGSize popoverSize = CGSizeMake(400.0, 200.0);
        self.noteInputPadPopover.popoverContentSize = popoverSize;
    }
    
    [self.noteInputPadPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    [self.noteInputText becomeFirstResponder];
}


- (void)hideInput
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self hideInputeForPhone];
    } else {
        [self hideInputForPad];
    }
    
    self.noteInputText.text = @"";
}


- (void)hideInputeForPhone
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
}


- (void)hideInputForPad
{
    [self.noteInputPadPopover dismissPopoverAnimated:YES];
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
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.noteDetailsVC configureWithNote:nil isRemoteChange:NO];
        
        if(self.noteInputPadPopover != nil && self.noteInputPadPopover.isPopoverVisible) {
            [self hideInputForPad];
            return;
        }
    }
    
    [self setupNavigationButtonsForListEditing];
    
    [self.tableVC.tableView setEditing:YES animated:YES];
}


- (void)finishEditingNotesList
{
    self.isEditingSingleRow = NO;
    
    [self setupNavigationButtonsForAdding];
    
    [self.tableVC.tableView setEditing:NO animated:YES];
}


- (void)showSettings
{
    SettingsVC *settingsVC = [[SettingsVC alloc] init];
    CGRect padModalSize = settingsVC.view.frame;
    padModalSize.size.width = 0.75 * padModalSize.size.height;

    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    settingsNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self.navigationController presentViewController:settingsNavigationController
                                            animated:YES
                                          completion:^{
                                                  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                                      settingsNavigationController.view.superview.bounds = padModalSize;
                                                  }
                                          }];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        settingsNavigationController.view.superview.bounds = padModalSize;
    }
}


#pragma mark - Control
- (void)showNoteForTag:(NSString *)tag_
{
    NSArray *notes = [[DataManager sharedInstance] allNotes];
    for(int i=0; i<notes.count; i++) {
        Note *note = notes[i];
        [[DataManager sharedInstance] nilNotificaitonDateWithoutCloudExportForNote:note];
        if([note.tag isEqualToString:tag_]) {
            [self tableView:self.tableVC.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            return;
        }
    }
}


#pragma mark - Internal Control
- (Note *)noteForTag:(NSString *)tag_
{
    if(tag_ == nil)
        return nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:[DataManager sharedInstance].notesContext];
    fetchRequest.entity = entityDescription;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"tag == '%@'", self.currentNoteTag]];
    NSArray *fetchResult = [[DataManager sharedInstance].notesContext executeFetchRequest:fetchRequest error:nil];
    if(fetchResult.count > 0) {
       return (Note *)fetchResult[0];
    }
    
    return nil;
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
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView_ deselectRowAtIndexPath:indexPath_ animated:YES];
    }
    
    Note *note = [self.notesResultsController objectAtIndexPath:indexPath_];
    self.currentNoteTag = note.tag;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.noteDetailsVC configureWithNote:note isRemoteChange:NO];
    } else {
        if(self.navigationController.topViewController == self.noteDetailsVC) {
            [self.noteDetailsVC configureWithNote:note isRemoteChange:NO];
        } else {
            if(self.noteDetailsVC == nil)
                self.noteDetailsVC = [[NoteDetailsVC alloc] init];

            [self.noteDetailsVC configureWithNote:note isRemoteChange:NO];
            [self.navigationController pushViewController:self.noteDetailsVC animated:YES];
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
                [self.noteDetailsVC configureWithNote:nil isRemoteChange:NO];
            }
            [[NotificationsManager sharedInstance] removeNotificationForNote:note];
            [[DataManager sharedInstance] deleteNote:note];
            
            if(self.isEditingSingleRow) {
                [self finishEditingNotesList];
                self.isEditingSingleRow = NO;
            }
            break;
        }
        case UITableViewCellEditingStyleInsert:
            break;
        case UITableViewCellEditingStyleNone:
            break;
    }
}


- (void)tableView:(UITableView *)tableView_ willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath_
{
    self.isEditingSingleRow = YES;
    
    [self setupNavigationButtonsForListEditing];
    
    [self.noteDetailsVC configureWithNote:nil isRemoteChange:NO];
}


- (void)tableView:(UITableView *)tableView_ didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath_
{
    [self finishEditingNotesList];
}


#pragma mark - Fetched Results Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller_
{
    if([DataManager sharedInstance].shouldIgnoreUpdates)
        return;
    
    [self.tableVC.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller_ didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo_
           atIndex:(NSUInteger)sectionIndex_ forChangeType:(NSFetchedResultsChangeType)type_
{
    if([DataManager sharedInstance].shouldIgnoreUpdates)
        return;
    
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
    if([DataManager sharedInstance].shouldIgnoreUpdates)
        return;
    
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
    if([DataManager sharedInstance].shouldIgnoreUpdates)
        return;

    [self.tableVC.tableView endUpdates];

    if(self.currentNoteTag != nil) {
        Note *currentNote = [self noteForTag:self.currentNoteTag];
        [self.noteDetailsVC configureWithNote:currentNote isRemoteChange:YES];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            if(currentNote != nil) {
                [self.tableVC.tableView selectRowAtIndexPath:[self.notesResultsController indexPathForObject:currentNote]
                                                    animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }
    }
}


#pragma  mark - Popover Delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController_
{
    if(popoverController_ == self.noteInputPadPopover) {
        [self hideInput];
    }
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


- (IBAction)settingsButtonAction:(id)sender_
{
    [self showSettings];
}

@end
