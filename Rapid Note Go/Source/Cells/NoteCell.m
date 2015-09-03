//
//  NoteCell.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NoteCell.h"

#import "Note.h"


#pragma mark  - Private properties
@interface NoteCell ()

@property (nonatomic, weak) IBOutlet UIImageView *notificationImage;
@property (nonatomic, weak) IBOutlet UILabel *notificationLabel;
@property (nonatomic, weak) IBOutlet UILabel *noteLabel;

@end


@implementation NoteCell

#pragma mark - Initialization
- (void)configureWithNote:(Note *)note_
{
    self.noteLabel.text = note_.message;
    
    if(note_.notificationDate != nil &&
       [note_.notificationDate isInFuture]) {
        self.notificationImage.hidden = NO;
        self.notificationLabel.text = [note_.notificationDate formatAsNiceString];
        self.notificationLabel.hidden = NO;
    } else {
        self.notificationImage.hidden = YES;
        self.notificationLabel.text = @"";
        self.notificationLabel.hidden = YES;
    }
}

@end
