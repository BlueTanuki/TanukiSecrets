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
#import "TSNotifierUtils.h"
#import "TSCryptoUtils.h"
#import "TSUtils.h"
#import "TSDBGroup.h"
#import "TSDBItem.h"
#import "TSIOUtils.h"

@interface TSSharedState()

@property(nonatomic, readonly) TSDatabaseWrapper *dropboxWrapper;
@property(nonatomic, readonly) TSDatabaseWrapper *iCloudWrapper;

@property(nonatomic, assign) BOOL nextEncryptKeyReady;
@property(nonatomic, assign) BOOL nextEncryptKeyGenerationInProgress;
@property(nonatomic, strong) NSData *nextEncryptKey;

@end

@implementation TSSharedState

@synthesize openDatabasePassword, openDatabaseMetadata, openDatabase;

@synthesize currentGroup = _currentGroup;
@synthesize currentItem = _currentItem;

@synthesize instanceUID = _instanceUID;

@synthesize dropboxWrapper = _dropboxWrapper;
@synthesize iCloudWrapper = _iCloudWrapper;

@synthesize nextEncryptKey, nextEncryptKeyGenerationInProgress, nextEncryptKeyReady;

@synthesize templatesDatabase = _templatesDatabase;

#pragma mark - override getters/setters

- (void)setCurrentGroup:(TSDBGroup *)currentGroup
{
	_currentGroup = currentGroup;
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"Current group set to %@", [_currentGroup uniqueGlobalId]);
	}
}

- (void)setCurrentItem:(TSDBItem *)currentItem
{
	_currentItem = currentItem;
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"Current item set to %@", [_currentItem uniqueGlobalId]);
	}
}

- (TSDatabase *)templatesDatabase
{
	if (_templatesDatabase == nil) {
		_templatesDatabase = [TSIOUtils loadTemplatesDatabase];
	}
	return _templatesDatabase;
}

#pragma mark - singleton creation and initialization

+ (TSSharedState*)sharedState
{
    static TSSharedState *sharedState = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{sharedState = [[self alloc] init];});
    return sharedState;
}

- (void)reset
{
	self.currentItem = nil;
	self.currentGroup = nil;
	self.openDatabasePassword = nil;
	self.openDatabase = nil;
	self.openDatabaseMetadata = nil;
}

#pragma mark - read-only properties

+ (NSString *)instanceUID
{
	return [self sharedState].instanceUID;
}

static NSArray *_userTemplates = nil;
+ (NSArray *)userTemplates {
	if (_userTemplates == nil) {
		[TSNotifierUtils error:@"user templates not implemented"];
		_userTemplates = [NSArray array];
	}
	return _userTemplates;
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
		[TSNotifierUtils error:@"dropboxWrapper instance is busy..."];
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
		[TSNotifierUtils error:@"iCloudWrapper instance is busy..."];
		return nil;
	}
	_iCloudWrapper.delegate = delegate;
	[(TSiCloudWrapper *)_iCloudWrapper.worker refreshUbiquityContainerURL];
	return _iCloudWrapper;
}

#pragma mark - prepare the next encryption key in the background

- (void)startPreparingNextEncryptKey
{
	if (self.nextEncryptKeyGenerationInProgress) {
		NSLog (@"[INTERNAL LOGIC ERROR] next encrypt key is already being generated");
		return;
	}
	if ((self.openDatabase == nil) || (self.openDatabasePassword == nil)) {
		NSLog (@"[INTERNAL LOGIC ERROR] next encrypt key cannot be generated before both metadata and password for the open database are set");
		return;
	}
	self.nextEncryptKeyGenerationInProgress = YES;
	self.nextEncryptKeyReady = NO;
	int64_t delayInSeconds = 2;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void){
		if ((self.openDatabase != nil) && (self.openDatabaseMetadata != nil) && (self.openDatabasePassword != nil)) {
			if (TS_DEV_DEBUG_ALL) {
				NSLog (@"next encryption key generation starting");
			}
			self.nextEncryptKey = [TSCryptoUtils tanukiEncryptKey:self.openDatabaseMetadata usingSecret:self.openDatabasePassword];
			self.nextEncryptKeyGenerationInProgress = NO;
			self.nextEncryptKeyReady = YES;
			if (TS_DEV_DEBUG_ALL) {
				NSLog (@"next encryption key generation finished");
			}
		}else {
			if (TS_DEV_DEBUG_ALL) {
				NSLog(@"Next encryption key computation aborted, database was probbaly closed.");
			}
		}
	});
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"next encryption key generation scheduled");
	}
}

- (BOOL)encryptKeyReady
{
	if (self.nextEncryptKeyReady) {
		return YES;
	}
	if (self.nextEncryptKeyGenerationInProgress) {
		return NO;
	}
	NSLog (@"[INTERNAL LOGIC ERROR] next encrypt key is neither ready nor being generated, starting to generate it now");
	[self startPreparingNextEncryptKey];
	return NO;
}

- (NSData *)encryptKey {
	if (self.nextEncryptKeyReady) {
		NSData *ret = self.nextEncryptKey;
		[self startPreparingNextEncryptKey];
		return ret;
	}
	NSLog (@"[INTERNAL LOGIC ERROR] encrypt key was called without checking if it is ready, returning nil");
	if (self.nextEncryptKeyGenerationInProgress == NO) {
		[self startPreparingNextEncryptKey];
	}
	return nil;
}

@end
