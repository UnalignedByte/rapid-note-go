//
//  NoteViewerBackgroundView.m
//  Rapid Note
//
//  Created by Rafał Grodziński on 11/18/12.
//  Copyright (c) 2012 UnalignedByte. All rights reserved.
//

#import "NoteViewerBackgroundView.h"


@interface NoteViewerBackgroundView ()

@property (nonatomic, strong) UIImage *phoneTopImage;
@property (nonatomic, strong) UIImage *phoneMiddleImage;
@property (nonatomic, strong) UIImage *phoneBottomImage;

@property (nonatomic, strong) UIImage *padTopVerticalImage;
@property (nonatomic, strong) UIImage *padMiddleVerticalImage;
@property (nonatomic, strong) UIImage *padBottomVerticalImage;

@property (nonatomic, strong) UIImage *padTopHorizontalImage;
@property (nonatomic, strong) UIImage *padMiddleHorizontalImage;
@property (nonatomic, strong) UIImage *padBottomHorizontalImage;

@end

@implementation NoteViewerBackgroundView

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect_
{
    NSLog(@"width: %f", self.frame.size.width);
    
    
    UIImage *topImage;
    UIImage *middleImage;
    UIImage *bottomImage;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(self.phoneTopImage == nil)
            self.phoneTopImage = [UIImage imageNamed:@"Note Viewer Top Dark"];
        if(self.phoneMiddleImage == nil)
            self.phoneMiddleImage = [UIImage imageNamed:@"Note Viewer Middle Dark"];
        if(self.phoneBottomImage == nil)
            self.phoneBottomImage = [UIImage imageNamed:@"Note Viewer Bottom Dark"];
        
        topImage = self.phoneTopImage;
        middleImage = self.phoneMiddleImage;
        bottomImage = self.phoneBottomImage;
    } else if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
        if(self.padTopVerticalImage == nil)
            self.padTopVerticalImage = [UIImage imageNamed:@"Note Viewer Pad Top Vertical Dark"];
        if(self.padMiddleVerticalImage == nil)
            self.padMiddleVerticalImage = [UIImage imageNamed:@"Note Viewer Pad Middle Vertical Dark"];
        if(self.padBottomVerticalImage == nil)
            self.padBottomVerticalImage = [UIImage imageNamed:@"Note Viewer Pad Bottom Vertical Dark"];

        topImage = self.padTopVerticalImage;
        middleImage = self.padMiddleVerticalImage;
        bottomImage = self.padBottomVerticalImage;
    } else {
        if(self.padTopHorizontalImage == nil)
            self.padTopHorizontalImage = [UIImage imageNamed:@"Note Viewer Pad Top Horizontal Dark"];
        if(self.padMiddleHorizontalImage == nil)
            self.padMiddleHorizontalImage = [UIImage imageNamed:@"Note Viewer Pad Middle Horizontal Dark"];
        if(self.padBottomHorizontalImage == nil)
            self.padBottomHorizontalImage = [UIImage imageNamed:@"Note Viewer Pad Bottom Horizontal Dark"];
        
        topImage = self.padTopHorizontalImage;
        middleImage = self.padMiddleHorizontalImage;
        bottomImage = self.padBottomHorizontalImage;
    }

    //draw top
    [topImage drawInRect:CGRectMake(0.0, 0.0, topImage.size.width, topImage.size.height)];

    //draw bottom
    [bottomImage drawInRect:CGRectMake(0.0,
                                                  self.frame.size.height - topImage.size.height,
                                                  bottomImage.size.width,
                                                  bottomImage.size.height)];

    //draw middle
    double yOffset = bottomImage.size.height;
    NSInteger linesCount = self.frame.size.height - (topImage.size.height + bottomImage.size.height);
    //nothing will get drawn anyway, just don't do that check in the loop
    if(linesCount <= 0)
        return;
    
    for(NSInteger i=0; i<linesCount; i++) {
        [middleImage drawInRect:CGRectMake(0.0,
                                                      yOffset + i*middleImage.size.height,
                                                      middleImage.size.width,
                                                      middleImage.size.height)];
    }
}

@end
