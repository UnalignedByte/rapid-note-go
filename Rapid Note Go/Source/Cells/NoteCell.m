//
//  NoteCell.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "NoteCell.h"

#import "Note.h"


@implementation NoteCell

#pragma mark - Initialization
- (id)init
{    
    NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:nil options:nil];
    NoteCell *cell = nibObjects[0];
    
    return cell;
}


- (void)configureWithNote:(Note *)note_
{
    
}

@end
