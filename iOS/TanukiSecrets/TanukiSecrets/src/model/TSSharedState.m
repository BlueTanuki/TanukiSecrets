//
//  TSSharedState.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSSharedState.h"

@implementation TSSharedState

@synthesize instanceUID = _instanceUID;

#pragma mark - singleton creation

+ (TSSharedState*)sharedState
{
    static TSSharedState *sharedState = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{sharedState = [[self alloc] init];});
    return sharedState;
}

#pragma mark - read-only properties

- (NSString *)instanceUID
{
	if (_instanceUID == nil) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		_instanceUID = [defaults stringForKey:TS_INSTANCE_UID_KEY];
		if (_instanceUID != nil) {
			NSLog(@"UID retrieved from NSUserDefaults : %@", _instanceUID);
		}else {
			CFUUIDRef uuidref = CFUUIDCreate(CFAllocatorGetDefault());
			_instanceUID = (__bridge NSString *)(CFUUIDCreateString(CFAllocatorGetDefault(), uuidref));
			NSLog(@"UID generated via CFUUIDCreate : %@", _instanceUID);
			[defaults setObject:_instanceUID forKey:TS_INSTANCE_UID_KEY];
			[defaults synchronize];
		}
	}
	return _instanceUID;
}

@end
