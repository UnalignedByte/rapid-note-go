//
//  LTKPopoverActionSheet.m
//  LTKPopoverActionSheet
//
//  Created by Adam Schlag on 9/30/12.
//  Copyright (c) 2012 Logical Thought. All rights reserved.
//

#import "LTKPopoverActionSheet.h"
#import <UIKit/UIPopoverBackgroundView.h>
#import <QuartzCore/QuartzCore.h>

NSInteger const LTKIndexForNoButton          = -1;
CGFloat   const LTKActionSheetDefaultWidth   = 272.0f;
CGFloat   const LTKActionSheetDefaultHeight  = 480.0f;
CGFloat   const LTKDefaultButtonHeight       = 44.0f;
CGFloat   const LTKDefaultButtonPadding      = 8.0f;
CGFloat   const LTKTitleLabelTopPadding      = 7.0f;
CGFloat   const LTKTitleLabelFontSize        = 13.0f;
CGFloat   const LTKMaxLinesInTitle           = 10.0f;
CGFloat   const LTKTitleLabelBottomPadding   = 12.0f;
CGFloat   const LTKDefaultButtonBorderWidth  = 0.5f;
CGFloat   const LTKDefaultButtonCornerRadius = 6.0f;
CGFloat   const LTKDefaultButtonFontSize     = 19.0f;

// appearance keys for setting appearance properties
NSString const *kAppearanceAttributeSize                   = @"size";
NSString const *kAppearanceAttributeBorderColor            = @"borderColor";
NSString const *kAppearanceAttributeBorderWidth            = @"borderWidth";
NSString const *kAppearanceAttributeCornerRadius           = @"cornerRadius";
NSString const *kAppearanceAttributeButtonFont             = @"buttonFont";
NSString const *kAppearanceAttributeButtonTitle            = @"buttonTitle";
NSString const *kAppearanceAttributeButtonTitleColors      = @"titleColors";
NSString const *kAppearanceAttributeButtonBackgroundColors = @"backgroundColors";
NSString const *kAppearanceAttributeButtonBackgroundImages = @"backgroundImages";

@interface LTKPopoverActionSheetPopoverDelegate : NSObject <UIPopoverControllerDelegate>

@property (nonatomic, weak) LTKPopoverActionSheet *popoverActionSheet;
@property (nonatomic) NSInteger activeButtonIndex;

@end

@interface LTKPopoverActionSheetContentController : UIViewController

- (void) addActionSheet:(LTKPopoverActionSheet *)actionSheet;

@end

@interface LTKPopoverActionSheet ()

@property (nonatomic, strong) LTKPopoverActionSheetPopoverDelegate *popoverDelegate;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) NSMutableDictionary *buttonTitleColors;
@property (nonatomic, strong) NSMutableDictionary *buttonBackgroundColors;
@property (nonatomic, strong) NSMutableDictionary *buttonBackgroundImages;
@property (nonatomic, strong) NSMutableDictionary *destructiveButtonTitleColors;
@property (nonatomic, strong) NSMutableDictionary *destructiveButtonBackgroundColors;
@property (nonatomic, strong) NSMutableDictionary *destructiveButtonBackgroundImages;
@property (nonatomic, strong) NSMutableArray *buttonTitles;
@property (nonatomic, strong) NSMutableArray *blockArray;
@property (nonatomic, getter = isDismissing) BOOL dismissing;
@property (nonatomic) BOOL subviewsLaidOut;
@property (nonatomic, readonly) Class popoverBackgroundClass;

// flags for style values that affect the popover style
// we have to manually pull these out of the appearance proxy since the popover will display
// before the appearance proxy sets the values in the object
@property (nonatomic) BOOL didSetSheetWidth;
@property (nonatomic) BOOL didSetPopoverBackgroundViewClassName;
@property (nonatomic) BOOL didSetTitleTopPadding;
@property (nonatomic) BOOL didSetTitleBottomPadding;
@property (nonatomic) BOOL didSetTitleFont;
@property (nonatomic) BOOL didSetButtonSize;
@property (nonatomic) BOOL didSetButtonPadding;

- (UIButton *) normalButtonWithTitle:(NSString *)title;
- (UIButton *) destructiveButtonWithTitle:(NSString *)title;
- (UIButton *) actionSheetButtonWithAttributes:(NSDictionary *)attributes;
- (CGSize) sizeForContent;
- (void) buttonPressed:(id)sender;
- (void) buttonHighlighted:(id)sender;
- (void) buttonReleased:(id)sender;
- (void) reconcilePopoverStyleWithAppearanceProxy;
- (void) initializeStyle;

@end

@implementation LTKPopoverActionSheet

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _destructiveButtonIndex = LTKIndexForNoButton;
        
        [self initializeStyle];
    }
    
    return self;
}

- (id) initWithTitle:(NSString *)title delegate:(id<LTKPopoverActionSheetDelegate>)delegate destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [self initWithFrame:CGRectZero];
    
    if (self)
    {
        self.title = title;
        self.delegate = delegate;
        _destructiveButtonIndex = LTKIndexForNoButton;
        
        if (nil != destructiveButtonTitle)
        {
            _destructiveButtonIndex = [self addButtonWithTitle:destructiveButtonTitle];
        }
        
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString *))
        {
            [self addButtonWithTitle:arg];
        }
        va_end(args);
    }
    
    return self;
}

