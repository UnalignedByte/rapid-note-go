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

@property (nonatomic, weak) IBOutlet UIView *setNotificationDateView;
@property (nonatomic, weak) IBOutlet UIDatePicker *setNotificationDatePicker;
@property (nonatomic, weak) IBOutlet UIView *setNotificationDatePickerOverlayView;
@property (nonatomic, strong) UIViewController *setNotificationDatePickerVC;
@property (nonatomic, strong) UIPopoverController *setNotificationDatePickerPopover;

@end


@implementation NoteDetailsVC

#pragma mark - Initialization
- (id)initWithNote:(Note *)note_
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if((self = [super initWithNibName:@"NoteDetailsViewPad" bundle:nil]) == nil)
            return nil;
    } else {
        if((self = [super initWithNibName:@"NoteDetailsViewPhone" bundle:nil]) == nil)
            return nil;
    }
    
    self.note = note_;
    
    return self;
}


- (id)init
{
    return [self initWithNote:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBackground];
    [self configureWithNote:self.note];
    [self setupNotificationSetting];
    [self setupNavigationButtonsForReading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    
    //notificaiton
    if(self.note.notificationDate != nil &&
       [self.note.notificationDate compare:[NSDate date]] == NSOrderedDescending)
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

    self.navigationItem.rightBarButtonItem = deleteButton;
    
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
    UIBarButtonItem *setNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Set Notification")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(setNotificationDateAction:)];
    self.navigationItem.leftBarButtonItem = cancelSettingNotificationButton;
    self.navigationItem.rightBarButtonItem = setNotificationButton;
}

#pragma mark - Internal Control
- (void)cancelNoteEditing
{
    self.noteText.text = self.note.message;
    
    [self setupNavigationButtonsForReading];
    
    [self.noteText resignFirstResponder];
}


- (void)saveNoteEditing
{
    self.note.message = self.noteText.text;
    self.note.modificationDate = [NSDate date];
    
    [self setupNote];
    [self setupNavigationButtonsForReading];
    
    [self.noteText resignFirstResponder];
}


- (void)deleteNote
{
    self.deleteNoteSheet = [[UIActionSheet alloc] initWithTitle:Localize(@"Are you suere that want to delete this note?")
                                                       delegate:self
                                              cancelButtonTitle:Localize(@"Cancel")
                                         destructiveButtonTitle:Localize(@"Delete")
                                              otherButtonTitles:nil];
    self.deleteNoteSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [self.deleteNoteSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}


- (void)showSetNotificationDate
{
    self.setNotificationDatePicker.minimumDate = [NSDate date];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self showSetNotificationDateForPhone];
    } else {
        [self showSetNotificationDateForPad];
    }
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
        UIBarButtonItem *setNotificationButton = [[UIBarButtonItem alloc] initWithTitle:Localize(@"Set Notification")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(setNotificationDateAction:)];
        pickerVC.navigationItem.leftBarButtonItem = cancelSettingNotificationButton;
        pickerVC.navigationItem.rightBarButtonItem = setNotificationButton;
        
        self.setNotificationDatePickerVC = [[UINavigationController alloc] initWithRootViewController:pickerVC];
    }
    
    if(self.setNotificationDatePickerPopover == nil) {
        self.setNotificationDatePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.setNotificationDatePickerVC];
        self.setNotificationDatePickerPopover.delegate = self;
        CGSize popoverSize = CGSizeMake(self.setNotificationDatePicker.frame.size.width, self.setNotificationDatePicker.frame.size.height);
        popoverSize.height += 35.0;
        self.setNotificationDatePickerPopover.popoverContentSize = popoverSize;
    }
    
    [self.setNotificationDatePickerPopover presentPopoverFromRect:self.notificationButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}


- (void)hideSetNotificationDate
{
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
    NSComparisonResult cmp = [[self.setNotificationDatePicker.minimumDate dateByRemovingSeconds] compare:[self.setNotificationDatePicker.date dateByRemovingSeconds]];
    if(cmp == NSOrderedDescending || cmp == NSOrderedSame) {
        [self.setNotificationDatePicker setDate:self.setNotificationDatePicker.minimumDate animated:YES];
        return;
    }
    
    self.note.notificationDate = [self.setNotificationDatePicker.date dateByRemovingSeconds];
    
    [self setupNote];
    
    [[NotificationsManager sharedInstance] addNotificationForNote:self.note];
    [self hideSetNotificationDate];
}


- (void)disableNotification
{
    self.disableNotificaitonSheet = [[UIActionSheet alloc] initWithTitle:Localize(@"Are you sure you want to disable notification for this note?")
                                                                delegate:self
                                                       cancelButtonTitle:Localize(@"Cancel")
                                                  destructiveButtonTitle:Localize(@"Disable Notification")
                                                       otherButtonTitles:nil];
    self.disableNotificaitonSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [self.disableNotificaitonSheet showFromRect:self.notificationButton.frame
                                         inView:self.view
                                       animated:YES];
}


#pragma mark - Control
- (void)configureWithNote:(Note *)note_
{
    [DataManager sharedInstance].shouldIgnoreNotesContextChanges = YES;
    
    self.note = note_;
    [self setupNote];
    
    if(note_ == nil) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        [self setupNavigationButtonsForReading];
    }
    
    [[DataManager sharedInstance].notesContext save:nil];
    [DataManager sharedInstance].shouldIgnoreNotesContextChanges = NO;
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
            self.note.notificationDate = nil;
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
    NSComparisonResult cmp = [[self.setNotificationDatePicker.minimumDate dateByRemovingSeconds] compare:[self.setNotificationDatePicker.date dateByRemovingSeconds]];
    
    if(cmp == NSOrderedDescending || cmp == NSOrderedSame) {
        [self.setNotificationDatePicker setDate:self.setNotificationDatePicker.minimumDate animated:YES];
        return;
    }
}

@end
