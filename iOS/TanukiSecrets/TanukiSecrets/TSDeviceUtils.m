//
//  TSDeviceUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDeviceUtils.h"

@implementation TSDeviceUtils

+ (NSString *) deviceName
{
	return [UIDevice currentDevice].name;
}

@end
