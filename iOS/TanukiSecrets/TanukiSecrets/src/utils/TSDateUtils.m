//
//  TSDateUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDateUtils.h"

@implementation TSDateUtils

static NSDateFormatter *_dateTimeFormat = nil;

+ (NSDateFormatter *) dateTimeFormat
{
	if (_dateTimeFormat == nil) {
		_dateTimeFormat = [[NSDateFormatter alloc] init];
		[_dateTimeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
	}
	return _dateTimeFormat;
}

+ (NSString *)stringFromDate:(NSDate *)date
{
	return [[self dateTimeFormat] stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)string
{
	return [[self dateTimeFormat] dateFromString:string];
}

static NSDateFormatter *_interfaceDateFormat = nil;

+ (NSDateFormatter *) interfaceDateFormat
{
	if (_interfaceDateFormat == nil) {
		_interfaceDateFormat = [[NSDateFormatter alloc] init];
		[_interfaceDateFormat setDateFormat:@"yyyy-MM-dd HH:mm"];
	}
	return _interfaceDateFormat;
}

+ (NSString *)interfaceStringFromDate:(NSDate *)date
{
	return [[self interfaceDateFormat] stringFromDate:date];
}


@end
