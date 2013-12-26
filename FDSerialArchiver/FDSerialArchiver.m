//
//  FDSerialArchiver.m
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#import "FDSerialArchiver.h"
#import "FDSerialCommons.h"

@interface FDSerialArchiver (){
    NSMutableData *_data;   // Buffer containing the data written so far
    
    void *_bytes;           // We don't use appendData on _data, instead we manage a pointer to the buffer
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
        _bytes = _data.mutableBytes;
        _position = 0;

        // hashtables filled during encoding used to keep info on what was already encoded
        _classes = [NSHashTable weakObjectsHashTable];      // class name will be encoded on the first time the class is met
        _objects = [NSHashTable weakObjectsHashTable];      // object will be encoded on the first time the object is met
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
    _bytes = _data.mutableBytes;
}

-(void)_appendBytes:(const void *)data length:(NSUInteger)length
{
    [self _expandBuffer:length];
    memcpy(_bytes+_position, data, length);
    _position += length;
}

-(void)_appendCString:(const char*)cString
{
    NSUInteger length = strlen(cString);
    [self _appendBytes:cString length:length+1];
    
}

-(void)_appendData:(NSData*)data
{
    uint32_t length = (uint32_t)data.length;
    
    [self _appendBytes:&length length:sizeof(uint32_t)];
    [self _appendBytes:data.bytes length:length];
}

-(void)_appendReference:(const void *)reference
{
	[self _appendBytes:&reference length:sizeof(void*)];
}

-(void)_appendClass:(Class)class
{
    // NSObject is always nil
    if (class == [NSObject class]) {
        [self _appendReference:nil];
        return;
    }
    
    // Append reference to class
    [self _appendReference:(__bridge const void *)(class)];
    
    // And append class name if this is the first time it is encountered
    if (![_classes containsObject:class])
    {
        [_classes addObject:class];
        [self _appendCString:[NSStringFromClass(class) cStringUsingEncoding:NSASCIIStringEncoding]];
    }
}

-(void)_appendObject:(const id)object
{
    // References are saved
    // Although we don't yet handle relationships between objects (we could do it the exact same way we do for classes)
    // at least it is useful to determine whether object was nil or not
    [self _appendReference:(__bridge const void *)(object)];
    
    if (!object)
        return;
    
    // TODO: check the _objects NSHashTable
    
    [self _appendClass:[object classForCoder]];
    [object encodeWithCoder:self];
    
}

-(void)_appendArrayOfType:(const char*)type at:(const void *)addr
{
    const char *tmp = type+1; // (skip [
    
    // Get number of elements
    NSUInteger length = parseInt(&tmp);
    
    // Get size of each element
    NSUInteger size = sizeOfType(tmp);

    // We don't know the size of that particular element
    if (length == NSUIntegerMax)
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
        case '@':{
            id object = *(const id *)addr;
            [self _appendObject:object];
        }
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
    return [NSClassFromString(className) version];
}

#pragma mark - Misc

-(NSData*)data
{
    return [_data copy];
}

+(NSData *)archivedDataWithRootObject:(id)rootObject
{
    FDSerialArchiver *archiver = [[FDSerialArchiver alloc] init];
    
    [archiver encodeRootObject:rootObject];
    return archiver.data;
}




@end