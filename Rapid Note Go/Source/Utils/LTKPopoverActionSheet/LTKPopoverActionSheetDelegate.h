//
//  LTKPopoverActionSheetDelegate.h
//  LTKPopoverActionSheet
//
//  Created by Adam Schlag on 9/30/12.
//  Copyright (c) 2012 Logical Thought. All rights reserved.
//

@class LTKPopoverActionSheet;

@protocol LTKPopoverActionSheetDelegate <NSObject>

@optional

- (void) actionSheetLTK:(LTKPopoverActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void) willPresentActionSheet:(LTKPopoverActionSheet *)actionSheet;
- (void) actionSheet:(LTKPopoverActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void) actionSheet:(LTKPopoverActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
