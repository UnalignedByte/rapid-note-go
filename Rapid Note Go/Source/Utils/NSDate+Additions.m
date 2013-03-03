//
//  NSDate+NiceFormatting.m
//  Rapid Note
//
//  Created by Rafał Grodziński on 2012/12/14.
//  Copyright (c) 2012年 UnalignedByte. All rights reserved.
//

#import "NSDate+Additions.h"

@implementation NSDate (Additions)

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


- (NSDate *)dateByRemovingSeconds
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger calendarUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *nowDateComponents = [gregorianCalendar components:calendarUnits
                                                               fromDate:self];
    nowDateComponents.second = 0;
    return [gregorianCalendar dateFromComponents:nowDateComponents];
}

@end
