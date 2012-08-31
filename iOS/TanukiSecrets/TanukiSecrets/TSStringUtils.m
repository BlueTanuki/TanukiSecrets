//
//  TSStringUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/31/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSStringUtils.h"

@implementation TSStringUtils

+ (NSString *)hexStringFor:(NSData *)data
{
	NSString *ret = [data description];
	ret = [ret stringByReplacingOccurrencesOfString:@" " withString:@""];
	ret = [ret stringByReplacingOccurrencesOfString:@"<" withString:@""];
	ret = [ret stringByReplacingOccurrencesOfString:@">" withString:@""];
	return ret;
}

@end
