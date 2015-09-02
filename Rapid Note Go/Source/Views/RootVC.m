//
//  RootVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "RootVC.h"

#import "NotesListVC.h"
#import "NoteDetailsVC.h"


@implementation RootVC

#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.delegate = self;
}


#pragma mark - Control
- (void)showNoteForTag:(NSString *)tag_
{
    for(UIViewController *viewController in self.viewControllers) {
        if([viewController isKindOfClass:[NotesListVC class]])
            [((NotesListVC *)viewController) showNoteForTag:tag_];
    }
}


#pragma mark - Split View Controller Delegate
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    return YES;
}

@end
