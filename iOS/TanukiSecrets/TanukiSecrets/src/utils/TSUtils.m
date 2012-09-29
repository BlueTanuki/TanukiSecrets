//
//  TSUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/29/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUtils.h"

#define ARC4RANDOM_MAX      0x100000000

@implementation TSUtils

#pragma mark - random numbers generation

+ (double)randomDouble
{
	return ((double)arc4random() / ARC4RANDOM_MAX);
}

+ (double)randomDoubleBetween:(double)a and:(double)b
{
	double mul = b - a;
	if (mul < 0) {
		mul = -mul;
	}
	double ret = [self randomDouble];
	ret *= mul;
	if (b > a) {
		ret += a;
	}else {
		ret += b;
	}
	return ret;
}

@end
