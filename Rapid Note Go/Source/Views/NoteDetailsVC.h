//
//  NoteDetailsVC.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 31.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <UIKit/UIKit.h>


@class Note;


@interface NoteDetailsVC : UIViewController <UITextViewDelegate>

//Initialization
- (id)init;
- (id)initWithNote:(Note *)note_;

//Control
- (void)configureWithNote:(Note *)note_;

@end
