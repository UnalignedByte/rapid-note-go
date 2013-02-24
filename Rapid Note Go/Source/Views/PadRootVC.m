//
//  PadRootVC.m
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "PadRootVC.h"

#import "NotesListVC.h"
#import "NoteDetailsVC.h"


@interface PadRootVC ()

@property (nonatomic, strong) NotesListVC *notesListVC;
@property (nonatomic, strong) NoteDetailsVC *noteDetailsVC;

@end


@implementation PadRootVC

#pragma mark - Initialization
- (id)init
{
    if((self = [super init]) == nil)
        return nil;
    
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    
    self.notesListVC = [[NotesListVC alloc] init];
    self.noteDetailsVC = [[NoteDetailsVC alloc] init];
    self.notesListVC.noteDetailsVC = self.noteDetailsVC;
    
    self.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:self.notesListVC],
                             [[UINavigationController alloc] initWithRootViewController:self.noteDetailsVC]];
    
    self.delegate = self;

    return self;
}


#pragma mark - Control
- (void)showNoteForTag:(NSString *)tag_
{
    [self.notesListVC showNoteForTag:tag_];
}


#pragma mark - Split View Controller Delegate
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

@end
