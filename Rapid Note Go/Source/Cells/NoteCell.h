//
//  NoteCell.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 29.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Note;


static NSString *kNoteCellIdentifier = @"NoteCellIdentifier";
#pragma unused(kNoteCellIdentifier)


@interface NoteCell : UITableViewCell

//Initialization
- (id)init;
- (void)configureWithNote:(Note *)note_;

@end
