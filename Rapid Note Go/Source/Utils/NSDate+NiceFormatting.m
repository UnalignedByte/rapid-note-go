//
//  NSDate+NiceFormatting.m
//  Rapid Note
//
//  Created by Rafał Grodziński on 2012/12/14.
//  Copyright (c) 2012年 UnalignedByte. All rights reserved.
//

#import "NSDate+NiceFormatting.h"

@implementation NSDate (NiceFormatting)

- (NSString *)formatAsNiceString
{
    NSString *localizedDateFormat = [NSDateFormatter dateFormatFromTemplate:@"ddMMMMyyyy HHmm" options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *localizedDateFormatter = [[NSDateFormatter alloc] init];
    localizedDateFormatter.dateFormat = localizedDateFormat;
    
    return [localizedDateFormatter stringFromDate:self];
}


- (NSString *)formatAsShortNiceString
{
    NSString *localizedDateFormat = [NSDateFormatter dateFormatFromTemplate:@"ddMMyyyy HHmm" options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *localizedDateFormatter = [[NSDateFormatter alloc] init];
    localizedDateFormatter.dateFormat = localizedDateFormat;
    
    return [localizedDateFormatter stringFromDate:self];
}

@end
