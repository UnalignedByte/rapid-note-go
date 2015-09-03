//
//  NoteDetailsVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 31.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NoteDetailsVC.h"

#import "DataManager.h"
#import "NotificationsManager.h"

#import "Note.h"

#import "KSCustomPopoverBackgroundView.h"
#import "LTKPopoverActionSheet.h"


#define NOTIFICATION_ANIMATION_DURATION 0.3


@interface NoteDetailsVC ()

@property (nonatomic, strong) Note *note;

@property (nonatomic, weak) IBOutlet UIView *noteTextBackgroundView;
@property (nonatomic, weak) IBOutlet UITextView *noteText;

@property (nonatomic, weak) IBOutlet UIImageView *creationImage;
@property (nonatomic, weak) IBOutlet UILabel *creationDateLabel;

@property (nonatomic, weak) IBOutlet UIImageView *modificationImage;
@property (nonatomic, weak) IBOutlet UILabel *modificationDateLabel;

@property (nonatomic, weak) IBOutlet UIImageView *notificationImage;
@property (nonatomic, weak) IBOutlet UIButton *notificationButton;

@property (nonatomic, strong) UIActionSheet *deleteNoteSheet;
@property (nonatomic, strong) UIActionSheet *disableNotificaitonSheet;
@property (nonatomic, strong) LTKPopoverActionSheet *deleteNoteSheetPad;
@property (nonatomic, strong) LTKPopoverActionSheet *disableNotificaitonSheetPad;


@property (nonatomic, weak) IBOutlet UIView *setNotificationDateView;
@property (nonatomic, weak) IBOutlet UIDatePicker *setNotificationDatePicker;
@property (nonatomic, weak) IBOutlet UIView *setNotificationDatePickerOverlayView;
@property (nonatomic, strong) UIViewController *setNotificationDatePickerVC;
@property (nonatomic, strong) UIPopoverController *setNotificationDatePickerPopover;
@property (nonatomic, strong) NSTimer *setNotificationTimer;

//current data
@property (nonatomic, strong) NSString *currentNoteTag;
@property (nonatomic, strong) NSString *currentNoteMessage;
@property (nonatomic, strong) NSDate *currentNoteCreationDate;
@property (nonatomic, strong) NSDate *currentNoteModificationDate;
@property (nonatomic, strong) NSDate *currentNoteNotificationDate;

@end


@implementation NoteDetailsVC

#pragma mark - Initialization
- (void)viewDidLoad
{
    /*if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if((self = [super initWithNibName:@"NoteDetailsViewPad" bundle:nil]) == nil)
            return nil;
    } else {
        if((self = [super initWithNibName:@"NoteDetailsViewPhone" bundle:nil]) == nil)
            return nil;
    }*/
    
    [self setupBackground];
    [self setupNote];
    [self setupNotificationSetting];
    [self setupNavigationButtonsForReading];
    [self configureWithNote:nil isRemoteChange:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    //self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    //self.navigationItem.leftItemsSupplementBackButton = YES;
    
    //return self;
}


- (void)setupBackground
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background Pattern Dark"]];
    
    [backgroundView addSubview:self.view];
    self.view.backgroundColor = [UIColor clearColor];
    self.view = backgroundView;
}


- (void)setupNote
{
    [self.noteText resignFirstResponder];
    
    if(self.note == nil) {
        self.creationImage.hidden = YES;
        self.creationDateLabel.hidden = YES;
        
        self.modificationImage.hidden = YES;
        self.modificationDateLabel.hidden = YES;
        
        self.notificationImage.hidden = YES;
        self.notificationButton.hidden = YES;
        
        self.noteText.hidden = YES;
        
        return;
    }

    //creation
    self.creationImage.hidden = NO;
    self.creationDateLabel.hidden = NO;
    self.noteText.hidden = NO;
    self.noteText.text = self.note.message;
    self.creationDateLabel.text = [self.note.creationDate formatAsShortNiceString];
    
    //modification
    if([self.note.modificationDate compare:self.note.creationDate] == NSOrderedDescending) {
        self.modificationImage.hidden = NO;
        self.modificationDateLabel.hidden = NO;
        self.modificationDateLabel.text = [self.note.modificationDate formatAsShortNiceString];
    } else {
        self.modificationImage.hidden = YES;
        self.modificationDateLabel.hidden = YES;
        self.modificationDateLabel.text = @"";
    }
    
    if(self.note.notificationDate != nil &&
       ![self.note.notificationDate isInFuture]) {
        [[DataManager sharedInstance] nilNotificaitonDateWithoutCloudExportForNote:self.note];
    }
    
    //notificaiton
    if(self.note.notificationDate != nil &&
       [self.note.notificationDate isInFuture])
    {
        self.notificationImage.hidden = NO;
        self.notificationButton.hidden = NO;
        [self.notificationButton setTitle:[self.note.notificationDate formatAsShortNiceString] forState:UIControlStateNormal];
    } else {
        self.notificationImage.hidden = NO;
        self.notificationButton.hidden = NO;
        [self.notificationButton setTitle:Localize(@"Set Notification") forState:UIControlStateNormal];
    }
}


