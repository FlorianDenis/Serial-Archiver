//
//  FDArchivingController.m
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//


#import "FDArchivingController.h"
#import "FDSerialArchiver.h"
#import "FDSerialUnarchiver.h"

@interface FDMockObject : NSObject <NSCoding> {
    int i1, i2;
    char *c1;
    double m1[3][3];
    NSNumber *n1, *n2, *n3, *n4;
    NSString *s1, *s2;
    NSArray *a1;
    NSDictionary *d1;
}
@end

@implementation FDMockObject

-(id)init
{
    self = [super init];
    if (self) {
        
        i1 = 42;
        i2 = 0;
        
        c1 = "I am a demo C-style string";
        
        m1[0][0] = m1[1][1] = m1[2][2] = .5;
        m1[0][1] = m1[0][2] = m1[1][0] = m1[1][2] = m1[2][0] = m1[2][1] = 0;
        
        n1 = @(i1);
        n2 = @(i2);
        n3 = nil;
        n4 = n2;
        
        s1 = @"Foo";
        s2 = @"Bar";
        
        a1 = @[n1,s1,n2,s2];
        
        d1 = @{s1: n1, s2: n2};
        
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeValueOfObjCType:@encode(int) at:&i1];
    [aCoder encodeValueOfObjCType:@encode(int) at:&i2];
    [aCoder encodeValueOfObjCType:@encode(char*) at:&c1];
    [aCoder encodeValueOfObjCType:@encode(double[3][3]) at:&m1];
    
    [aCoder encodeObject:n1];
    [aCoder encodeObject:n2];
    [aCoder encodeObject:n3];
    [aCoder encodeObject:n4];
    
    [aCoder encodeObject:s1];
    [aCoder encodeObject:s2];
    
    [aCoder encodeObject:a1];
    
    [aCoder encodeObject:d1];
    
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        // Order is important
        [aDecoder decodeValueOfObjCType:@encode(int) at:&i1];
        [aDecoder decodeValueOfObjCType:@encode(int) at:&i2];
        [aDecoder decodeValueOfObjCType:@encode(char*) at:&c1];
        [aDecoder decodeValueOfObjCType:@encode(double[3][3]) at:&m1];
        
        n1 = [aDecoder decodeObject];
        n2 = [aDecoder decodeObject];
        n3 = [aDecoder decodeObject];
        n4 = [aDecoder decodeObject];

        s1 = [aDecoder decodeObject];
        s2 = [aDecoder decodeObject];
        
        a1 = [aDecoder decodeObject];
        
        d1 = [aDecoder decodeObject];
        
    }
    return self;
}

@end


@implementation FDArchivingController


-(void)archiveData
{
    FDMockObject *obj = [[FDMockObject alloc] init];
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj];
    
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"archive"];
    [data writeToFile:tempFile atomically:YES];

    
}

-(void)unarchiveData
{
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"archive"];
    NSData *data = [NSData dataWithContentsOfFile:tempFile];
    

    FDMockObject *obj = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    NSLog(@"%@",obj);
    
}

-(void)stressTestArchive
{
    
    NSMutableArray *array = [NSMutableArray array];
    const unsigned N = 100000;
    
    for (unsigned i = 0; i < N; ++i){
        [array addObject:@{@"Test" :  [[FDMockObject alloc] init]}];
    }
    
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:array];
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"stresstest-archive"];
    [data writeToFile:tempFile atomically:YES];

    
}

-(void)stressTestUnarchive
{
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"stresstest-archive"];
    NSData *data = [NSData dataWithContentsOfFile:tempFile];
    
    
    NSArray *obj = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    NSLog(@"%lu",(unsigned long)obj.count);

    
}

@end
