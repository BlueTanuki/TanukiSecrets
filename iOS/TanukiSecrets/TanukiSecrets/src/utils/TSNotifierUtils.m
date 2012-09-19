//
//  TSNotifierUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNotifierUtils.h"

#import "JSNotifier.h"

@implementation TSNotifierUtils

+ (void)info:(NSString *)text
{
	JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:text];
	jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck.png"]];
	[jsn showFor:2.0];
}

+ (void)error:(NSString *)text
{
	JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:text];
	jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX.png"]];
	[jsn showFor:2.0];
}

@end
