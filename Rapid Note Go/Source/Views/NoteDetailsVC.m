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

@end


@implementation NoteDetailsVC

#pragma mark - Initialization
- (id)initWithNote:(Note *)note_
{
    if((self = [super initWithNibName:@"NoteDetailsView" bundle:nil]) == nil)
        return nil;
    
    self.note = note_;
    
    return self;
}

@end
