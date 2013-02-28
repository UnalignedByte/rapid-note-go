//
//  Note.h
//  Rapid Note Go
//
//  Created by Rafał Grodziński on 28.02.2013.
//  Copyright (c) 2013 UnalignedByte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSDate * notificationDate;
@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) NSNumber * isUploaded;

@end
