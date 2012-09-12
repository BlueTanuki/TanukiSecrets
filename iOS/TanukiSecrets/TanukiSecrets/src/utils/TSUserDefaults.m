//
//  TSUserDefaults.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUserDefaults.h"

@implementation TSUserDefaults

+ (NSString *)stringForKey:(NSString *)key usingDefaultValue:(NSString *)defaultValue
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *ret = [defaults stringForKey:key];
	if (ret == nil) {
		[defaults setObject:defaultValue forKey:key];
		[defaults synchronize];
		ret = defaultValue;
	}
	return ret;
}

+ (NSInteger)integerForKey:(NSString *)key usingDefaultValue:(NSInteger)defaultValue
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger ret = [defaults integerForKey:key];
	if ((ret == 0) && (defaultValue != 0)) {
		[defaults setInteger:defaultValue forKey:key];
		[defaults synchronize];
		ret = defaultValue;
	}
	return ret;
}

@end
