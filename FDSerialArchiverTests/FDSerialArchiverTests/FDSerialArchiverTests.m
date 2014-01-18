//
//  FDSerialArchiverTests.m
//  FDSerialArchiverTests
//
//  Created by Florian Denis on 26/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpedantic"

#import <XCTest/XCTest.h>

#import "FDSerialCommons.h"
#import "FDSerialArchiver.h"
#import "FDSerialUnarchiver.h"


@interface FDSerialArchiverTests : XCTestCase

@end

@implementation FDSerialArchiverTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Testing Common

-(void)testIntParsingValue
{
    const int N = 1000;
    
    for (int i = 0; i < N; ++i)
    {
        int x = arc4random_uniform(N);
        const char * str = [[NSString stringWithFormat:@"%d",x] cStringUsingEncoding:NSASCIIStringEncoding];
        NSUInteger y = parseInt(&str);
        
        XCTAssert(x == y);
        
    }
}

-(void)testIntParsingPointer
{
    const int N = 1000;
    const int M = 255;
    
    for (int i = 0; i < N; ++i)
    {
        char *buffer = (char*)malloc(2*M+2);
        char *p = buffer;
        
        // Build a randomly long string of figures & then letters
        int n = arc4random_uniform(M)+1;
        int m = arc4random_uniform(M)+1;
        for (int k = 0; k < n; ++k)
            *p++ = '0' + arc4random_uniform(10);
        char *q = p;
        *q++ = arc4random_uniform('0');
        for (int k = 0; k < m; ++k)
            *q++ = arc4random_uniform(256);
        
        
        *q = '\0';

        const char *str = buffer;
        parseInt(&str);
        
        XCTAssert(str == p);
        
        free(buffer);
        
    }
    
}

-(void)testSizeOfType
{
    // Primitive types
    XCTAssert( sizeOfType(@encode( char      ))   == sizeof( char       ));
    XCTAssert( sizeOfType(@encode( short     ))   == sizeof( short      ));
    XCTAssert( sizeOfType(@encode( int       ))   == sizeof( int        ));
    XCTAssert( sizeOfType(@encode( long      ))   == sizeof( long       ));
    XCTAssert( sizeOfType(@encode( long long ))   == sizeof( long long  ));
    XCTAssert( sizeOfType(@encode( float     ))   == sizeof( float      ));
    XCTAssert( sizeOfType(@encode( double    ))   == sizeof( double     ));
    
    // Primitive arrays
    XCTAssert( sizeOfType(@encode( long[42]  ))   == sizeof( long[42]   ));
    
    // Nested arrays
    const char* type = @encode(double[42][1337][1]);
    XCTAssert( sizeOfType(type) == sizeof(double[42][1337][1]) );
    
    // 0-terminated strings
    XCTAssert( sizeOfType(@encode(char*)) == FDUnknownSize );
    
    // Objective-C obj
    XCTAssert( sizeOfType(@encode(id)) == FDUnknownSize );
    
}


#pragma mark - Testing Archiving

-(void)testArchivingNSNumber
{
    
    id obj1 = @42;

    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj1];
    id obj2 = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    XCTAssert( [obj1 isEqual:obj2] );
    
}

-(void)testArchivingNSString
{
    
    id obj1 = @"Donec congue lacinia dui, a porttitor lectus condimentum laoreet. Nunc eu ullamcorper orci.";
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj1];
    id obj2 = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    XCTAssert( [obj1 isEqual:obj2] );
    
}

-(void)testArchivingNSArray
{
    
    id obj1 = [@"Donec congue lacinia dui, a porttitor lectus condimentum laoreet. Nunc eu ullamcorper orci." componentsSeparatedByString:@" "];
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj1];
    id obj2 = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    XCTAssert( [obj1 isEqual:obj2] );
    
}


-(void)testArchivingNSDictionnary
{
    
    id obj1 = @{
                @"Foo": @"Bar",
                @"Bar": @42,
                @"Test":[@"Donec congue lacinia dui, a porttitor lectus condimentum laoreet. Nunc eu ullamcorper orci." componentsSeparatedByString:@" "],
                @1337: [NSDate date]
                };
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj1];
    id obj2 = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    XCTAssert( [obj1 isEqual:obj2] );
    
}

-(void)testObjectReferencing
{
    id obj = @42;
    
    NSDictionary* obj1 = @{
                           @"Fo": @"oB",
                           @"ar": obj,
                           @"Test":@[@41,obj,@43,@44],
                           @1337: [NSDate date]
                           };
    
    NSData *data = [FDSerialArchiver archivedDataWithRootObject:obj1];
    NSDictionary* obj2 = [FDSerialUnarchiver unarchiveObjectWithData:data];
    
    // This needs to be a pointer equality
    XCTAssert( obj2[@"ar"] == obj2[@"Test"][1] );

}

#pragma mark - Performances

-(void)testSpeedEncoding
{
    
    // Build a big NSDictionnary
    const int N = 5;
    const int M = 10000;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0; i < N; ++i)
    {
        NSMutableArray *array = [NSMutableArray array];
        for (int j = 0; j < M; ++j)
        {
            [array addObject:@(i*M+j)];
        }
        dict[ [NSString stringWithFormat:@"%d",i] ] = array;
    }
    
    const int P = 50;
    
    NSTimeInterval dt1, dt2;
    
    NSLog(@"==========================");
    // Encode it with FDSerialArchiver a lot and average time
    {
        NSDate *start = [NSDate date];
        for (int i = 0; i < P; ++i)
            [FDSerialArchiver archivedDataWithRootObject:dict];
         dt1 = -[start timeIntervalSinceNow];
        
        NSLog(@"FDSerialArchiver : %.2fms",dt1/P*1000);
    }
    
    // Encode it with NSKeyedArchiver a lot and average time
    {
        NSDate *start = [NSDate date];
        for (int i = 0; i < P; ++i)
            [NSKeyedArchiver archivedDataWithRootObject:dict];
        dt2 = -[start timeIntervalSinceNow];
        
        NSLog(@"NSKeyedArchiver : %.2fms",dt2/P*1000);
    }
    NSLog(@"==========================");

    XCTAssert(dt1 < dt2);

}

-(void)testSize
{
    
    // Build a big NSDictionnary
    const int N = 5;
    const int M = 10000;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0; i < N; ++i)
    {
        NSMutableArray *array = [NSMutableArray array];
        for (int j = 0; j < M; ++j)
        {
            [array addObject:@(i*M+j)];
        }
        dict[ [NSString stringWithFormat:@"%d",i] ] = array;
    }
    
    // Encode it with FDSerialArchiver
    NSData *data1 = [FDSerialArchiver archivedDataWithRootObject:dict];
    
    // Encode it with NSKeyedArchiver
    NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    NSLog(@"========================");
    NSLog(@"FDSerialArchiver : %lukB",(unsigned long)(data1.length>>10));
    NSLog(@"NSKeyedArchiver : %lukB",(unsigned long)(data2.length>>10));
    NSLog(@"========================");
    
    XCTAssert(data1.length < data2.length);
}

@end

#pragma clang diagnostic pop