- (void)setupNotificationSetting
{
    [[NSBundle mainBundle] loadNibNamed:@"SetNotificationView" owner:self options:nil];
    [self.view addSubview:self.setNotificationDateView];
    
    CGRect setNotificationDateRect = self.setNotificationDateView.frame;
    setNotificationDateRect.origin.y = -self.setNotificationDatePicker.frame.size.height;
    self.setNotificationDateView.frame = setNotificationDateRect;
    
    self.setNotificationDateView.userInteractionEnabled = NO;
    self.setNotificationDateView.alpha = 0.0;
    
    self.setNotificationDatePicker.minimumDate = [NSDate date];
}


- (void)setupNavigationButtonsForReading
{
    self.navigationItem.leftBarButtonItem = nil;
    
    if(self.note == nil)
        return;
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                  target:self
                                                  action:@selector(deleteButtonAction:)];

    self.navigationItem.rightBarButtonItems = @[deleteButton];
    //self.title = @"";
    
    self.notificationButton.userInteractionEnabled = YES;
}


- (void)setupNavigationButtonsForEditing
{
    UIBarButtonItem *cancelEditingButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:self
                                                                           action:@selector(cancelNoteEditingAction:)];
    UIBarButtonItem *saveEditingButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Save")
                                                                          style:UIBarButtonSystemItemAction
                                                                         target:self
                                                                         action:@selector(saveNoteEditingAction:)];
    self.navigationItem.leftBarButtonItem = cancelEditingButton;
    self.navigationItem.rightBarButtonItem = saveEditingButton;
    self.title = @"";
    
    self.notificationButton.userInteractionEnabled = NO;
}


- (void)setupNavigationButtonsForSettingNotificationDate
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return;
    
    UIBarButtonItem *cancelSettingNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                                        style:UIBarButtonItemStylePlain
                                                                                       target:self
                                                                                       action:@selector(cancelSettingNotificationDateAction:)];
    UIBarButtonItem *setNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Set")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(setNotificationDateAction:)];
    self.navigationItem.leftBarButtonItem = cancelSettingNotificationButton;
    self.navigationItem.rightBarButtonItem = setNotificationButton;
    self.title = Localize(@"Set Notification");
}

#pragma mark - Internal Control
- (void)cancelNoteEditing
{
    [self setupNavigationButtonsForReading];
    
    [self.noteText resignFirstResponder];
    
    self.noteText.text = self.note.message;
}


- (void)saveNoteEditing
{
    if(![self.noteText.text isEqualToString:self.note.message]) {
        self.note.message = self.noteText.text;
        self.currentNoteMessage = [self.note.message copy];
        self.note.modificationDate = [NSDate date];
        self.currentNoteModificationDate = [self.note.modificationDate copy];
        self.note.isUploaded = @NO;
    }
    
    [self setupNote];
    [self setupNavigationButtonsForReading];
    
    [self.noteText resignFirstResponder];
}


- (void)deleteNote
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.deleteNoteSheet = [[UIActionSheet alloc] initWithTitle:Localize(@"Are you suere that want to delete this note?")
                                                           delegate:self
                                                  cancelButtonTitle:Localize(@"Cancel")
                                             destructiveButtonTitle:Localize(@"Delete Note")
                                                  otherButtonTitles:nil];
        
        self.deleteNoteSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        
        [self.deleteNoteSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        self.deleteNoteSheetPad = [[LTKPopoverActionSheet alloc] initWithTitle:Localize(@"Are you suere that want to delete this note?")
                                                                      delegate:self
                                                        destructiveButtonTitle:Localize(@"Delete Note")
                                                             otherButtonTitles:Localize(@"Cancel"), nil];
        
        self.deleteNoteSheetPad.popoverBackgroundViewClassName = NSStringFromClass([KSCustomPopoverBackgroundView class]);
        
        [self.deleteNoteSheetPad showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }
}


