//
//  NotesListVC.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NoteDetailsVC;


@interface NotesListVC : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) NoteDetailsVC *noteDetailsVC;

//Initialization
- (id)init;

//Control
- (void)showNoteForTag:(NSString *)tag_;

@end
