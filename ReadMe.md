# FDSerialArchiver - FDSerialUnarchiver

## Overview

`FDSerialArchiver` is a serial binary archiver in the style of `NSArchiver`. 
Concretely, `FDSerialArchiver` and `FDSerialUnarchiver` are concrete subclasses of `NSCoder` (thus allowing you to use the `<NSCoding>` protocol) implementing the features of `NSArchiver`.
In opposition to `NSKeyedArchiver`, `FDSerialArchiver` does not support keyed archiving: data is serially appended/read from a stream of binary symbols for faster encoding/decoding.

## Motivation

`NSKeyedArchiver` is a great piece of software: it gives view keyed (un)archiving, versioning, *etc*. In short: it gives you flexibility. 
I started experimenting with serial archiving because sometimes, this kind of flexibility is overkill. You might want to serialize very lightweight, straightforward pieces of data that will not be subject to change in the future. The flexibility of `NSKeyedArchiver` results in speed and space compromises, and unfortunately `NSArchiver` is deprecated on OS X since 10.2, and AFAIK never made it to iOS. I was curious to see what kind of performances you can get by using more basic archiving techniques.
More importantly, I felt like it would be a good exercise and a nice way to get more acquainted with `NSCoder`. 

## Performance

## Usage

Using `FDSerialArchiver` is as simple as using the `NSCoding` protocol, but without the keyed part.
The classes you are used to using (`NSArray`, `NSNumber`, `NSString`, *etc*) all support 

For coding, you will need to implement the `encodeWithCoder:` method on your custom classes, for instance: 

    -(void)encodeWithCoder:(NSCoder *)aCoder
    {
        [aCoder encodeValueOfObjCType:@encode(double) at:&_someDoubleMember];
        [aCoder encodeObject:_someCustomClassInstanceMember];
        [aCoder encodeObject:_someMutableArrayMember];
    }
    
And simply call the archiving method on the root object to archive

    data = [FDSerialArchiver archivedDataWithRootObject:objectToEncode];
    
    
Decoding is done by implementing `initWithCoder:` in the same classes as you implemented `encodeWithCoder:`:

    -(id)initWithCoder:(NSCoder *)aDecoder
    {
        if (self = [super init]) {
            // Serial archiving => order is important !
            [aDecoder decodeValueOfObjCType:@encode(double) at:& _someDoubleMember];
            _someCustomClassInstanceMember = [aDecoder decodeObject];
            _someMutableArrayMember = [aDecoder decodeObject]; 
        }
        return self;
    }

And simply calling the unarchive method

    decodedObject = [ISUBinaryUnarchiver unarchiveObjectWithData:data];

    

## ToDo

 Before 0.1
 - Object referencing
 - ARC bug
 - Performance chart
 - Unit testing
 Before 0.2
 - More general C-style array encoding
 - 32-64 bit archive compatibility 
 Before 1.0
 - Versioning
 
## License

`FDSerialArchiver` is distributed using the MIT license. See the `LICENSE` file for detailed information

In short, you can use it, modify it and distribute it (including in binary form) as long as you include the following notice :


    FDSerialArchiver
    Copyright (c) 2013 Florian Denis
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