- (void)showSetNotificationDate
{
    self.setNotificationDatePicker.minimumDate = [[[NSDate date] dateBySettingSecondsAtOne] dateByAddingOneMinute];
    self.setNotificationDatePicker.date = self.setNotificationDatePicker.minimumDate;
    
    NSDate *timerFireDate = [[[NSDate date] dateByRemovingSeconds] dateByAddingOneMinute];
    self.setNotificationTimer = [[NSTimer alloc] initWithFireDate:timerFireDate
                                                         interval:60.0
                                                           target:self
                                                         selector:@selector(setNotificationTimerFired:)
                                                         userInfo:nil
                                                          repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.setNotificationTimer forMode:NSDefaultRunLoopMode];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self showSetNotificationDateForPhone];
    } else {
        [self showSetNotificationDateForPad];
    }
}


- (void)setNotificationTimerFired:(NSTimer *)timer_
{
    self.setNotificationDatePicker.minimumDate = [self.setNotificationDatePicker.minimumDate dateByAddingOneMinute];
}


- (void)showSetNotificationDateForPhone
{
    [self setupNavigationButtonsForSettingNotificationDate];
    
    CGRect setNotificationDateRect = self.setNotificationDateView.frame;
    setNotificationDateRect.origin.y = 0.0;
    self.setNotificationDateView.userInteractionEnabled = YES;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:NOTIFICATION_ANIMATION_DURATION];
    self.setNotificationDateView.alpha = 1.0;
    self.setNotificationDateView.frame = setNotificationDateRect;
    [UIView commitAnimations];
}


- (void)showSetNotificationDateForPad
{
    if(self.setNotificationDatePickerVC == nil) {
        UIViewController *pickerVC = [[UIViewController alloc] init];
        
        [pickerVC.view addSubview:self.setNotificationDatePicker];
        [pickerVC.view addSubview:self.setNotificationDatePickerOverlayView];
        
        UIBarButtonItem *cancelSettingNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Cancel")
                                                                                            style:UIBarButtonItemStylePlain
                                                                                           target:self
                                                                                           action:@selector(cancelSettingNotificationDateAction:)];
        cancelSettingNotificationButton.tintColor = [UIColor blackColor];
        UIBarButtonItem *setNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Set")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(setNotificationDateAction:)];
        setNotificationButton.tintColor = [UIColor blackColor];
        pickerVC.navigationItem.leftBarButtonItem = cancelSettingNotificationButton;
        pickerVC.navigationItem.rightBarButtonItem = setNotificationButton;
        pickerVC.title = Localize(@"Set Notification");
        
        self.setNotificationDatePickerVC = [[UINavigationController alloc] initWithRootViewController:pickerVC];
    }
    
    if(self.setNotificationDatePickerPopover == nil) {
        self.setNotificationDatePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.setNotificationDatePickerVC];
        self.setNotificationDatePickerPopover.popoverBackgroundViewClass = [KSCustomPopoverBackgroundView class];
        self.setNotificationDatePickerPopover.delegate = self;
        CGSize popoverSize = CGSizeMake(self.setNotificationDatePicker.frame.size.width, self.setNotificationDatePicker.frame.size.height);
        popoverSize.height += 35.0;
        self.setNotificationDatePickerPopover.popoverContentSize = popoverSize;
    }
    
    [self.setNotificationDatePickerPopover presentPopoverFromRect:self.notificationButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}


- (void)hideSetNotificationDate
{
    [self.setNotificationTimer invalidate];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.setNotificationDatePickerPopover dismissPopoverAnimated:YES];
    } else {
        [self setupNavigationButtonsForReading];
        
        CGRect setNotificationDateRect = self.setNotificationDateView.frame;
        setNotificationDateRect.origin.y = -self.setNotificationDatePicker.frame.size.height;
        self.setNotificationDateView.userInteractionEnabled = NO;
        
        [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:NOTIFICATION_ANIMATION_DURATION];
            self.setNotificationDateView.alpha = 0.0;
            self.setNotificationDateView.frame = setNotificationDateRect;
        [UIView commitAnimations];
    }
}


- (void)setNotification
{
    NSComparisonResult cmp = [[[NSDate date] dateByRemovingSeconds] compare:[self.setNotificationDatePicker.date dateByRemovingSeconds]];
    if(cmp == NSOrderedDescending || cmp == NSOrderedSame) {
        return;
    }
    
    self.currentNoteNotificationDate = [self.setNotificationDatePicker.date dateByRemovingSeconds];
    self.note.notificationDate = [self.currentNoteNotificationDate copy];
    self.note.isUploaded = @NO;
    
    [self setupNote];
    
    [[NotificationsManager sharedInstance] addNotificationForNote:self.note];
    [self hideSetNotificationDate];
}