- (void) layoutSubviews
{
    // if there are no changes to the view then don't make any changes
    if (self.subviewsLaidOut)
    {
        return;
    }
    
    // remove any currently added subviews
    for (UIView *subview in self.subviews)
    {
        [subview removeFromSuperview];
    }
    
    // set up the view
    super.backgroundColor = self.backgroundColor;
    CGFloat viewHeight    = (self.buttonSize.height * self.buttonTitles.count) + (self.buttonPadding * (self.buttonTitles.count - 1));
    self.frame            = CGRectMake(0.0f, 0.0f, self.sheetWidth, viewHeight);
    
    // if background image is set then add it
    if (nil != self.backgroundImage)
    {
        super.backgroundColor = [UIColor clearColor];
        
        // if caps aren't set the image isn't resizable, so just tile it
        if (UIEdgeInsetsEqualToEdgeInsets(self.backgroundImage.capInsets, UIEdgeInsetsZero))
        {
            UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
            backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            backgroundView.backgroundColor = [UIColor colorWithPatternImage:self.backgroundImage];
            
            [self addSubview:backgroundView];
        }
        else // add the resizable image
        {
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
            backgroundImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            backgroundImageView.image = self.backgroundImage;
            
            [self addSubview:backgroundImageView];
        }
    }
    
    CGFloat currentY = 0.0f;
    
    // if set, add the title label
    if (nil != self.title)
    {
        currentY = currentY + self.titleTopPadding;
        
        CGSize maximumSize  = CGSizeMake(self.sheetWidth, self.titleFont.pointSize * LTKMaxLinesInTitle);
        CGSize stringSize   = [self.title sizeWithFont:self.titleFont constrainedToSize:maximumSize lineBreakMode:UILineBreakModeWordWrap];
        
        UILabel *titleLabel        = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, currentY, self.sheetWidth, stringSize.height)];
        titleLabel.font            = self.titleFont;
        titleLabel.numberOfLines   = 0; // don't set a max number of lines
        titleLabel.text            = self.title;
        titleLabel.textAlignment   = self.titleTextAlignment;
        titleLabel.textColor       = self.titleColor;
        titleLabel.backgroundColor = self.titleBackgroundColor;
        
        // add in height for the label
        CGRect viewFrame      = self.frame;
        viewFrame.size.height = self.titleTopPadding + titleLabel.frame.size.height + self.titleBottomPadding + viewFrame.size.height;
        self.frame            = viewFrame;
        
        [self addSubview:titleLabel];
        currentY = currentY + titleLabel.frame.size.height + self.titleBottomPadding;
    }
    
    NSUInteger buttonIndex = 0;
    
    for (NSString *buttonTitle in self.buttonTitles)
    {
        UIButton *button;
        
        if (buttonIndex == self.destructiveButtonIndex)
        {
            button = [self destructiveButtonWithTitle:buttonTitle];
        }
        else
        {
            button = [self normalButtonWithTitle:buttonTitle];
        }
        
        CGRect buttonFrame = button.frame;
        CGFloat xPos       = (self.sheetWidth - self.buttonSize.width) / 2.0f;
        buttonFrame.origin = CGPointMake(xPos, currentY);
        button.frame       = buttonFrame;
        button.tag         = buttonIndex;
        buttonIndex        = buttonIndex + 1;
        
        [self addSubview:button];
        currentY = currentY + button.frame.size.height + self.buttonPadding;
    }
    
    self.subviewsLaidOut = YES;
}

#pragma mark - UIActionSheet compatibility API

- (NSInteger) addButtonWithTitle:(NSString *)title
{
    NSInteger index = self.buttonTitles.count;
    [self.buttonTitles addObject:title];
    
    self.subviewsLaidOut = NO;
    
    return index;
}

- (NSString *) buttonTitleAtIndex:(NSInteger)buttonIndex
{
    if (self.buttonTitles.count > buttonIndex)
    {
        return (NSString *)self.buttonTitles[buttonIndex];
    }
    
    return nil;
}

- (void) dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    if ([self isDismissing])
    {
        return;
    }
    
    self.dismissing = YES;
    self.popoverDelegate.activeButtonIndex = buttonIndex;
    
    if (buttonIndex >= 0 && self.blockArray.count > buttonIndex)
    {
        LTKPopoverActionSheetBlock block = (LTKPopoverActionSheetBlock)self.blockArray[buttonIndex];
        
        if (![block isEqual:[NSNull null]])
        {
            block();
        }
    }
    
    // if there is no delegate or if the button index doesn't correspond to a button then just return the popover
    if (nil == self.delegate || buttonIndex == LTKIndexForNoButton)
    {
        [self.popoverController dismissPopoverAnimated:animated];
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(actionSheetLTK:clickedButtonAtIndex:)])
        {
            [self.delegate actionSheetLTK:self clickedButtonAtIndex:buttonIndex];
        }
        
        if ([self.delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)])
        {
            [self.delegate actionSheet:self willDismissWithButtonIndex:buttonIndex];
        }
        
        [self.popoverController dismissPopoverAnimated:animated];
        
        if ([self.delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)])
        {
            [self.delegate actionSheet:self didDismissWithButtonIndex:buttonIndex];
        }
    }
    
    self.dismissing = NO;
}

