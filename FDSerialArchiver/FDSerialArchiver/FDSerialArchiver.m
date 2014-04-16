//
//  FDSerialArchiver.m
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#import "FDSerialArchiver.h"
#import "FDSerialCommons.h"

#if !__has_feature(objc_arc)
#error FDSerialArchiver needs ARC
#endif


@interface FDSerialArchiver (){
    NSMutableData *_data;   // Buffer containing the data written so far
    
    char *_bytes;           // We don't use appendData on _data, instead we manage a pointer to the buffer
    size_t _position;       // and the position in this buffer by ourselves
    
    NSHashTable *_classes;  // Keep a memory of classes already encoded (avoid duplication of information)
    NSHashTable *_objects;  // Keep a memory of objects already encoded (handle object relationship)
}
@end


@implementation FDSerialArchiver


#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        _data = [[NSMutableData alloc] init];
        _bytes = (char*)_data.mutableBytes;
        _position = 0;

        // hashtables filled during encoding used to keep info on what was already encoded
        _classes = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];      // class name will be encoded on the first time the class is met
        _objects = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];      // object will be encoded on the first time the object is met
    }
    return self;
}

- (void)dealloc
{
}

#pragma mark - Core Encoding

-(void)_expandBuffer:(NSUInteger)length
{
    [_data increaseLengthBy:length];
    _bytes = (char*)_data.mutableBytes;
}

-(void)_appendBytes:(const void *)data length:(NSUInteger)length
{
    [self _expandBuffer:length];
    memcpy(_bytes+_position, data, length);
    _position += length;
}

-(void)_appendCString:(const char*)cString
{
    FDLog(@"Appending C-string: %s",cString);
    
    NSUInteger length = strlen(cString);
    [self _appendBytes:cString length:length+1];
    
}

-(void)_appendData:(NSData*)data
{
    FDLog(@"Appending NSData: %@",data);
    
    uint32_t length = (uint32_t)data.length;
    
    [self _appendBytes:&length length:sizeof(uint32_t)];
    [self _appendBytes:data.bytes length:length];
}

-(void)_appendReference:(const void *)reference
{
    FDLog(@"Appending Reference: %p",reference);
    
	[self _appendBytes:&reference length:sizeOfType("^")];
}

-(void)_appendClass:(Class)objectClass
{
    FDLog(@"Appending class: %@",objectClass);
    FDLogIndent(@"{");
    
    // NSObject is always nil
    if (objectClass == [NSObject class]) {
        [self _appendReference:nil];
        return;
    }
    
    // Append reference to class
    [self _appendReference:(__bridge const void *)(objectClass)];
    
    // And append class name if this is the first time it is encountered
    if (![_classes containsObject:objectClass])
    {
        [_classes addObject:objectClass];
        [self _appendCString:[NSStringFromClass(objectClass) cStringUsingEncoding:NSASCIIStringEncoding]];
    }
    
    FDLogOutdent(@"}");
}

-(void)_appendObject:(const id)object
{
    FDLog(@"Appending object: %@",object);
    FDLogIndent(@"{");

    
    // Append object reference
    [self _appendReference:(__bridge const void *)(object)];
    
    // If object was nil, no need to go forward
    if (!object)
        return;
    
    // If this object was not encoded yet, encode it and its class
    if (![_objects containsObject:object])
    {
        [self _appendClass:[object classForCoder]];
        [object encodeWithCoder:self];
        
        [_objects addObject:object];
    }
    
    FDLogOutdent(@"}");

}

-(void)_appendArrayOfType:(const char*)type at:(const void *)addr
{
    FDLog(@"Appending array of type: %s",type);
    FDLogIndent(@"[");
    
    const char *tmp = type+1; // skip [
    
    // Get number of elements
    NSUInteger length = parseInt(&tmp);
    
    // Get size of each element
    NSUInteger size = sizeOfType(tmp);

    // We don't know the size of that particular element
    if (length == FDUnknownSize)
    {
        [self _cannotEncodeType:tmp];
        return;
    }
    
    // Encode array
    const char *src = (const char*)addr;
    for (NSUInteger i = 0; i < length; ++i)
    {
        [self encodeValueOfObjCType:tmp at:src];
        src += size;
    }
    
    FDLogOutdent(@"]");
    
}

#pragma mark - Branching by type

-(void)_cannotEncodeType:(const char *)type
{
    @throw [NSException exceptionWithName:@"ISUBinaryArchiverCannotEncodeException"
                                   reason:[NSString stringWithFormat:@"ISUBinaryArchiver cannot encode type %s",type]
                                 userInfo:nil];
}

-(void)encodeValueOfObjCType:(const char *)type at:(const void *)addr
{
    switch(*type){
            // char
        case 'c':
        case 'C':
            // short
        case 's':
        case 'S':
            // int
        case 'i':
        case 'I':
            // long
        case 'l':
        case 'L':
            // long long
        case 'q':
        case 'Q':
            // float
        case 'f':
            // double
        case 'd':
            FDLog(@"Appending value of type %c",*type);
            [self _appendBytes:addr length:sizeOfType(type)];
            break;
            
            // Fixed length array
        case '[':
            [self _appendArrayOfType:type at:addr];
            break;
            
            // C-string (0 terminated)
        case '*':
            [self _appendCString:*(const char**)addr];
            break;
            
            
            // Obj-C object
        case '@':
            [self _appendObject:*(const id *)addr];
            break;
            
            
        case '#':
        case ':':
        case '{':
        case '(':
        case 'b':
        case '^':
        case '?':
        default:
            [self _cannotEncodeType:type];
            break;
    }
    
}

-(void)encodeObject:(id)object
{
    [self _appendObject:object];
    
}

-(void)encodeDataObject:(NSData *)data
{
    [self _appendData:data];
}

-(void)encodeRootObject:(id)rootObject
{
    // Header
    [self _appendCString:"fdsarchive"];
    
    // Root object
    [self encodeObject:rootObject];
    
}

#pragma mark - Versionning

-(NSInteger)versionForClassName:(NSString *)className
{
    Class objectClass = NSClassFromString(className);
    return objectClass ? [objectClass version] : NSNotFound;
}

#pragma mark - Misc

-(NSData*)data
{
    return [_data copy];
}

+(NSData *)archivedDataWithRootObject:(id)rootObject
{
    @autoreleasepool {
        
        FDSerialArchiver *archiver = [[FDSerialArchiver alloc] init];
        [archiver encodeRootObject:rootObject];
        return archiver.data;

    }
    
}




@end