- (void)disableNotification
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.disableNotificaitonSheet = [[UIActionSheet alloc] initWithTitle:Localize(@"Are you sure you want to disable notification for this note?")
                                                                    delegate:self
                                                           cancelButtonTitle:Localize(@"Cancel")
                                                      destructiveButtonTitle:Localize(@"Disable Notification")
                                                           otherButtonTitles:nil];
        
        self.disableNotificaitonSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        [self.disableNotificaitonSheet showFromRect:self.notificationButton.frame
                                             inView:self.view
                                           animated:YES];
    } else {
        self.disableNotificaitonSheetPad = [[LTKPopoverActionSheet alloc] initWithTitle:Localize(@"Are you sure you want to disable notification for this note?")
                                                                               delegate:self
                                                                 destructiveButtonTitle:Localize(@"Disable Notification")
                                                                      otherButtonTitles:Localize(@"Cancel"), nil];
        
        self.disableNotificaitonSheetPad.popoverBackgroundViewClassName = NSStringFromClass([KSCustomPopoverBackgroundView class]);
        
        [self.disableNotificaitonSheetPad showFromRect:self.notificationButton.frame
                                                inView:self.view.superview
                                              animated:YES];
    }
}


- (BOOL)isNoteDifferent:(Note *)note_
{
    if(note_ != self.note)
        return YES;
    
    if((note_.message == nil && self.currentNoteMessage != nil) ||
       (note_.message != nil && self.currentNoteMessage == nil) ||
       (![note_.message isEqualToString:self.currentNoteMessage]))
        return YES;
    
    if((note_.creationDate == nil && self.currentNoteCreationDate != nil) ||
       (note_.creationDate != nil && self.currentNoteCreationDate == nil) ||
       ([note_.creationDate compare:self.currentNoteCreationDate] != NSOrderedSame))
        return YES;
    
    if((note_.modificationDate == nil && self.currentNoteModificationDate != nil) ||
       (note_.modificationDate != nil && self.currentNoteModificationDate == nil) ||
       ([note_.modificationDate compare:self.currentNoteModificationDate] != NSOrderedSame))
        return YES;
    
    if((note_.notificationDate == nil && self.currentNoteNotificationDate != nil) ||
       (note_.notificationDate != nil && self.currentNoteNotificationDate == nil) ||
       ([note_.notificationDate compare:self.currentNoteNotificationDate] != NSOrderedSame))
        return YES;

    return NO;
}


