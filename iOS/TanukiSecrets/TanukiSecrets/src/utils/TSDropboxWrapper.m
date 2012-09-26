//
//  TSDropboxWrapper.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDropboxWrapper.h"

#import "TSIOUtils.h"

@interface TSDropboxWrapper()

@property(nonatomic, strong) DBRestClient *dropboxRestClient;

@property(nonatomic, weak) id<TSDropboxUploadDelegate> uploadDelegate;

@property(nonatomic, copy) NSString *databaseUid;

@end

@implementation TSDropboxWrapper

@synthesize busy = _busy, state = _state,
dropboxRestClient = _dropboxRestClient, uploadDelegate = _uploadDelegate,
databaseUid = _databaseUid;

#pragma mark - getter/setter override

- (DBRestClient *)dropboxRestClient
{
	if (_dropboxRestClient == nil) {
		_dropboxRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		_dropboxRestClient.delegate = self;
	}
	return _dropboxRestClient;
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
	NSLog (@"Dropbox upload failed :: %@", [error debugDescription]);
	[self.uploadDelegate dropboxWrapper:self
			  uploadForDatabase:self.databaseUid
							failedWithError:[error description]];
	_state = IDLE;
	self.uploadDelegate = nil;
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
    NSLog(@"File uploaded successfully to path: %@", destPath);
	if (self.state == UPLOADING_METADATA) {
		if ([self.uploadDelegate respondsToSelector:@selector(dropboxWrapper:uploadedMetadataFileForDatabase:)]) {
			[self.uploadDelegate dropboxWrapper:self uploadedMetadataFileForDatabase:self.databaseUid];
		}
		NSString *databaseFilePath = [TSIOUtils databaseFilePath:self.databaseUid];
		[self.dropboxRestClient uploadFile:[databaseFilePath lastPathComponent]
									toPath:@"/"
							 withParentRev:nil
								  fromPath:databaseFilePath];
		_state = UPLOADING_DATABASE;
	}else {
		if ([self.uploadDelegate respondsToSelector:@selector(dropboxWrapper:uploadedMainFileForDatabase:)]) {
			[self.uploadDelegate dropboxWrapper:self uploadedMainFileForDatabase:self.databaseUid];
		}
		_state = IDLE;
		[self.uploadDelegate dropboxWrapper:self finishedUploadingDatabase:self.databaseUid];
		self.uploadDelegate = nil;
	}
}

#pragma mark - wrapper methods

- (BOOL)busy
{
	return (self.state != IDLE);
}

- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid andReportToDelegate:(id<TSDropboxUploadDelegate>)delegate
{
	NSLog (@"WARNING : incorrect implementation, does not handle updates correctly");
	BOOL ret = NO;
	if (self.state == IDLE) {
		NSString *metadataFilePath = [TSIOUtils metadataFilePath:databaseUid];
		[self.dropboxRestClient uploadFile:[metadataFilePath lastPathComponent]
									toPath:@"/"
							 withParentRev:nil
								  fromPath:metadataFilePath];
		self.databaseUid = databaseUid;
		self.uploadDelegate = delegate;
		_state = UPLOADING_METADATA;
		ret = YES;
	}
	return ret;
}

@end