- (void) showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
    if ([self.popoverController isPopoverVisible])
    {
        return;
    }
    
    [self reconcilePopoverStyleWithAppearanceProxy];
    [self setNeedsDisplay];
    
    // set the correct size for the view and the popover
    CGSize sizeForContent = [self sizeForContent];
    CGRect frame = self.frame;
    frame.size = sizeForContent;
    self.frame = frame;
    [self.popoverController setPopoverContentSize:sizeForContent];
    
    Class backgroundClass = self.popoverBackgroundClass;
    
    if (backgroundClass)
    {
        self.popoverController.popoverBackgroundViewClass = backgroundClass;
    }
    
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(willPresentActionSheet:)])
    {
        [self.delegate willPresentActionSheet:self];
    }
    
    [self.popoverController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    if ([self.popoverController isPopoverVisible])
    {
        return;
    }
    
    [self reconcilePopoverStyleWithAppearanceProxy];
    [self setNeedsDisplay];
    
    // set the correct size for the view and the popover
    CGSize sizeForContent = [self sizeForContent];
    CGRect frame = self.frame;
    frame.size = sizeForContent;
    self.frame = frame;
    [self.popoverController setPopoverContentSize:sizeForContent];
    
    Class backgroundClass = self.popoverBackgroundClass;
    
    if (backgroundClass)
    {
        self.popoverController.popoverBackgroundViewClass = backgroundClass;
    }
    
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(willPresentActionSheet:)])
    {
        [self.delegate willPresentActionSheet:self];
    }
    
    [self.popoverController presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - custom convenience API

- (id) initWithTitle:(NSString *)title
{
    self = [self initWithFrame:CGRectZero];
    
    if (self)
    {
        self.title              = title;
        _destructiveButtonIndex = LTKIndexForNoButton;
    }
    
    return self;
}

- (id) init
{
    return [self initWithTitle:nil];
}

- (NSInteger) addButtonWithTitle:(NSString *)title block:(LTKPopoverActionSheetBlock)block
{
    NSInteger buttonIndex = [self addButtonWithTitle:title];
    
    if (buttonIndex >= 0 && nil != block)
    {
        [self.blockArray addObject:[block copy]];
    }
    else
    {
        [self.blockArray addObject:[NSNull null]];
    }
    
    return buttonIndex;
}

- (NSInteger) addDestructiveButtonWithTitle:(NSString *)title block:(LTKPopoverActionSheetBlock)block
{
    NSInteger buttonIndex = [self addButtonWithTitle:title];
    
    if (buttonIndex >= 0 && nil != block)
    {
        _destructiveButtonIndex = buttonIndex;
        [self.blockArray addObject:[block copy]];
    }
    else
    {
        [self.blockArray addObject:[NSNull null]];
    }
    
    return buttonIndex;
}

- (void) dismissPopoverAnimated:(BOOL)animated
{
    return [self dismissWithClickedButtonIndex:LTKIndexForNoButton animated:animated];
}

#pragma mark - appearance API

- (UIColor*) buttonTitleColorForState:(UIControlState)state
{
    return (UIColor *)self.buttonTitleColors[@(state)];
}

- (void) setButtonTitleColor:(UIColor *)color forState:(UIControlState)state
{
    self.buttonTitleColors[@(state)] = color;
    
    self.subviewsLaidOut = NO;
}

- (UIColor*) buttonBackgroundColorForState:(UIControlState)state
{
    return (UIColor *)self.buttonBackgroundColors[@(state)];
}

- (void) setButtonBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    self.buttonBackgroundColors[@(state)] = color;
    
    self.subviewsLaidOut = NO;
}

- (UIImage*) buttonBackgroundImageForState:(UIControlState)state
{
    return (UIImage *)self.buttonBackgroundImages[@(state)];
}

- (void) setButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    self.buttonBackgroundImages[@(state)] = image;
    
    self.subviewsLaidOut = NO;
}

- (UIColor*) destructiveButtonTitleColorForState:(UIControlState)state
{
    return (UIColor *)self.destructiveButtonTitleColors[@(state)];
}

- (void) setDestructiveButtonTitleColor:(UIColor *)color forState:(UIControlState)state
{
    self.destructiveButtonTitleColors[@(state)] = color;
    
    self.subviewsLaidOut = NO;
}

- (UIColor*) destructiveButtonBackgroundColorForState:(UIControlState)state
{
    return (UIColor *)self.destructiveButtonBackgroundColors[@(state)];
}

- (void) setDestructiveButtonBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    self.destructiveButtonBackgroundColors[@(state)] = color;
    
    self.subviewsLaidOut = NO;
}

- (UIImage*) destructiveButtonBackgroundImageForState:(UIControlState)state
{
    return (UIImage *)self.buttonBackgroundImages[@(state)];
}

