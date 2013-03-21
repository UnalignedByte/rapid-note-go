//
//  MacroHelpers.c
//  Rapid Note
//
//  Created by Rafał Grodziński on 27.01.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import "MacroHelpers.h"

NSInteger systemVersionMacroHelper(void)
{
    NSString *versionString = [[UIDevice currentDevice] systemVersion];
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    
    return (NSInteger)[versionComponents[0] integerValue];
}
