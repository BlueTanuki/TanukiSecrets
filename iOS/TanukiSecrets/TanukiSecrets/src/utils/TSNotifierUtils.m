//
//  TSNotifierUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNotifierUtils.h"

#import "JSNotifier.h"
#import "TSUtils.h"

@implementation TSNotifierUtils

+ (void)info:(NSString *)text
{
	[TSUtils foreground:^{
		JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:text];
		jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck.png"]];
		[jsn showFor:2.0];
	}];
	NSLog (@"[INFO] %@ [TSNotifierUtils]", text);
}

+ (void)error:(NSString *)text
{
	[TSUtils foreground:^{
		JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:text];
		jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX.png"]];
		[jsn showFor:2.0];
	}];
	NSLog (@"[ERROR] %@ [TSNotifierUtils]", text);
}

@end