- (void) setDestructiveButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    self.destructiveButtonBackgroundImages[@(state)] = image;
    
    self.subviewsLaidOut = NO;
}

- (void) useDefaultStyle
{
    // reset the internal style to the default style
    [self initializeStyle];
    
    // re-write the defaults using setters so they don't get overwritten by the appearance proxy
    self.sheetWidth = _sheetWidth;
    self.backgroundColor = _backgroundColor;
    self.backgroundImage = _backgroundImage;
    self.popoverBackgroundViewClassName = _popoverBackgroundViewClassName;
    self.titleTopPadding = _titleTopPadding;
    self.titleBottomPadding = _titleBottomPadding;
    self.titleFont = _titleFont;
    self.titleTextAlignment = _titleTextAlignment;
    self.titleColor = _titleColor;
    self.titleBackgroundColor = _titleBackgroundColor;
    self.buttonSize = _buttonSize;
    self.buttonPadding = _buttonPadding;
    self.buttonBorderWidth = _buttonBorderWidth;
    self.buttonCornerRadius = _buttonCornerRadius;
    self.buttonBorderColor = _buttonBorderColor;
    self.destructiveButtonBorderColor = _destructiveButtonBorderColor;
    self.buttonFont = _buttonFont;
    
    NSDictionary *buttonTitleColors = [NSDictionary dictionaryWithDictionary:_buttonTitleColors];
    for (NSNumber *buttonState in buttonTitleColors)
    {
        [self setButtonTitleColor:buttonTitleColors[buttonState] forState:[buttonState intValue]];
    }
    
    NSDictionary *buttonBackgroundColors = [NSDictionary dictionaryWithDictionary:_buttonBackgroundColors];
    for (NSNumber *buttonState in buttonBackgroundColors)
    {
        [self setButtonBackgroundColor:buttonBackgroundColors[buttonState] forState:[buttonState intValue]];
    }
    
    NSDictionary *buttonBackgroundImages = [NSDictionary dictionaryWithDictionary:_buttonBackgroundImages];
    for (NSNumber *buttonState in buttonBackgroundImages)
    {
        [self setButtonBackgroundImage:buttonBackgroundImages[buttonState] forState:[buttonState intValue]];
    }
    
    NSDictionary *destructiveButtonTitleColors = [NSDictionary dictionaryWithDictionary:_destructiveButtonTitleColors];
    for (NSNumber *buttonState in destructiveButtonTitleColors)
    {
        [self setDestructiveButtonTitleColor:destructiveButtonTitleColors[buttonState] forState:[buttonState intValue]];
    }
    
    NSDictionary *destructiveButtonBackgroundColors = [NSDictionary dictionaryWithDictionary:_destructiveButtonBackgroundColors];
    for (NSNumber *buttonState in destructiveButtonBackgroundColors)
    {
        [self setDestructiveButtonBackgroundColor:destructiveButtonBackgroundColors[buttonState] forState:[buttonState intValue]];
    }
    
    NSDictionary *destructiveButtonBackgroundImages = [NSDictionary dictionaryWithDictionary:_destructiveButtonBackgroundImages];
    for (NSNumber *buttonState in destructiveButtonBackgroundImages)
    {
        [self setDestructiveButtonBackgroundImage:destructiveButtonBackgroundImages[buttonState] forState:[buttonState intValue]];
    }
}

- (void) setSheetWidth:(CGFloat)sheetWidth
{
    _sheetWidth = sheetWidth;
    
    self.didSetSheetWidth = YES;
    self.subviewsLaidOut  = NO;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    
    self.subviewsLaidOut = NO;
}

- (void) setBackgroundImage:(UIImage *)backgroundImage
{
    _backgroundImage = backgroundImage;
    
    self.subviewsLaidOut = NO;
}

- (void) setPopoverBackgroundViewClassName:(NSString *)popoverBackgroundViewClassName
{
    _popoverBackgroundViewClassName = popoverBackgroundViewClassName;
    
    self.didSetPopoverBackgroundViewClassName = YES;
}

- (void) setTitleTopPadding:(CGFloat)titleTopPadding
{
    _titleTopPadding = titleTopPadding;
    
    self.didSetTitleTopPadding = YES;
    self.subviewsLaidOut = NO;
}

- (void) setTitleBottomPadding:(CGFloat)titleBottomPadding
{
    _titleBottomPadding = titleBottomPadding;
    
    self.didSetTitleBottomPadding = YES;
    self.subviewsLaidOut = NO;
}

- (void) setTitleFont:(UIFont *)titleFont
{
    _titleFont = titleFont;
    
    self.didSetTitleFont = YES;
    self.subviewsLaidOut = NO;
}

- (void) setTitleTextAlignment:(UITextAlignment)titleTextAlignment
{
    _titleTextAlignment = titleTextAlignment;
    
    self.subviewsLaidOut = NO;
}

- (void) setButtonSize:(CGSize)buttonSize
{
    _buttonSize = buttonSize;
    
    self.didSetButtonSize = YES;
    self.subviewsLaidOut = NO;
}

- (void) setButtonPadding:(CGFloat)buttonPadding
{
    _buttonPadding = buttonPadding;
    
    self.didSetButtonPadding = YES;
    self.subviewsLaidOut = NO;
}

