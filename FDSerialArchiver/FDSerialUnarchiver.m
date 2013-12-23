//
//  FDSerialUnarchiver.m
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#import "FDSerialUnarchiver.h"
#import "FDSerialCommons.h"

@interface FDSerialUnarchiver (){
    NSData *_data;              // Reference to the NSData to read
    const void *_bytes;         // Pointer to the current position in the NSData buffer
    
    NSMapTable *_classes;       // Mapping between class references and actual class
    NSMapTable *_objects;       // Mapping between object references and actual objects
}

@end


@implementation FDSerialUnarchiver

#pragma mark - Init

-(id)initForReadingWithData:(NSData*)data
{
    self = [super init];
    if (self) {
        _data = data;
        _bytes = [data bytes];
        
        // Keep track of reference->object mapping
        _classes = [NSMapTable weakToWeakObjectsMapTable];
        _objects = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

-(void)dealloc
{
}

#pragma mark - Core decoding

-(void)_extractBytesTo:(void*)data length:(NSUInteger)length
{
    memcpy(data, _bytes, length);
    _bytes += length;
}

/**
 *  Beware! **YOU** will be responsible for freeing that string
 */
-(char*)_extractCString
{
    NSUInteger length = strlen(_bytes);
    char *string = (char*)malloc((length+1)*sizeof(char));
    [self _extractBytesTo:string length:length+1];
    
    return string;
    
}

-(NSData*)_extractData
{
    uint32_t length;
    [self _extractBytesTo:&length length:4];
    
    NSData *data = [NSData dataWithBytes:_bytes length:length];
    _bytes += length;
    
    return data;
    
}

-(const void *)_extractReference
{
    const void * reference;
    [self _extractBytesTo:&reference length:sizeof(void*)];
    return reference;
}


-(Class)_extractClass
{
    
    // Lookup class reference
    id reference = (__bridge id)[self _extractReference];
    
    // NSObject is always nil
    if (!reference)
        return [NSObject class];
    
    // Do we already know that one ?
    if (![_classes objectForKey:reference])
    {
        // If not, then the name should follow
        
        char *classCName = [self _extractCString];
        NSString *className = [NSString stringWithCString:classCName encoding:NSASCIIStringEncoding];
        free(classCName);
        
        Class class = NSClassFromString(className);
        
        [_classes setObject:class forKey:reference];
    }
    
    return [_classes objectForKey:reference];
    
}

-(id)_extractObject
{
    id objectReference = [self _extractReference];
    
    if (!objectReference)
    {
        return nil;
    }
    
    Class objectClass = [self _extractClass];
    id object = [[objectClass alloc] initWithCoder:self];
    
    return object;
    
}

-(void)_extractArrayOfType:(const char*)type to:(void *)addr
{
    const char *tmp = type+1; // (skip [

    // Get number of elements
    NSUInteger length = parseInt(&tmp);
    
    // Get size of each element
    NSUInteger size = sizeOfType(tmp);
    
    // We don't know the size of that particular element
    if (length == NSUIntegerMax)
    {
        [self _cannotDecodeType:tmp];
        return;
    }

    // Decode array
    char *dst = (char*)addr;
    for (NSUInteger i = 0; i < length; ++i)
    {
        [self decodeValueOfObjCType:tmp at:dst];
        dst += size;
    }
    
}


#pragma mark - Branching by type

-(void)_cannotDecodeType:(const char *)type
{
    
    @throw [NSException exceptionWithName:@"ISUBinaryUnarchiverCannotDecodeException"
                                   reason:[NSString stringWithFormat:@"ISUBinaryUnarchiver cannot decode type %s",type]
                                 userInfo:nil];
}

-(void)decodeValueOfObjCType:(const char *)type at:(void *)data
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
            [self _extractBytesTo:data length:sizeOfType(type)];
            break;
            
            // Fixed length array
        case '[':
            [self _extractArrayOfType:type to:data];
            break;
            
            
            // c-string (zero terminated)
        case '*':{
            *(char **)data = [self _extractCString];
        }
            break;
            
            // Obj-C object
        case '@':
            *(__strong id *) data = [self _extractObject];
            break;
            
        case '#':
        case ':':
        case '{':
        case '(':
        case 'b':
        case '^':
        case '?':
        default:
            [self _cannotDecodeType:type];
            break;
    }
    
    
}

-(id)decodeObject
{
    return [self _extractObject];
}

-(NSData*)decodeDataObject
{
    return [self _extractData];
}

-(id)decodeRootObject
{
    
    // Header
    char *header = [self _extractCString];
    if (strcmp(header, "fdsarchive"))
    {
        free(header);
        @throw [NSException exceptionWithName:@"ISUBinaryUnarchiverInvalidData"
                                       reason:@"Data does not appear to be a valid archive"
                                     userInfo:nil];
    }
    free(header);
    
    
    // Root object
    return [self decodeObject];
    
}

#pragma mark - Versionning

-(NSInteger)versionForClassName:(NSString *)className
{
    return [NSClassFromString(className) version];
}


#pragma mark - Misc

+(id)unarchiveObjectWithData:(NSData *)data
{
    FDSerialUnarchiver *unarchiver = [[FDSerialUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeRootObject];
}



@end
