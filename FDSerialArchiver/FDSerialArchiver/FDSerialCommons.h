//
//  FDSerialCommons.h
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#ifndef FDSerialArchiverDemo_FDSerialCommons_h
#define FDSerialArchiverDemo_FDSerialCommons_h

#pragma mark - Logging

#if FD_SERIAL_ARCHIVER_DEBUG
static unsigned logIndentLevel = 0;
#endif

static inline void FDLog(NSString * format, ...)
{
#if FD_SERIAL_ARCHIVER_DEBUG
    va_list args;
    va_start(args, format);
    
    NSString * indentString = [@"" stringByPaddingToLength:(2*logIndentLevel) withString:@" " startingAtIndex:0];
    
    NSLogv([NSString stringWithFormat:@"%@%@", indentString, format], args);
    
    va_end(args);
#endif
}

static inline void FDLogIndent(NSString * format, ...){
#if FD_SERIAL_ARCHIVER_DEBUG
    FDLog(format);
    logIndentLevel++;
#endif
}

static inline void FDLogOutdent(NSString * format, ...) {
#if FD_SERIAL_ARCHIVER_DEBUG
    logIndentLevel--;
    FDLog(format);
#endif
}


#pragma mark - Misc functions used in archiver & unarchiver

static NSUInteger const FDUnknownSize = NSUIntegerMax;


// Parse a positive integer and locate the pointer to the first non-figure character in the string
static inline NSUInteger parseInt(const char **tmp)
{

    NSUInteger i = 0;
    
    // Get size of array from type
    while (**tmp >= '0' && **tmp <= '9')
    {
        i = (i*10)+(**tmp-'0');
        ++(*tmp);
    }
    
    return i;

}

static inline NSUInteger sizeOfType(const char *type)
{
    switch(*type){
            // char
        case 'c':
        case 'C':
            return sizeof(char);
            
            // short
        case 's':
        case 'S':
            return sizeof(short);
            
            // int
        case 'i':
        case 'I':
            return sizeof(int);
            
            // long
        case 'l':
        case 'L':
            return sizeof(long);
            
            // long long
        case 'q':
        case 'Q':
            return sizeof(long long);
            
            // float
        case 'f':
            return sizeof(float);
            
            // double
        case 'd':
            return sizeof(double);
            
            // Array
        case '[':{
            const char *tmp = type+1; // Skip [
            
            // Get length of array
            NSUInteger length = parseInt(&tmp);
            
            // Get size of each element
            NSUInteger size = sizeOfType(tmp);
            
            return (size != FDUnknownSize ? size*length : FDUnknownSize);
        }
            
        case '^':
            return sizeof(void*);
            
            // Unknown/unimplemented
        case '*':
        case '#':
        case ':':
        case '{':
        case '(':
        case 'b':
        case '?':
        default:
            return FDUnknownSize;
            
    }
}


#endif
