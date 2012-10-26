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
#import "TSDropboxWrapper.h"
#import "TSiCloudWrapper.h"

@interface TSSharedState()

@property(nonatomic, readonly) TSDatabaseWrapper *dropboxWrapper;
@property(nonatomic, readonly) TSDatabaseWrapper *iCloudWrapper;

@end

@implementation TSSharedState

@synthesize openDatabasePassword;
@synthesize instanceUID = _instanceUID;

@synthesize dropboxWrapper = _dropboxWrapper;
@synthesize iCloudWrapper = _iCloudWrapper;

#pragma mark - singleton creation

+ (TSSharedState*)sharedState
{
    static TSSharedState *sharedState = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{sharedState = [[self alloc] init];});
    return sharedState;
}

#pragma mark - read-only properties

+ (NSString *)instanceUID
{
	return [self sharedState].instanceUID;
}

- (NSString *)instanceUID
{
	if (_instanceUID == nil) {
		NSString *defaultUid = [TSStringUtils generateUid];
		_instanceUID = [TSUserDefaults stringForKey:TS_INSTANCE_UID_KEY usingDefaultValue:defaultUid];
	}
	return _instanceUID;
}

+ (TSDatabaseWrapper *)dropboxWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate
{
	return [[self sharedState] dropboxWrapperForDelegate:delegate];
}

- (TSDatabaseWrapper *)dropboxWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate
{
	if (_dropboxWrapper == nil) {
		TSDropboxWrapper *worker = [[TSDropboxWrapper alloc] init];
		_dropboxWrapper = [TSDatabaseWrapper databaseWrapperWithWorker:worker];
	}
	if ([_dropboxWrapper busy] == YES) {
		NSLog (@"dropboxWrapper instance is busy...");
		return nil;
	}
	_dropboxWrapper.delegate = delegate;
	return _dropboxWrapper;
}

+ (TSDatabaseWrapper *)iCloudWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate
{
	return [[self sharedState] iCloudWrapperForDelegate:delegate];
}

- (TSDatabaseWrapper *)iCloudWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate
{
	if (_iCloudWrapper == nil) {
		TSiCloudWrapper *worker = [[TSiCloudWrapper alloc] init];
		_iCloudWrapper = [TSDatabaseWrapper databaseWrapperWithWorker:worker];
	}
	if ([_iCloudWrapper busy] == YES) {
		NSLog (@"iCloudWrapper instance is busy...");
		return nil;
	}
	_iCloudWrapper.delegate = delegate;
	[(TSiCloudWrapper *)_iCloudWrapper.worker refreshUbiquityContainerURL];
	return _iCloudWrapper;
}

@end
