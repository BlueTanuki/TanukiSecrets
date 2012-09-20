//
//  TSSharedState.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSSharedState.h"

#import "TSStringUtils.h"
#import "TSUserDefaults.h"

@implementation TSSharedState

@synthesize instanceUID = _instanceUID, dropboxWrapper = _dropboxWrapper;

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
		NSString *defaultUid = [TSStringUtils generateUid];
		_instanceUID = [TSUserDefaults stringForKey:TS_INSTANCE_UID_KEY usingDefaultValue:defaultUid];
	}
	return _instanceUID;
}

- (TSDropboxWrapper *)dropboxWrapper
{
	if (_dropboxWrapper == nil) {
		_dropboxWrapper = [[TSDropboxWrapper alloc] init];
	}
	return _dropboxWrapper;
}

@end