#pragma mark - Control
- (void)configureWithNote:(Note *)note_ isRemoteChange:(BOOL)isRemoteChange_;
{
    self.note = note_;
    return;
    BOOL isModified = [self isNoteDifferent:note_];
    
    BOOL isDeletedRemotely = (self.note != nil) && (note_ == nil) && isRemoteChange_;
    BOOL isModifiedRemotely = note_ != nil && [self.currentNoteTag isEqualToString:note_.tag] &&
                      note_.isUploaded.boolValue && isModified && isRemoteChange_;
    
    if(isModified) {
        self.note = note_;
        self.currentNoteTag = [note_.tag copy];
        self.currentNoteMessage = [note_.message copy];
        self.currentNoteCreationDate = [note_.creationDate copy];
        self.currentNoteModificationDate = [note_.modificationDate copy];
        self.currentNoteNotificationDate = [note_.notificationDate copy];
    
        [self setupNote];
        [self setupNavigationButtonsForReading];
    }
    
    if(note_ == nil) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    //Show message if has been modified remotely
    NSString *message = nil;
    if(isDeletedRemotely)
        message = Localize(@"Note has been deleted remotely");
    else if(isModifiedRemotely)
        message = Localize(@"Note has been modified remotely");
        
    
    if(message != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:Localize(@"OK")
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    if(isDeletedRemotely)
        [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Text View Delegate
- (void)textViewDidBeginEditing:(UITextView *)textView_
{
    [self setupNavigationButtonsForEditing];
}


#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet_ clickedButtonAtIndex:(NSInteger)buttonIndex_
{
    if(actionSheet_ == self.deleteNoteSheet && buttonIndex_ == 0) {
        [[NotificationsManager sharedInstance] removeNotificationForNote:self.note];
        [[DataManager sharedInstance] deleteNote:self.note];
        [self.navigationController popViewControllerAnimated:YES];
    } else if(actionSheet_ == self.disableNotificaitonSheet && buttonIndex_ == 0) {
        if(buttonIndex_ == 0) {
            self.currentNoteNotificationDate = nil;
            self.note.notificationDate = nil;
            self.note.isUploaded = @NO;
            [[NotificationsManager sharedInstance] removeNotificationForNote:self.note];
            [self setupNote];
        }
    }
}

- (void)actionSheetLTK:(LTKPopoverActionSheet *)actionSheet_ clickedButtonAtIndex:(NSInteger)buttonIndex_
{
    if(actionSheet_ == self.deleteNoteSheetPad && buttonIndex_ == 0) {
        [[NotificationsManager sharedInstance] removeNotificationForNote:self.note];
        [[DataManager sharedInstance] deleteNote:self.note];
        [self.navigationController popViewControllerAnimated:YES];
    } else if(actionSheet_ == self.disableNotificaitonSheetPad && buttonIndex_ == 0) {
        if(buttonIndex_ == 0) {
            self.currentNoteNotificationDate = nil;
            self.note.notificationDate = nil;
            self.note.isUploaded = @NO;
            [[NotificationsManager sharedInstance] removeNotificationForNote:self.note];
            [self setupNote];
        }
    }
}


#pragma  mark - Popover Delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController_
{
    if(popoverController_ == self.setNotificationDatePickerPopover) {
        [self hideSetNotificationDate];
    }
}


#pragma mark - Handle Rotation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation_
{
    if(self.setNotificationDatePickerPopover.isPopoverVisible) {
        [self.setNotificationDatePickerPopover dismissPopoverAnimated:NO];
        [self.setNotificationDatePickerPopover presentPopoverFromRect:self.notificationButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}


#pragma mark - Handle Keyboard
- (void)keyboardWillShow:(NSNotification *)notification_
{
    [self resizeTextBackgroundUpwards:YES keyboardInfo:notification_.userInfo];
}


- (void)keyboardWillHide:(NSNotification *)notification_
{
    [self resizeTextBackgroundUpwards:NO keyboardInfo:notification_.userInfo];
}


- (void)resizeTextBackgroundUpwards:(BOOL)resizeUpwards_ keyboardInfo:(NSDictionary *)keyboardInfo_
{
    if(!self.noteText.isFirstResponder)
        return;
    
    static CGFloat resizeHeight;
    
    if(resizeUpwards_) {
        CGRect keyboardFrame = [keyboardInfo_[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        if(keyboardFrame.size.height < keyboardFrame.size.width)
            resizeHeight = -keyboardFrame.size.height;
        else
            resizeHeight = -keyboardFrame.size.width;
    } else {
        resizeHeight = -resizeHeight;
    }
    
    CGRect backgroundRect = self.noteTextBackgroundView.frame;
    backgroundRect.size.height += resizeHeight;
    
    UIViewAnimationCurve keyboardAnimationCurve;
    NSTimeInterval keyboardAnimationDuration;
    
    [keyboardInfo_[UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardAnimationCurve];
    [keyboardInfo_[UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardAnimationDuration];
    
    [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:keyboardAnimationCurve];
        [UIView setAnimationDuration:keyboardAnimationDuration];
        self.noteTextBackgroundView.frame = backgroundRect;
    [UIView commitAnimations];
}


#pragma mark - Acitons
- (IBAction)notificationButtonAction:(id)sender_
{
    if(self.note.notificationDate != nil)
        [self disableNotification];
    else
        [self showSetNotificationDate];
}


- (IBAction)cancelNoteEditingAction:(id)sender_
{
    [self cancelNoteEditing];
}


- (IBAction)saveNoteEditingAction:(id)sender_
{
    [self saveNoteEditing];
}

- (IBAction)deleteButtonAction:(id)sender_
{
    [self deleteNote];
}


- (IBAction)setNotificationDateAction:(id)sender_
{
    [self setNotification];
}


- (IBAction)cancelSettingNotificationDateAction:(id)sender_
{
    [self hideSetNotificationDate];
}


- (IBAction)setNotificationPickerValueChanged:(id)sender_
{
    NSComparisonResult cmp = [self.setNotificationDatePicker.minimumDate compare:self.setNotificationDatePicker.date];
    
    if(cmp == NSOrderedDescending || cmp == NSOrderedSame) {
        self.setNotificationDatePicker.date = [self.setNotificationDatePicker.minimumDate copy];
        return;
    }
}

@end
