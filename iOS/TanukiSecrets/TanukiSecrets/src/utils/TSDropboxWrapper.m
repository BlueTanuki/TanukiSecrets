//
//  TSDropboxWrapper.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDropboxWrapper.h"

#import "TSConstants.h"
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
	NSLog (@"File upload failed :: %@", [error debugDescription]);
	[self.uploadDelegate dropboxWrapper:self
			  uploadForDatabase:self.databaseUid
							failedWithError:[error description]];
	_state = IDLE;
	self.uploadDelegate = nil;
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
    NSLog(@"File uploaded successfully to path: %@", destPath);
	switch (self.state) {
		case UPLOAD_METADATA: {
			if ([self.uploadDelegate respondsToSelector:@selector(dropboxWrapper:uploadedMetadataFileForDatabase:)]) {
				[self.uploadDelegate dropboxWrapper:self uploadedMetadataFileForDatabase:self.databaseUid];
			}
			NSString *databaseFilePath = [TSIOUtils databaseFilePath:self.databaseUid];
			[self.dropboxRestClient uploadFile:[databaseFilePath lastPathComponent]
										toPath:@"/"
								 withParentRev:nil
									  fromPath:databaseFilePath];
			_state = UPLOAD_DATABASE;
		}
		break;
			
		case UPLOAD_DATABASE: {
			if ([self.uploadDelegate respondsToSelector:@selector(dropboxWrapper:uploadedMainFileForDatabase:)]) {
				[self.uploadDelegate dropboxWrapper:self uploadedMainFileForDatabase:self.databaseUid];
			}
			this is wrong!!!
			_state = IDLE;
			[self.uploadDelegate dropboxWrapper:self finishedUploadingDatabase:self.databaseUid];
			self.uploadDelegate = nil;
		}
		break;
			
		default: {
			NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Received successful file upload callback in unknown state (%d). Switching back to IDLE...", self.state);
			_state = IDLE;
		}
	}
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
	NSLog(@"File download failed :: %@", [error debugDescription]);
	switch (self.state) {
		case UPLOAD_CHECK_LOCKFILE: {
			this is probably a normal thing (TODO: can we test the error code or something???),
			the lock file should not exist and the download should fail,
			invocation of next step goes here
		}
		break;
			
		default: {
			NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Received failed file download callback in unknown state (%d). Switching back to IDLE...", self.state);
			_state = IDLE;
		}
	}
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath
{
	NSLog(@"File downloaded successfully to path %@", destPath);
	switch (self.state) {
		case UPLOAD_CHECK_LOCKFILE: {
			this can be a bad thing, we read the lock file and communicate failure
			if there is a lock held by somebody else
				Note : this is not necessarily a fatal error, since optimistic locks are advisory and can be overwritten
		}
		break;
			
		default: {
			NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Received successful file download callback in unknown state (%d). Switching back to IDLE...", self.state);
			_state = IDLE;
		}
	}
}

#pragma mark - wrapper methods

- (BOOL)busy
{
	return (self.state != IDLE);
}

NSString *metadataFilePath = [TSIOUtils metadataFilePath:databaseUid];
[self.dropboxRestClient uploadFile:[metadataFilePath lastPathComponent]
							toPath:@"/"
					 withParentRev:nil
						  fromPath:metadataFilePath];


- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid andReportToDelegate:(id<TSDropboxUploadDelegate>)delegate
{
	NSLog (@"WARNING : incorrect implementation, does not handle updates correctly");
	BOOL ret = NO;
	if (self.state == IDLE) {
		NSString *lockfileName = [databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
		NSString *lockfileLocalPath = [TSIOUtils temporaryFileNamed:lockfileName];
		NSString *lockfileRemotePath = [@"/" stringByAppendingString:lockfileName];
		[self.dropboxRestClient loadFile:lockfileRemotePath intoPath:lockfileLocalPath];
		self.databaseUid = databaseUid;
		self.uploadDelegate = delegate;
		_state = UPLOAD_READ_LOCKFILE;
		ret = YES;
	}
	return ret;
}

@end
