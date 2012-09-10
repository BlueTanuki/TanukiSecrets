//
//  TSSharedState.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSSharedState.h"

@implementation TSSharedState

static TSSharedState *sharedState = nil;

NSString *uid = nil;

+ (TSSharedState*)sharedState
{
	@synchronized(self) {
        if (sharedState == nil) {
            sharedState = [[self alloc] init];
		}
    }
    return sharedState;
}

#pragma mark - permanent properties

- (NSString *)instanceUID
{
	if (uid == nil) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		uid = [defaults stringForKey:TS_INSTANCE_UID_KEY];
		if (uid != nil) {
			NSLog(@"UID retrieved from NSUserDefaults : %@", uid);
		}else {
			CFUUIDRef uuidref = CFUUIDCreate(CFAllocatorGetDefault());
			uid = (__bridge NSString *)(CFUUIDCreateString(CFAllocatorGetDefault(), uuidref));
			NSLog(@"UID generated via CFUUIDCreate : %@", uid);
			[defaults setObject:uid forKey:TS_INSTANCE_UID_KEY];
			[defaults synchronize];
		}
	}
	return uid;
}

@end
