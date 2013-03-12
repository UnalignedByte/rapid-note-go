//
//  NSDate+NiceFormatting.h
//  Rapid Note
//
//  Created by Rafał Grodziński on 2012/12/14.
//  Copyright (c) 2012年 UnalignedByte. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (Additions)

- (NSString *)formatAsNiceString;
- (NSString *)formatAsShortNiceString;
- (NSDate *)dateByRemovingSeconds;
- (NSDate *)dateBySettingSecondsAtOne;
- (NSDate *)dateByAddingOneMinute;

@end