- (void) setButtonBorderWidth:(CGFloat)buttonBorderWidth
{
    _buttonBorderWidth = buttonBorderWidth;
    
    self.subviewsLaidOut = NO;
}

- (void) setButtonCornerRadius:(CGFloat)buttonCornerRadius
{
    _buttonCornerRadius = buttonCornerRadius;
    
    self.subviewsLaidOut = NO;
}

- (void) setButtonFont:(UIFont *)buttonFont
{
    _buttonFont = buttonFont;
    
    self.subviewsLaidOut = NO;
}

- (void) setButtonBorderColor:(UIColor *)buttonBorderColor
{
    _buttonBorderColor = buttonBorderColor;
    
    self.subviewsLaidOut = NO;
}

- (void) setDestructiveButtonBorderColor:(UIColor *)destructiveButtonBorderColor
{
    _destructiveButtonBorderColor = destructiveButtonBorderColor;
    
    self.subviewsLaidOut = NO;
}

#pragma mark - custom getters/setters

- (void) setTitle:(NSString *)title
{
    if (![_title isEqualToString:title])
    {
        _title = [title copy];
        
        self.subviewsLaidOut = NO;
    }
}

- (void) setDestructiveButtonIndex:(NSInteger)destructiveButtonIndex
{
    // if the input index is less than 0, just ignore and return
    // NOTE: internal methods looking to set the value should directly set
    // the _destructiveButtonIndex variable
    if (destructiveButtonIndex < 0)
    {
        return;
    }
    // if there is no destructive button then just return
    else if (LTKIndexForNoButton == _destructiveButtonIndex)
    {
        return;
    }
    // if there is only one button then just return
    else if (1 == self.buttonTitles.count)
    {
        return;
    }
    
    NSString *destructiveButtonTitle = (NSString *)self.buttonTitles[self.destructiveButtonIndex];
    [self.buttonTitles removeObject:destructiveButtonTitle];
    [self.buttonTitles insertObject:destructiveButtonTitle atIndex:destructiveButtonIndex];
    _destructiveButtonIndex = destructiveButtonIndex;
    
    self.subviewsLaidOut = NO;
}

- (NSInteger) firstOtherButtonIndex
{
    // The first button index will only ever be LTKIndexForNoButton, 0, or 1:
    //  • it will be -1 if there is no regular button
    //  • it will be 0 if there is at least one button and the destructive button index is not 0
    //  • it will be 1 if there is more than one button and the destructive button index is 0
    NSInteger buttonIndex = LTKIndexForNoButton; // -1
    
    if (0 != self.destructiveButtonIndex && self.buttonTitles.count > 0)
    {
        buttonIndex = 0;
    }
    else if (0 == self.destructiveButtonIndex && self.buttonTitles.count > 1)
    {
        buttonIndex = 1;
    }
    
    return buttonIndex;
}

- (NSInteger) numberOfButtons
{
    return self.buttonTitles.count;
}

- (BOOL) isVisible
{
    return [self.popoverController isPopoverVisible];
}

- (UIPopoverController *) popoverController
{
    if (nil == _popoverController)
    {
        LTKPopoverActionSheetContentController *contentController = [[LTKPopoverActionSheetContentController alloc] init];
        [contentController addActionSheet:self];
        
        _popoverController = [[UIPopoverController alloc] initWithContentViewController:contentController];
        _popoverController.delegate = self.popoverDelegate;
        
        Class backgroundClass = self.popoverBackgroundClass;
        
        if (backgroundClass)
        {
            _popoverController.popoverBackgroundViewClass = backgroundClass;
        }
    }
    
    return _popoverController;
}

- (LTKPopoverActionSheetPopoverDelegate *) popoverDelegate
{
    if (nil == _popoverDelegate)
    {
        _popoverDelegate = [[LTKPopoverActionSheetPopoverDelegate alloc] init];
        _popoverDelegate.popoverActionSheet = self;
        _popoverDelegate.activeButtonIndex  = LTKIndexForNoButton;
    }
    
    return _popoverDelegate;
}

- (NSMutableArray *) buttonTitles
{
    if (nil == _buttonTitles)
    {
        _buttonTitles = [@[] mutableCopy];
    }
    
    return _buttonTitles;
}

- (NSMutableArray *) blockArray
{
    if (nil == _blockArray)
    {
        _blockArray = [@[] mutableCopy];
    }
    
    return _blockArray;
}

- (NSMutableDictionary *) buttonTitleColors
{
    if (nil == _buttonTitleColors)
    {
        _buttonTitleColors = [@{} mutableCopy];
    }
    
    return _buttonTitleColors;
}

- (NSMutableDictionary *) buttonBackgroundColors
{
    if (nil == _buttonBackgroundColors)
    {
        _buttonBackgroundColors = [@{} mutableCopy];
    }
    
    return _buttonBackgroundColors;
}

- (NSMutableDictionary *) buttonBackgroundImages
{
    if (nil == _buttonBackgroundImages)
    {
        _buttonBackgroundImages = [@{} mutableCopy];
    }
    
    return _buttonBackgroundImages;
}

