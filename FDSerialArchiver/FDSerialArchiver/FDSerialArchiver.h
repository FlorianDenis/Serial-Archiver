//
//  FDSerialArchiver.h
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDSerialArchiver : NSCoder

+(NSData *)archivedDataWithRootObject:(id)rootObject;

@end
