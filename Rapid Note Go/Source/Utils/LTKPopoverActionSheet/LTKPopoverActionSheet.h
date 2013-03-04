//
//  LTKPopoverActionSheet.h
//  LTKPopoverActionSheet
//
//  Created by Adam on 9/30/12.
//  Copyright (c) 2012 Logical Thought LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LTKPopoverActionSheetDelegate.h"

// Define a custom type for the Blocks API
typedef void (^LTKPopoverActionSheetBlock)(void);

@interface LTKPopoverActionSheet : UIView

// UI Customization Properties
// * These should be set before displaying the action sheet *

// Default sheet width is 272 points
@property (nonatomic) CGFloat sheetWidth UI_APPEARANCE_SELECTOR;

// Default background color is transparent (clearColor)
@property (nonatomic, strong) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

// Background image will override whatever is set as backgroundColor
// A stretchable background image is stretched, a non-stretchable background image is tiled
// Default is nil
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

// The class name to use for drawing the UIPopoverController background (border and arrow)
// The class must be available to create from the name, so make sure you import the header in your code
// Default is nil (UIKit default)
@property (nonatomic, strong) NSString *popoverBackgroundViewClassName UI_APPEARANCE_SELECTOR;

// Padding from the top of the popover to begin drawing the title label
// Default is 7 points
@property (nonatomic) CGFloat titleTopPadding UI_APPEARANCE_SELECTOR;

// Padding below the title label to begin drawing the buttons
// Default is 12 points
@property (nonatomic) CGFloat titleBottomPadding UI_APPEARANCE_SELECTOR;

// Font to use for the top title (if the title string is set)
// Default is 13 point system font
@property (nonatomic, strong) UIFont *titleFont UI_APPEARANCE_SELECTOR;

// How to position the title string
// Default is centered
@property (nonatomic) UITextAlignment titleTextAlignment UI_APPEARANCE_SELECTOR;

// Color of the title label text
// Default is light gray
@property (nonatomic, strong) UIColor *titleColor UI_APPEARANCE_SELECTOR;

// Background color of the title label text
// Default is clear
@property (nonatomic, strong) UIColor *titleBackgroundColor UI_APPEARANCE_SELECTOR;

// Size of the buttons in the sheet; buttons will be horizontally centered and spaced according to other attributes
// Default size is full width (272 points) by 44 points high
@property (nonatomic) CGSize buttonSize UI_APPEARANCE_SELECTOR;

// Padding between buttons
// Default is 8 points
@property (nonatomic) CGFloat buttonPadding UI_APPEARANCE_SELECTOR;

// If there is no image specified then the button will draw a border to provide the look of a standard rounded rect button
// Default border width is 0.5 points
@property (nonatomic) CGFloat buttonBorderWidth UI_APPEARANCE_SELECTOR;
// Default corner radius is 6 points
@property (nonatomic) CGFloat buttonCornerRadius UI_APPEARANCE_SELECTOR;
// Color to use for the border of normal action sheet buttons
// Default is black
@property (nonatomic, strong) UIColor *buttonBorderColor UI_APPEARANCE_SELECTOR;
// Color to use for the border of destructive action sheet buttons
// Default is black
@property (nonatomic, strong) UIColor *destructiveButtonBorderColor UI_APPEARANCE_SELECTOR;

// Font to use on the action sheet buttons
// Default is 19 point bold system font
@property (nonatomic, strong) UIFont *buttonFont UI_APPEARANCE_SELECTOR;

// The button title color is the color of the button label in a particular control state
// Default normal title color is black, highlighted is white
- (UIColor*) buttonTitleColorForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setButtonTitleColor:(UIColor *)color forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// The button background color is used to color the button in a particular control state
// If an image is set for the control state then it will be used instead
// Default normal button color is white, highlighted is blue
- (UIColor*) buttonBackgroundColorForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setButtonBackgroundColor:(UIColor *)color forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// The button background images can be set instead of setting a background color for a custom appearance
// Default uses images in the same style as the UIKit default
- (UIImage*) buttonBackgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// these methods are the same as those above, but for the destructive button instead of the normal sheet buttons

// Default destructive title color for all states is white
- (UIColor*) destructiveButtonTitleColorForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setDestructiveButtonTitleColor:(UIColor *)color forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// Default normal button color is red, highlighted is #990000
- (UIColor*) destructiveButtonBackgroundColorForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setDestructiveButtonBackgroundColor:(UIColor *)color forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// Default uses images in the same style as the UIKit default
- (UIImage*) destructiveButtonBackgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void) setDestructiveButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

// Convenience method for resetting to use the default style
- (void) useDefaultStyle;

// In addition to the standard UIActionSheet API provided below there are a set of convenience
// methods defined to allow for simpler initialization, blocks-based button handling, and
// simple dismissal. This API is not compatible with UIActionSheet, so use at your discretion.
//
// Note that when using blocks for adding action sheet buttons that, if a delegate is set, the
// delegate methods will still get called by LTKPopoverActionSheet.

- (id) initWithTitle:(NSString *)title;
- (id) init;
- (NSInteger) addButtonWithTitle:(NSString *)title block:(LTKPopoverActionSheetBlock)block;
- (NSInteger) addDestructiveButtonWithTitle:(NSString *)title block:(LTKPopoverActionSheetBlock)block;
- (void) dismissPopoverAnimated:(BOOL)animated;

// UIActionSheet compatibility methods (without methods that are not relevant to iPad apps) 

// Creating Action Sheets
- (id) initWithTitle:(NSString *)title delegate:(id<LTKPopoverActionSheetDelegate>)delegate destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

// Setting Properties
@property (nonatomic, weak) id<LTKPopoverActionSheetDelegate> delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

// Configuring Buttons
// Note: cancel button is not used or needed for a popover action sheet, so there is no API for a cancel button
- (NSInteger) addButtonWithTitle:(NSString *)title;
@property (nonatomic, readonly) NSInteger numberOfButtons;
- (NSString*) buttonTitleAtIndex:(NSInteger)buttonIndex;
@property (nonatomic) NSInteger destructiveButtonIndex;
@property (nonatomic, readonly) NSInteger firstOtherButtonIndex;

// Presenting the Action Sheet
/*
 * The following methods from UIActionSheet are not implemented as they are not applicable on iPad:
 *
 * – showFromTabBar:
 * – showFromToolbar:
 * – showInView:
 *
 * According to documentation these methods display the action sheet in the center of the screeen 
 * because they should not be used on iPad. For that reason they are not added to this class. You 
 * should use the methods below instead.
 */
- (void) showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;
- (void) showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;

// Dismissing the Action Sheet
- (void) dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end
