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

#pragma mark - GCD helpers

+ (void)background:(void (^)(void))block
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

+ (void)foreground:(void (^)(void))block
{
	dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark - presenting various reusable dialogs

+ (void)notifyEncryptionKeyIsNotReady
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot perform action right now."
													message:@"The next encryption key is currently being generated in the background. Please try again in a few seconds."
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark - other UI crap

+ (void)setImage:(UIImage *)image forButton:(UIButton *)button
{
	[button setImage:image forState:UIControlStateNormal];
	[button setImage:image forState:UIControlStateHighlighted];
	[button setImage:image forState:UIControlStateDisabled];
	[button setImage:image forState:UIControlStateSelected];
	[button setImage:image forState:UIControlStateApplication];
	[button setImage:image forState:UIControlStateReserved];
}

@end
