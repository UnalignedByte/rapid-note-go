//
//  NSDate+NiceFormatting.h
//  Rapid Note
//
//  Created by Rafał Grodziński on 2012/12/14.
//  Copyright (c) 2012年 UnalignedByte. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (NiceFormatting)

- (NSString *)formatAsNiceString;
- (NSString *)formatAsShortNiceString;

@end