- (Class) popoverBackgroundClass
{
    Class popoverBackgroundClass = nil;
    
    if (nil != self.popoverBackgroundViewClassName)
    {
        popoverBackgroundClass = NSClassFromString(self.popoverBackgroundViewClassName);
    }
    
    return popoverBackgroundClass;
}

#pragma mark - private methods

- (void) buttonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        NSInteger buttonIndex = button.tag;
        
        if (nil == button.currentBackgroundImage)
        {
            UIColor *backgroundColor;
            
            if (buttonIndex == self.destructiveButtonIndex)
            {
                backgroundColor = self.destructiveButtonBackgroundColors[@(UIControlStateNormal)];
            }
            else
            {
                backgroundColor = self.buttonBackgroundColors[@(UIControlStateNormal)];
            }
            
            button.backgroundColor = backgroundColor;
        }
        
        [self dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}

- (void) buttonHighlighted:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        NSInteger buttonIndex = button.tag;
        
        if (nil == button.currentBackgroundImage)
        {
            UIColor *backgroundColor;
            
            if (buttonIndex == self.destructiveButtonIndex)
            {
                backgroundColor = self.destructiveButtonBackgroundColors[@(UIControlStateHighlighted)];
            }
            else
            {
                backgroundColor = self.buttonBackgroundColors[@(UIControlStateHighlighted)];
            }
            
            button.backgroundColor = backgroundColor;
        }
    }
}

- (void) buttonReleased:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        NSInteger buttonIndex = button.tag;
        
        if (nil == button.currentBackgroundImage)
        {
            UIColor *backgroundColor;
            
            if (buttonIndex == self.destructiveButtonIndex)
            {
                backgroundColor = self.destructiveButtonBackgroundColors[@(UIControlStateNormal)];
            }
            else
            {
                backgroundColor = self.buttonBackgroundColors[@(UIControlStateNormal)];
            }
            
            button.backgroundColor = backgroundColor;
        }
    }
}

- (CGSize) sizeForContent
{
    CGFloat viewHeight = (self.buttonSize.height * self.buttonTitles.count) + (self.buttonPadding * (self.buttonTitles.count - 1));
    
    if (nil != self.title)
    {
        CGSize maximumSize = CGSizeMake(self.sheetWidth, self.titleFont.pointSize * LTKMaxLinesInTitle);
        CGSize stringSize  = [self.title sizeWithFont:self.titleFont constrainedToSize:maximumSize lineBreakMode:UILineBreakModeWordWrap];
        
        // add in height for the label
        viewHeight = self.titleTopPadding + stringSize.height + self.titleBottomPadding + viewHeight;
    }
    
    return CGSizeMake(self.sheetWidth, viewHeight);
}

- (UIButton *) normalButtonWithTitle:(NSString *)title
{
    NSDictionary *buttonAttributes = @{
        kAppearanceAttributeSize: [NSValue valueWithCGSize:self.buttonSize],
        kAppearanceAttributeBorderColor: self.buttonBorderColor,
        kAppearanceAttributeBorderWidth: @(self.buttonBorderWidth),
        kAppearanceAttributeCornerRadius: @(self.buttonCornerRadius),
        kAppearanceAttributeButtonFont: self.buttonFont,
        kAppearanceAttributeButtonTitle: title,
        kAppearanceAttributeButtonTitleColors: self.buttonTitleColors,
        kAppearanceAttributeButtonBackgroundColors: self.buttonBackgroundColors,
        kAppearanceAttributeButtonBackgroundImages: self.buttonBackgroundImages
    };
    
    return [self actionSheetButtonWithAttributes:buttonAttributes];
}

- (UIButton *) destructiveButtonWithTitle:(NSString *)title
{
    NSDictionary *buttonAttributes = @{
        kAppearanceAttributeSize: [NSValue valueWithCGSize:self.buttonSize],
        kAppearanceAttributeBorderColor: self.destructiveButtonBorderColor,
        kAppearanceAttributeBorderWidth: @(self.buttonBorderWidth),
        kAppearanceAttributeCornerRadius: @(self.buttonCornerRadius),
        kAppearanceAttributeButtonFont: self.buttonFont,
        kAppearanceAttributeButtonTitle: title,
        kAppearanceAttributeButtonTitleColors: self.destructiveButtonTitleColors,
        kAppearanceAttributeButtonBackgroundColors: self.destructiveButtonBackgroundColors,
        kAppearanceAttributeButtonBackgroundImages: self.destructiveButtonBackgroundImages
    };
    
    return [self actionSheetButtonWithAttributes:buttonAttributes];
}

