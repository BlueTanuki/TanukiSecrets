//
//  TSStringUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/31/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSStringUtils.h"

@implementation TSStringUtils

#pragma mark - conversion

+ (NSData *) dataFromHexString:(NSString *)string
{
    NSMutableData *stringData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [string length] / 2; i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [stringData appendBytes:&whole_byte length:1];
    }
    return stringData;
}

+ (NSString*) hexStringFromData:(NSData *)data
{
    unichar* hexChars = (unichar*)malloc(sizeof(unichar) * (data.length*2));
    unsigned char* bytes = (unsigned char*)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        unichar c = bytes[i] / 16;
        if (c < 10) c += '0';
        else c += 'a' - 10;
        hexChars[i*2] = c;
        c = bytes[i] % 16;
        if (c < 10) c += '0';
        else c += 'a' - 10;
        hexChars[i*2+1] = c;
    }
    NSString* retVal = [[NSString alloc] initWithCharactersNoCopy:hexChars
                                                           length:data.length*2
                                                     freeWhenDone:YES];
    return retVal;
}

+ (NSString *)stringFromInteger:(NSInteger)value
{
	return [NSString stringWithFormat:@"%d", value];
}

#pragma mark - transform

+ (NSString *)trim:(NSString *)string
{
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - information

+ (BOOL)isBlank:(NSString *)string
{
	BOOL ret = YES;
	if (string != nil) {
		NSString *trimmed = [self trim:string];
		if ([trimmed length] > 0) {
			ret = NO;
		}
	}
	return ret;
}

+ (BOOL)isNotBlank:(NSString *)string
{
	return ![self isBlank:string];
}

#pragma mark - factory

+ (NSString *)generateUid
{
	CFUUIDRef uuidref = CFUUIDCreate(CFAllocatorGetDefault());
	NSString *ret = (__bridge_transfer NSString *)(CFUUIDCreateString(CFAllocatorGetDefault(), uuidref));
	CFRelease(uuidref);
	return ret;
}

@end
