//
//  NoteViewerBackgroundView.m
//  Rapid Note
//
//  Created by Rafał Grodziński on 11/18/12.
//  Copyright (c) 2012 UnalignedByte. All rights reserved.
//

#import "NoteViewerBackgroundView.h"


@implementation NoteViewerBackgroundView

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect_
{
    //check if images are loaded, if not, load them
    if(self.viewerTopImage == nil)
        self.viewerTopImage = [UIImage imageNamed:@"Note Viewer Top Dark"];
    if(self.viewerMiddleImage == nil)
        self.viewerMiddleImage = [UIImage imageNamed:@"Note Viewer Middle Dark"];
    if(self.viewerBottomImage == nil)
        self.viewerBottomImage = [UIImage imageNamed:@"Note Viewer Bottom Dark"];
    
    //draw top
    [self.viewerTopImage drawInRect:CGRectMake(0.0, 0.0, self.viewerTopImage.size.width, self.viewerTopImage.size.height)];

    //draw bottom
    [self.viewerBottomImage drawInRect:CGRectMake(0.0,
                                                  self.frame.size.height - self.viewerTopImage.size.height,
                                                  self.viewerBottomImage.size.width,
                                                  self.viewerBottomImage.size.height)];

    //draw middle
    double yOffset = self.viewerBottomImage.size.height;
    NSInteger linesCount = self.frame.size.height - (self.viewerTopImage.size.height + self.viewerBottomImage.size.height);
    //nothing will get drawn anyway, just don't do that check in the loop
    if(linesCount <= 0)
        return;
    
    for(NSInteger i=0; i<linesCount; i++) {
        [self.viewerMiddleImage drawInRect:CGRectMake(0.0,
                                                      yOffset + i*self.viewerMiddleImage.size.height,
                                                      self.viewerMiddleImage.size.width,
                                                      self.viewerMiddleImage.size.height)];
    }
}

@end
