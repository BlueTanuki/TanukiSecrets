//
//  TSDateUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDateUtils.h"

@implementation TSDateUtils

static NSDateFormatter *dateTimeFormat = nil;

+ (NSDateFormatter *) dateTimeFormat
{
	if (dateTimeFormat == nil) {
		dateTimeFormat = [[NSDateFormatter alloc] init];
		[dateTimeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
	}
	return dateTimeFormat;
}

+ (NSString *)stringFromDate:(NSDate *)date
{
	return [[self dateTimeFormat] stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)string
{
	return [[self dateTimeFormat] dateFromString:string];
}

@end
