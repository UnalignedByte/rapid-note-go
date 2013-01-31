//
//  NoteDetailsVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 31.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NoteDetailsVC.h"

#import "Note.h"


@interface NoteDetailsVC ()

@property (nonatomic, strong) Note *note;
@property (nonatomic, weak) IBOutlet UITextView *noteText;

@property (nonatomic, weak) IBOutlet UIImageView *creationImage;
@property (nonatomic, weak) IBOutlet UILabel *creationDateLabel;

@property (nonatomic, weak) IBOutlet UIImageView *modificationImage;
@property (nonatomic, weak) IBOutlet UILabel *modificationDateLabel;

@property (nonatomic, weak) IBOutlet UIImageView *notificationImage;
@property (nonatomic, weak) IBOutlet UILabel *notificationDateLabel;

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
    [self setupNote];
}


- (void)setupNote
{
    if(self.note == nil) {
        self.creationImage.hidden = YES;
        self.creationDateLabel.hidden = YES;
        
        self.modificationImage.hidden = YES;
        self.modificationDateLabel.hidden = YES;
        
        self.notificationImage.hidden = YES;
        self.notificationDateLabel.hidden = YES;
        
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
    if(self.note.modificationDate != nil) {
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
       [self.note.notificationDate laterDate:[NSDate date]] == self.note.notificationDate)
    {
    } else {
    }
}


#pragma mark - Control
- (void)configureWithNote:(Note *)note_
{
    self.note = note_;
    [self setupNote];
}

@end
