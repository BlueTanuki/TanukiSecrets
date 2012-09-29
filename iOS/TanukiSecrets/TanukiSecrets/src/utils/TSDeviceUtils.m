//
//  TSDeviceUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDeviceUtils.h"

#import <TargetConditionals.h>

@implementation TSDeviceUtils

+ (NSString *) deviceName
{
	return [UIDevice currentDevice].name;
}

+ (BOOL) isRunningInSimulator
{
#ifdef TARGET_IPHONE_SIMULATOR
	return TARGET_IPHONE_SIMULATOR == 1;
#else
	return NO;
#endif
}

@end
