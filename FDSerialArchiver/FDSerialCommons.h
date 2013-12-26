//
//  FDSerialCommons.h
//  FDSerialArchiverDemo
//
//  Created by Florian Denis on 23/12/13.
//  Copyright (c) 2013 Florian Denis. All rights reserved.
//

#ifndef FDSerialArchiverDemo_FDSerialCommons_h
#define FDSerialArchiverDemo_FDSerialCommons_h

// Parse an integer and locate the pointer after the
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
            
            return (size != NSUIntegerMax ? size*length : NSUIntegerMax);
        }
            // Unknown/unimplemented
        case '*':
        case '#':
        case ':':
        case '{':
        case '(':
        case 'b':
        case '^':
        case '?':
        default:
            return NSUIntegerMax;
            
    }
}


#endif