- (UIButton *) actionSheetButtonWithAttributes:(NSDictionary *)attributes
{
    CGSize  buttonSize = [(NSValue *)attributes[kAppearanceAttributeSize] CGSizeValue];
    UIColor *borderColor = (UIColor *)attributes[kAppearanceAttributeBorderColor];
    CGFloat borderWidth = [(NSNumber *)attributes[kAppearanceAttributeBorderWidth] floatValue];
    CGFloat cornerRadius = [(NSNumber *)attributes[kAppearanceAttributeCornerRadius] floatValue];
    UIFont *buttonFont = (UIFont *)attributes[kAppearanceAttributeButtonFont];
    NSString *buttonTitle = (NSString *)attributes[kAppearanceAttributeButtonTitle];
    NSDictionary *titleColors = (NSDictionary *)attributes[kAppearanceAttributeButtonTitleColors];
    NSDictionary *backgroundColors = (NSDictionary *)attributes[kAppearanceAttributeButtonBackgroundColors];
    NSDictionary *backgroundImages = (NSDictionary *)attributes[kAppearanceAttributeButtonBackgroundImages];
    
    UIButton *actionSheetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionSheetButton.frame = CGRectMake(0.0f, 0.0f, buttonSize.width, buttonSize.height);
    actionSheetButton.titleLabel.font = buttonFont;
    [actionSheetButton setTitle:buttonTitle forState:UIControlStateNormal];
    [actionSheetButton setTitleColor:(UIColor *)titleColors[@(UIControlStateNormal)] forState:UIControlStateNormal];
    [actionSheetButton setTitleColor:(UIColor *)titleColors[@(UIControlStateHighlighted)] forState:UIControlStateHighlighted];
    [actionSheetButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [actionSheetButton addTarget:self action:@selector(buttonHighlighted:) forControlEvents:UIControlEventTouchDown];
    [actionSheetButton addTarget:self action:@selector(buttonReleased:) forControlEvents:UIControlEventTouchDragExit];
    
    id normalBackgroundImage = backgroundImages[@(UIControlStateNormal)];
    id highlightedBackgroundImage = backgroundImages[@(UIControlStateHighlighted)];
    
    if ([normalBackgroundImage isKindOfClass:[UIImage class]] && [highlightedBackgroundImage isKindOfClass:[UIImage class]])
    {
        [actionSheetButton setBackgroundImage:(UIImage *)normalBackgroundImage forState:UIControlStateNormal];
        [actionSheetButton setBackgroundImage:(UIImage *)highlightedBackgroundImage forState:UIControlStateHighlighted];
    }
    else
    {
        actionSheetButton.backgroundColor = (UIColor *)backgroundColors[@(UIControlStateNormal)];
        actionSheetButton.layer.borderColor = [borderColor CGColor];
        actionSheetButton.layer.borderWidth = borderWidth;
        actionSheetButton.layer.cornerRadius = cornerRadius;
    }
    
    return actionSheetButton;
}

- (void) reconcilePopoverStyleWithAppearanceProxy
{
    id appearanceProxy = [[self class] appearance];
    
    if (!self.didSetSheetWidth)
    {
        CGFloat sheetWidth = [appearanceProxy sheetWidth];
        
        if (0.0f != sheetWidth)
        {
            _sheetWidth = sheetWidth;
        }
    }
    
    if (!self.didSetPopoverBackgroundViewClassName)
    {
        NSString *popoverBackgroundClassName = [appearanceProxy popoverBackgroundViewClassName];
        
        if (nil != popoverBackgroundClassName)
        {
            _popoverBackgroundViewClassName = popoverBackgroundClassName;
        }
    }
    
    if (!self.didSetTitleTopPadding)
    {
        CGFloat titleTopPadding = [appearanceProxy titleTopPadding];
        
        if (0.0f != titleTopPadding)
        {
            _titleTopPadding = titleTopPadding;
        }
    }
    
    if (!self.didSetTitleBottomPadding)
    {
        CGFloat titleBottomPadding = [appearanceProxy titleBottomPadding];
        
        if (0.0f != titleBottomPadding)
        {
            _titleBottomPadding = titleBottomPadding;
        }
    }
    
    if (!self.didSetTitleFont)
    {
        UIFont *titleFont = [appearanceProxy titleFont];
        
        if (nil != titleFont)
        {
            _titleFont = titleFont;
        }
    }
    
    if (!self.didSetButtonSize)
    {
        CGSize buttonSize = [appearanceProxy buttonSize];
        
        if (!CGSizeEqualToSize(buttonSize, CGSizeZero))
        {
            _buttonSize = buttonSize;
        }
    }
    
    if (!self.didSetButtonPadding)
    {
        CGFloat buttonPadding = [appearanceProxy buttonPadding];
        
        if (0.0f != buttonPadding)
        {
            _buttonPadding = buttonPadding;
        }
    }
}

- (void) initializeStyle
{
    _sheetWidth = LTKActionSheetDefaultWidth;
    _backgroundColor = [UIColor clearColor];
    _backgroundImage = nil;
    _popoverBackgroundViewClassName = nil;
    _titleTopPadding = LTKTitleLabelTopPadding;
    _titleBottomPadding = LTKTitleLabelBottomPadding;
    _titleFont = [UIFont systemFontOfSize:LTKTitleLabelFontSize];
    _titleTextAlignment = UITextAlignmentCenter;
    _titleColor = [UIColor lightGrayColor];
    _titleBackgroundColor = [UIColor clearColor];
    _buttonSize = CGSizeMake(LTKActionSheetDefaultWidth, LTKDefaultButtonHeight);
    _buttonPadding = LTKDefaultButtonPadding;
    _buttonBorderWidth = LTKDefaultButtonBorderWidth;
    _buttonCornerRadius = LTKDefaultButtonCornerRadius;
    _buttonBorderColor = [UIColor blackColor];
    _destructiveButtonBorderColor = [UIColor blackColor];
    _buttonFont = [UIFont boldSystemFontOfSize:LTKDefaultButtonFontSize];
    _buttonTitleColors = [@{} mutableCopy];
    _buttonTitleColors[@(UIControlStateNormal)] = [UIColor blackColor];
    _buttonTitleColors[@(UIControlStateHighlighted)] = [UIColor whiteColor];
    _destructiveButtonTitleColors = [@{} mutableCopy];
    _destructiveButtonTitleColors[@(UIControlStateNormal)] = [UIColor whiteColor];
    _destructiveButtonTitleColors[@(UIControlStateHighlighted)] = [UIColor whiteColor];
    _buttonBackgroundColors = [@{} mutableCopy];
    _buttonBackgroundImages = [@{} mutableCopy];
    _destructiveButtonBackgroundColors = [@{} mutableCopy];
    _destructiveButtonBackgroundImages = [@{} mutableCopy];
    
    // Try to load the default images. If they don't load then use colors to approximate the image appearance
    UIImage *buttonImage = [UIImage imageNamed:@"PopoverDefaultButton"];
    UIImage *pressedButtonImage = [UIImage imageNamed:@"PopoverDefaultButtonPressed"];
    UIImage *destructiveButtonImage = [UIImage imageNamed:@"PopoverDestroyButton"];
    UIImage *pressedDestructiveButtonImage = [UIImage imageNamed:@"PopoverDestroyButtonPressed"];
    
    if (buttonImage && pressedButtonImage && destructiveButtonImage && pressedDestructiveButtonImage)
    {
        UIEdgeInsets capInsets = UIEdgeInsetsMake(21.0f, 5.0f, 21.0f, 5.0f);
        _buttonBackgroundColors[@(UIControlStateNormal)] = [NSNull null];
        _buttonBackgroundColors[@(UIControlStateHighlighted)] = [NSNull null];
        _buttonBackgroundImages[@(UIControlStateNormal)] = [buttonImage resizableImageWithCapInsets:capInsets];
        _buttonBackgroundImages[@(UIControlStateHighlighted)] = [pressedButtonImage resizableImageWithCapInsets:capInsets];
        _destructiveButtonBackgroundColors[@(UIControlStateNormal)] = [NSNull null];
        _destructiveButtonBackgroundColors[@(UIControlStateHighlighted)] = [NSNull null];
        _destructiveButtonBackgroundImages[@(UIControlStateNormal)] = [destructiveButtonImage resizableImageWithCapInsets:capInsets];
        _destructiveButtonBackgroundImages[@(UIControlStateHighlighted)] = [pressedDestructiveButtonImage resizableImageWithCapInsets:capInsets];
    }
    else
    {
        _buttonBackgroundColors[@(UIControlStateNormal)] = [UIColor whiteColor];
        _buttonBackgroundColors[@(UIControlStateHighlighted)] = [UIColor blueColor];
        _buttonBackgroundImages[@(UIControlStateNormal)] = [NSNull null];
        _buttonBackgroundImages[@(UIControlStateHighlighted)] = [NSNull null];
        _destructiveButtonBackgroundColors[@(UIControlStateNormal)] = [UIColor redColor];
        _destructiveButtonBackgroundColors[@(UIControlStateHighlighted)] = [UIColor colorWithRed:0.6f green:0.0f blue:0.0f alpha:1.0f];
        _destructiveButtonBackgroundImages[@(UIControlStateNormal)] = [NSNull null];
        _destructiveButtonBackgroundImages[@(UIControlStateHighlighted)] = [NSNull null];
    }
}

@end

@implementation LTKPopoverActionSheetPopoverDelegate

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (nil != self.popoverActionSheet && nil != self.popoverActionSheet.delegate &&
        [self.popoverActionSheet.delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)])
    {
        [self.popoverActionSheet.delegate actionSheet:self.popoverActionSheet didDismissWithButtonIndex:self.activeButtonIndex];
        
        self.popoverActionSheet = nil;
        self.activeButtonIndex  = LTKIndexForNoButton;
    }
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

@end

@implementation LTKPopoverActionSheetContentController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // This will remove the inner shadow from the popover
    if ([NSStringFromClass([self.view.superview class]) isEqualToString:@"UILayoutContainerView"])
    {
        self.view.superview.layer.cornerRadius = 0;
        
        for (UIView *subview in self.view.superview.subviews)
        {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UIImageView"])
            {
                [subview removeFromSuperview];
            }
        }
    }
}

- (void) addActionSheet:(LTKPopoverActionSheet *)actionSheet
{
    // remove any currently added subviews
    for (UIView *subview in self.view.subviews)
    {
        [subview removeFromSuperview];
    }
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size   = actionSheet.frame.size;
    self.view.frame  = viewFrame;
    
    CGRect actionSheetFrame = actionSheet.frame;
    actionSheetFrame.origin = CGPointZero;
    actionSheet.frame       = actionSheetFrame;
    
    [self.view addSubview:actionSheet];
}

@end
