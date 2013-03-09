//
//  NoteDetailsVC.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 31.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LTKPopoverActionSheetDelegate.h"


@class Note;


@interface NoteDetailsVC : UIViewController <UITextViewDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate,
                                             UIActionSheetDelegate, LTKPopoverActionSheetDelegate>

//Initialization
- (id)init;

//Control
- (void)configureWithNote:(Note *)note_ isRemoteChange:(BOOL)isRemoteChange_;

@end
