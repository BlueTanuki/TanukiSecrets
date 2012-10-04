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
#import "TSUtils.h"
#import "TSSharedState.h"
#import "TSBackupUtils.h"

@interface TSDropboxWrapper()

@property(nonatomic, strong) DBRestClient *dropboxRestClient;

@property(nonatomic, copy) NSString *databaseUid;

@property(nonatomic, copy) NSString *remoteLockfileRevision;
@property(nonatomic, copy) NSString *remoteBackupId;

@property(nonatomic, copy) NSString *optimisticLockComment;

@property(nonatomic, strong) NSArray *toBeDeleted;
@property(nonatomic, assign) NSInteger toBeDeletedIndex;

- (void)setState:(DropboxWrapperState)newState;

@end

@implementation TSDropboxWrapper

@synthesize state = _state,
dropboxRestClient = _dropboxRestClient, delegate = _delegate,
databaseUid = _databaseUid, remoteLockfileRevision = _remoteLockfileRevision,
remoteBackupId = _remoteBackupId,
optimisticLockComment = _optimisticLockComment,
toBeDeleted = _toBeDeleted, toBeDeletedIndex = _toBeDeletedIndex;

#pragma mark - state machine helpers

+ (NSString *)stateString:(DropboxWrapperState)state
{
	switch (state) {
		case IDLE:
			return @"IDLE";
		case WAITING:
			return @"WAITING";
		case LIST_DATABASE_UIDS:
			return @"LIST_DATABASE_UIDS";
		case UPLOAD_READ_LOCKFILE:
			return @"UPLOAD_READ_LOCKFILE";
		case UPLOAD_STALLED_OPTIMISTIC_LOCK:
			return @"UPLOAD_STALLED_OPTIMISTIC_LOCK";
		case UPLOAD_WRITE_LOCKFILE:
			return @"UPLOAD_WRITE_LOCKFILE";
		case UPLOAD_CHECK_LOCKFILE:
			return @"UPLOAD_CHECK_LOCKFILE";
		case UPLOAD_RECHECK_LOCKFILE:
			return @"UPLOAD_RECHECK_LOCKFILE";
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS:
			return @"UPLOAD_CHECK_BACKUP_FOLDER_EXISTS";
		case UPLOAD_CREATE_BACKUP_FOLDER:
			return @"UPLOAD_CREATE_BACKUP_FOLDER";
		case UPLOAD_CHECK_DATABASE_EXISTS:
			return @"UPLOAD_CHECK_DATABASE_EXISTS";
		case UPLOAD_MOVE_DATABASE_TO_BACKUP:
			return @"UPLOAD_MOVE_DATABASE_TO_BACKUP";
		case UPLOAD_CHECK_METADATA_EXISTS:
			return @"UPLOAD_CHECK_METADATA_EXISTS";
		case UPLOAD_MOVE_METADATA_TO_BACKUP:
			return @"UPLOAD_MOVE_METADATA_TO_BACKUP";
		case UPLOAD_METADATA:
			return @"UPLOAD_METADATA";
		case UPLOAD_DATABASE:
			return @"UPLOAD_DATABASE";
		case UPLOAD_DELETE_LOCKFILE:
			return @"UPLOAD_DELETE_LOCKFILE";
		case OPTIMISTIC_LOCK_ADD_READ_LOCKFILE:
			return @"OPTIMISTIC_LOCK_ADD_READ_LOCKFILE";
		case OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE:
			return @"OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE";
		case OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE:
			return @"OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE";
		case OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE:
			return @"OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE";
		case CLEANUP_READ_LOCKFILE:
			return @"CLEANUP_READ_LOCKFILE";
		case CLEANUP_WRITE_LOCKFILE:
			return @"CLEANUP_WRITE_LOCKFILE";
		case CLEANUP_CHECK_LOCKFILE:
			return @"CLEANUP_CHECK_LOCKFILE";
		case CLEANUP_LIST_LOCKFILES:
			return @"CLEANUP_LIST_LOCKFILES";
		case CLEANUP_DELETE_REDUNDANT_LOCKFILE:
			return @"CLEANUP_DELETE_REDUNDANT_LOCKFILE";
		case CLEANUP_CHECK_BACKUP_FOLDER_EXISTS:
			return @"CLEANUP_CHECK_BACKUP_FOLDER_EXISTS";
		case CLEANUP_DELETE_OLD_BACKUP:
			return @"CLEANUP_DELETE_OLD_BACKUP";
		case CLEANUP_DELETE_LOCKFILE:
			return @"CLEANUP_DELETE_LOCKFILE";
//		case XXX:
//			return @"XXX";
		default:
			return @"UNKNOWN";
	}
}

- (NSString *)stateString
{
	return [TSDropboxWrapper stateString:self.state];
}

- (void)setState:(DropboxWrapperState)newState
{
	NSLog (@"*** STATE TRANSITION :: %@(%d) -> %@(%d)", [self stateString], self.state, [TSDropboxWrapper stateString:newState], newState);
	_state = newState;
}

#pragma mark - getter/setter override

- (DBRestClient *)dropboxRestClient
{
	if (_dropboxRestClient == nil) {
		_dropboxRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		_dropboxRestClient.delegate = self;
	}
	return _dropboxRestClient;
}

#pragma mark - misc helper methods

- (NSArray *)filenameListFromMetadata:(DBMetadata *)metadata
{
	if (([metadata isDirectory] == YES) && ([metadata isDeleted] == NO)) {
		NSMutableArray *aux = [NSMutableArray array];
		if ([metadata contents] != nil) {
			for (id item in [metadata contents]) {
				if ([item isKindOfClass:[DBMetadata class]]) {
					DBMetadata *itemMetadata = (DBMetadata *)item;
					NSString *itemFilename = [itemMetadata filename];
					[aux addObject:itemFilename];
				}else {
					NSLog (@"Strange : item in contents listing is not of type DBMetadata (class is %@).", [item class]);
				}
			}
		}else {
			NSLog (@"Strange : remote folder contents is not set.");
		}
		return aux;
	}else {
		NSLog (@"ERROR : the entity at path %@ is not a directory.", [metadata path]);
		return nil;
	}
}

#pragma mark - reused operations

- (void) stateTransitionError:(NSString *)eventDescription
{
	NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Event '%@' occurred in unknown state %@ (%d). Switching back to IDLE...", eventDescription, [self stateString], self.state);
	[self setState:IDLE];
}

- (void)reportListDatabaseUidsErrorToDelegate:(NSString *)errorText
{
	[self.delegate dropboxWrapper:self listDatabaseUidsFailedWithError:errorText];
	[self setState:IDLE];
}

- (void)reportDatabaseUploadErrorToDelegate:(NSString *)errorText
{
	[self.delegate dropboxWrapper:self uploadForDatabase:self.databaseUid failedWithError:errorText];
	[self setState:IDLE];
}

- (void)reportAddOptimisticLockErrorToDelegate:(NSString *)errorText
{
	[self.delegate dropboxWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedWithError:errorText];
	[self setState:IDLE];
}

- (void)reportRemoveOptimisticLockErrorToDelegate:(NSString *)errorText
{
	[self.delegate dropboxWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedWithError:errorText];
	[self setState:IDLE];
}

- (void)reportCleanupErrorToDelegate:(NSString *)errorText
{
	[self.delegate dropboxWrapper:self cleanupForDatabase:self.databaseUid failedWithError:errorText];
	[self setState:IDLE];
}

- (void)downloadLockFile
{
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileLocalPath = [TSIOUtils temporaryFileNamed:lockfileName];
	NSString *lockfileRemotePath = [@"/" stringByAppendingString:lockfileName];
	[self.dropboxRestClient loadFile:lockfileRemotePath intoPath:lockfileLocalPath];
}

- (void)deleteLockFile
{
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileRemotePath = [@"/" stringByAppendingString:lockfileName];
	[self.dropboxRestClient deletePath:lockfileRemotePath];
}

- (BOOL)uploadLockFile:(TSDatabaseLock *)databaseLock overwritingRevision:(NSString *)overwrittenRevision
{
	NSData *content = [databaseLock toData];
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileLocalPath = [TSIOUtils temporaryFileNamed:lockfileName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createFileAtPath:lockfileLocalPath contents:content attributes:nil] == YES) {
		[self.dropboxRestClient uploadFile:[lockfileLocalPath lastPathComponent]
									toPath:@"/"
							 withParentRev:overwrittenRevision
								  fromPath:lockfileLocalPath];
		return YES;
	}else {
		NSLog (@"Failed to create local file at %@", lockfileLocalPath);
		return NO;
	}
}

- (void)uploadWriteLock:(NSString *)overwrittenRevision
{
	if ([self.delegate respondsToSelector:@selector(dropboxWrapper:attemptingToLockDatabase:)]) {
		[self.delegate dropboxWrapper:self attemptingToLockDatabase:self.databaseUid];
	}
	TSDatabaseLock *databaseLock = [TSDatabaseLock writeLock];
	if ([self uploadLockFile:databaseLock overwritingRevision:overwrittenRevision] == YES) {
		[self setState:UPLOAD_WRITE_LOCKFILE];
	}else {
		[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile write local)"];
	}
}

- (void)uploadOptimisticLock:(NSString *)overwrittenRevision
{
	TSDatabaseLock *databaseLock = [TSDatabaseLock optimisticLock];
	databaseLock.optimisticLock.comment = self.optimisticLockComment;
	if ([self uploadLockFile:databaseLock overwritingRevision:overwrittenRevision] == YES) {
		[self setState:OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE];
	}else {
		[self reportAddOptimisticLockErrorToDelegate:@"Internal error (lockfile write local)"];
	}
}

- (void)uploadCleanupLock
{
	if ([self.delegate respondsToSelector:@selector(dropboxWrapper:attemptingToLockDatabase:)]) {
		[self.delegate dropboxWrapper:self attemptingToLockDatabase:self.databaseUid];
	}
	TSDatabaseLock *databaseLock = [TSDatabaseLock writeLock];
	databaseLock.writeLock.comment = @"Cleaning up...";
	if ([self uploadLockFile:databaseLock overwritingRevision:nil] == YES) {
		[self setState:CLEANUP_WRITE_LOCKFILE];
	}else {
		[self reportCleanupErrorToDelegate:@"Internal error (lockfile write local)"];
	}
}

- (void)loadBackupsFolderMetadata
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [@"/" stringByAppendingString:backupsFolderName];
	[self.dropboxRestClient loadMetadata:backupsFolderRemotePath];
}

- (void)createBackupsFolder
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [@"/" stringByAppendingString:backupsFolderName];
	[self.dropboxRestClient createFolder:backupsFolderRemotePath];
	[self setState:UPLOAD_CREATE_BACKUP_FOLDER];
}

- (void)checkDatabaseExists
{
	NSString *databaseFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePath = [@"/" stringByAppendingString:databaseFileName];
	[self.dropboxRestClient loadMetadata:databaseRemotePath];
	[self setState:UPLOAD_CHECK_DATABASE_EXISTS];
}

//first operation of 2-step backup
- (void)moveDatabaseToBackup
{
	NSString *databaseFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePathOld = [@"/" stringByAppendingString:databaseFileName];
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	self.remoteBackupId = [TSBackupUtils newBackupId];
	NSString *databaseBackupName = [self.remoteBackupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePathNew = [[@"/" stringByAppendingString:backupsFolderName] stringByAppendingPathComponent:databaseBackupName];
	[self.dropboxRestClient moveFrom:databaseRemotePathOld toPath:databaseRemotePathNew];
	[self setState:UPLOAD_MOVE_DATABASE_TO_BACKUP];
}

- (void)checkMetadataExists
{
	NSString *metadataFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePath = [@"/" stringByAppendingString:metadataFileName];
	[self.dropboxRestClient loadMetadata:metadataRemotePath];
	[self setState:UPLOAD_CHECK_METADATA_EXISTS];
}

//second operation of 2-step backup
- (void)moveMetadataToBackup
{
	NSString *metadataFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePathOld = [@"/" stringByAppendingString:metadataFileName];
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *metadataBackupName = [self.remoteBackupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePathNew = [[@"/" stringByAppendingString:backupsFolderName] stringByAppendingPathComponent:metadataBackupName];
	[self.dropboxRestClient moveFrom:metadataRemotePathOld toPath:metadataRemotePathNew];
	[self setState:UPLOAD_MOVE_METADATA_TO_BACKUP];
}

- (void)uploadMetadata
{
	NSString *metadataFilePath = [TSIOUtils metadataFilePath:self.databaseUid];
	[self.dropboxRestClient uploadFile:[metadataFilePath lastPathComponent]
								toPath:@"/"
						 withParentRev:nil
							  fromPath:metadataFilePath];
	[self setState:UPLOAD_METADATA];
}

- (void)uploadDatabase
{
	NSString *databaseFilePath = [TSIOUtils databaseFilePath:self.databaseUid];
	[self.dropboxRestClient uploadFile:[databaseFilePath lastPathComponent]
								toPath:@"/"
						 withParentRev:nil
							  fromPath:databaseFilePath];
	[self setState:UPLOAD_DATABASE];
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
	NSLog (@"File upload failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
	switch (self.state) {
		case OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE:
			[self reportAddOptimisticLockErrorToDelegate:[error description]];
			break;
			
		case CLEANUP_WRITE_LOCKFILE:
			[self reportCleanupErrorToDelegate:[error description]];
			break;
			
		default:
			[self reportDatabaseUploadErrorToDelegate:[error description]];
			break;
	}
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
    NSLog(@"File uploaded successfully to path: %@", destPath);
	switch (self.state) {
		case UPLOAD_WRITE_LOCKFILE: {
			NSLog (@"Lockfile uploaded successfully, waiting 2 seconds before checking the lockfile");
			[self setState:WAITING];
			[NSThread sleepForTimeInterval:2];
			[self downloadLockFile];
			[self setState:UPLOAD_CHECK_LOCKFILE];
		}
		break;
			
		case UPLOAD_METADATA: {
			if ([self.delegate respondsToSelector:@selector(dropboxWrapper:uploadedMetadataFileForDatabase:)]) {
				[self.delegate dropboxWrapper:self uploadedMetadataFileForDatabase:self.databaseUid];
			}
			[self uploadDatabase];
		}
		break;
			
		case UPLOAD_DATABASE: {
			if ([self.delegate respondsToSelector:@selector(dropboxWrapper:uploadedMainFileForDatabase:)]) {
				[self.delegate dropboxWrapper:self uploadedMainFileForDatabase:self.databaseUid];
			}
			[self deleteLockFile];
			[self setState:UPLOAD_DELETE_LOCKFILE];
		}
		break;
			
		case OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE: {
			[self.delegate dropboxWrapper:self finishedAddingOptimisticLockForDatabase:self.databaseUid];
			[self setState:IDLE];
		}
		break;
			
		case CLEANUP_WRITE_LOCKFILE: {
			NSLog (@"Lockfile uploaded successfully, waiting 2 seconds before checking the lockfile");
			[self setState:WAITING];
			[NSThread sleepForTimeInterval:2];
			[self downloadLockFile];
			[self setState:CLEANUP_CHECK_LOCKFILE];
		}
		break;
			
		default: {
			[self stateTransitionError:@"successful file upload"];
		}
	}
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
	NSLog(@"File download failed :: %@", [error debugDescription]);
	switch (self.state) {
		case UPLOAD_READ_LOCKFILE: {
			if ([error code] == 404) {
				[self uploadWriteLock:nil];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportDatabaseUploadErrorToDelegate:@"Checking lockfile failed."];
			}
		}
		break;
			
		case OPTIMISTIC_LOCK_ADD_READ_LOCKFILE: {
			if ([error code] == 404) {
				[self uploadOptimisticLock:nil];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportAddOptimisticLockErrorToDelegate:@"Checking lockfile failed."];
			}
		}
		break;
			
		case OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE: {
			if ([error code] == 404) {
				NSLog (@"Removal of optimistic lock is actually not needed...");
				[self.delegate dropboxWrapper:self finishedRemovingOptimisticLockForDatabase:self.databaseUid];
				[self setState:IDLE];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportRemoveOptimisticLockErrorToDelegate:@"Checking lockfile failed."];
			}
		}
		break;
			
		case UPLOAD_CHECK_LOCKFILE:
		case UPLOAD_RECHECK_LOCKFILE:
		{
			NSLog (@"!!!REMOTE FILES MAY BE INCONSISTENT!!! Lockfile download failed :: %@", [error debugDescription]);
			[self reportDatabaseUploadErrorToDelegate:@"Failed to check the recently uploaded lockfile!"];
		}
		break;
			
		case CLEANUP_READ_LOCKFILE: {
			if ([error code] == 404) {
				[self uploadCleanupLock];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportCleanupErrorToDelegate:@"Checking lockfile failed."];
			}
		}
		break;
			
		case CLEANUP_CHECK_LOCKFILE:
		{
			NSLog (@"Lockfile download failed :: %@", [error debugDescription]);
			[self reportCleanupErrorToDelegate:@"Failed to check the recently uploaded lockfile!"];
		}
		break;
			
		default: {
			[self stateTransitionError:@"failed file download"];
		}
	}
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata
{
	NSLog(@"File downloaded successfully to path %@", destPath);
	switch (self.state) {
		case UPLOAD_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				if (databaseLock.writeLock != nil) {
					[self.delegate dropboxWrapper:self uploadForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					[self setState:IDLE];
				}else if ((databaseLock.optimisticLock != nil) && ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					[self.delegate dropboxWrapper:self uploadForDatabase:self.databaseUid isStalledBecauseOfOptimisticLock:databaseLock];
					[self setState:UPLOAD_STALLED_OPTIMISTIC_LOCK];
					self.remoteLockfileRevision = metadata.rev;
				}else {
					[self uploadWriteLock:metadata.rev];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;
			
		case OPTIMISTIC_LOCK_ADD_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				if ((databaseLock.optimisticLock == nil) || ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == YES)) {
					if (databaseLock.writeLock == nil) {
						[self uploadOptimisticLock:metadata.rev];
					}else {
						[self.delegate dropboxWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
						[self setState:IDLE];
					}
				}else {
					[self.delegate dropboxWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					[self setState:IDLE];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportAddOptimisticLockErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;
		
		case OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				if ((databaseLock.optimisticLock != nil) && ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == YES)) {
					if (databaseLock.writeLock == nil) {
						[self deleteLockFile];
						[self setState:OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE];
					}else {
						[self.delegate dropboxWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
						[self setState:IDLE];
					}
				}else {
					[self.delegate dropboxWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					[self setState:IDLE];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportRemoveOptimisticLockErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;
						
		case UPLOAD_CHECK_LOCKFILE:
		case UPLOAD_RECHECK_LOCKFILE:
		{
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				if ((databaseLock.writeLock == nil) || ([databaseLock.writeLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					NSLog (@"Lockfile check failed, the lock is not held by the current device");
					[self.delegate dropboxWrapper:self uploadForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					[self setState:IDLE];
				}else {
					if (self.state == UPLOAD_CHECK_LOCKFILE) {
						NSLog (@"Lockfile check ok, waiting a little more then performing a recheck");
						[self setState:WAITING];
						[NSThread sleepForTimeInterval:[TSUtils randomDoubleBetween:1.5 and:4]];
						[self downloadLockFile];
						[self setState:UPLOAD_RECHECK_LOCKFILE];
					}else {
						NSLog (@"Lockfile re-check ok, proceeding with backup");
						if ([self.delegate respondsToSelector:@selector(dropboxWrapper:successfullyLockedDatabase:)]) {
							[self.delegate dropboxWrapper:self successfullyLockedDatabase:self.databaseUid];
						}
						[self loadBackupsFolderMetadata];
						[self setState:UPLOAD_CHECK_BACKUP_FOLDER_EXISTS];
					}
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;
			
		case CLEANUP_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				[self.delegate dropboxWrapper:self cleanupForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
				[self setState:IDLE];
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportCleanupErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;

		case CLEANUP_CHECK_LOCKFILE:
		{
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:destPath];
			if (databaseLock != nil) {
				if ((databaseLock.writeLock == nil) || ([databaseLock.writeLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					NSLog (@"Lockfile check failed, the lock is not held by the current device");
					[self.delegate dropboxWrapper:self cleanupForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					[self setState:IDLE];
				}else {
					[self.dropboxRestClient loadMetadata:@"/"];
					[self setState:CLEANUP_LIST_LOCKFILES];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
		break;
			
		default: {
			[self stateTransitionError:@"successful file download"];
		}
	}
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
	switch (self.state) {
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS: {
			if ([error code] == 404) {
				[self createBackupsFolder];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportDatabaseUploadErrorToDelegate:@"Checking existence of backup folder failed."];
			}
		}
		break;
			
		case UPLOAD_CHECK_DATABASE_EXISTS: {
			if ([error code] == 404) {
				[self checkMetadataExists];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportDatabaseUploadErrorToDelegate:@"Checking existence of database file failed."];
			}
		}
		break;
			
		case UPLOAD_CHECK_METADATA_EXISTS: {
			if ([error code] == 404) {
				[self uploadMetadata];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportDatabaseUploadErrorToDelegate:@"Checking existence of database metadata failed."];
			}
		}
		break;
			
		case LIST_DATABASE_UIDS: {
			NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
				   [self stateString], self.state, [error code], [error domain], [error userInfo]);
			[self reportListDatabaseUidsErrorToDelegate:[error description]];
		}
		break;
			
		case CLEANUP_LIST_LOCKFILES: {
			NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
				   [self stateString], self.state, [error code], [error domain], [error userInfo]);
			[self reportCleanupErrorToDelegate:[error description]];
		}
		break;
			
		case CLEANUP_CHECK_BACKUP_FOLDER_EXISTS: {
			if ([error code] == 404) {
				[self deleteLockFile];
				[self setState:CLEANUP_DELETE_LOCKFILE];
			}else {
				NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
					   [self stateString], self.state, [error code], [error domain], [error userInfo]);
				[self reportCleanupErrorToDelegate:@"Checking existence of backup folder failed."];
			}
		}
		break;
			
		default: {
			NSLog (@"Load metadata failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
			[self reportDatabaseUploadErrorToDelegate:[error description]];
		}
	}
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
	switch (self.state) {
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS: {
			if (([metadata isDirectory] == YES) && ([metadata isDeleted] == NO)) {
				[self checkDatabaseExists];
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a directory.", [metadata path]);
				[self reportDatabaseUploadErrorToDelegate:@"Remote backups folder corrupt???"];
			}
		}
		break;
			
		case UPLOAD_CHECK_DATABASE_EXISTS: {
			if (([metadata isDirectory] == NO) && ([metadata isDeleted] == NO)) {
				[self moveDatabaseToBackup];
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a file.", [metadata path]);
				[self reportDatabaseUploadErrorToDelegate:@"Remote database file corrupt???"];
			}
		}
		break;
			
		case UPLOAD_CHECK_METADATA_EXISTS: {
			if (([metadata isDirectory] == NO) && ([metadata isDeleted] == NO)) {
				[self moveMetadataToBackup];
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a file.", [metadata path]);
				[self reportDatabaseUploadErrorToDelegate:@"Remote metadata file corrupt???"];
			}
		}
		break;
			
		case LIST_DATABASE_UIDS: {
			NSArray *filenames = [self filenameListFromMetadata:metadata];
			if (filenames != nil) {
				NSMutableArray *databaseUids = [NSMutableArray array];
				for (NSString *filename in filenames) {
					if ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_METADATA]) {
						[databaseUids addObject:[filename stringByDeletingPathExtension]];
					}
				}
				[self.delegate dropboxWrapper:self finishedListDatabaseUids:databaseUids];
				[self setState:IDLE];
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a directory.", [metadata path]);
				[self reportListDatabaseUidsErrorToDelegate:@"Remote root folder corrupt???"];
			}
		}
		break;
			
		case CLEANUP_LIST_LOCKFILES: {
			NSArray *filenames = [self filenameListFromMetadata:metadata];
			if (filenames != nil) {
				NSMutableArray *deletedPaths = [NSMutableArray array];
				NSString *realLockfile = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
				for (NSString *filename in filenames) {
					if (([realLockfile isEqualToString:filename] == NO)
							&& ([filename hasPrefix:self.databaseUid])
							&& ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_LOCK])) {
						NSString *path = [@"/" stringByAppendingPathComponent:filename];
						[deletedPaths addObject:path];
					}
				}
				if ([deletedPaths count] > 0) {
					self.toBeDeleted = [deletedPaths copy];
					self.toBeDeletedIndex = 0;
					[self.dropboxRestClient deletePath:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
					[self setState:CLEANUP_DELETE_REDUNDANT_LOCKFILE];
				}else {
					[self loadBackupsFolderMetadata];
					[self setState:CLEANUP_CHECK_BACKUP_FOLDER_EXISTS];
				}
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a directory.", [metadata path]);
				[self reportListDatabaseUidsErrorToDelegate:@"Remote root folder corrupt???"];
			}
		}
		break;
			
		case CLEANUP_CHECK_BACKUP_FOLDER_EXISTS: {
			NSArray *filenames = [self filenameListFromMetadata:metadata];
			if (filenames != nil) {
				NSMutableArray *deletedPaths = [NSMutableArray array];
				NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
				NSString *backupsFolderRemotePath = [@"/" stringByAppendingString:backupsFolderName];
				
				NSArray *retainedFiles = [TSBackupUtils retainOnlyNeededBackups:filenames];
				for (NSString *filename in filenames) {
					if ([retainedFiles containsObject:filename] == NO) {
						NSString *path = [backupsFolderRemotePath stringByAppendingPathComponent:filename];
						[deletedPaths addObject:path];
					}
				}
				if ([deletedPaths count] > 0) {
					self.toBeDeleted = [deletedPaths copy];
					self.toBeDeletedIndex = 0;
					[self.dropboxRestClient deletePath:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
					[self setState:CLEANUP_DELETE_OLD_BACKUP];
				}else {
					[self deleteLockFile];
					[self setState:CLEANUP_DELETE_LOCKFILE];
				}
			}else {
				NSLog (@"ERROR : the entity at path %@ is not a directory.", [metadata path]);
				[self reportCleanupErrorToDelegate:@"Remote backups folder corrupt???"];
			}
		}
		break;
			
		default: {
			[self stateTransitionError:@"loaded metadata"];
		}
	}
}

- (void)restClient:(DBRestClient *)client metadataUnchangedAtPath:(NSString *)path
{
	switch (self.state) {
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS: {
			NSLog (@"Strange but probably correct : received metadata unchanged callback for %@ while checking if the backups folder exists...", path);
			[self checkDatabaseExists];
		}
		break;
			
		case UPLOAD_CHECK_DATABASE_EXISTS: {
			NSLog (@"Strange but probably correct : received metadata unchanged callback for %@ while checking if the database file exists...", path);
			[self moveDatabaseToBackup];
		}
		break;
			
		case UPLOAD_CHECK_METADATA_EXISTS: {
			NSLog (@"Strange but probably correct : received metadata unchanged callback for %@ while checking if the metadata file exists...", path);
			[self moveMetadataToBackup];
		}
		break;
			
		case CLEANUP_CHECK_BACKUP_FOLDER_EXISTS: {
			NSLog (@"Strange and incorrect for cleanup needs : received metadata unchanged callback for %@ while checking if the backups folder exists...", path);
			[self deleteLockFile];
			[self setState:CLEANUP_DELETE_LOCKFILE];
		}
		break;
			
		default: {
			[self stateTransitionError:[NSString stringWithFormat:@"metadata unchanged at path %@", path]];
		}
	}
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
	NSLog (@"Create folder failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
	[self reportDatabaseUploadErrorToDelegate:[error description]];
}

- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
	NSLog (@"Created backups remote folder.");
	[self checkDatabaseExists];
}

- (void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error
{
	NSLog (@"Move operation failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
	[self reportDatabaseUploadErrorToDelegate:[error description]];
}

- (void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result
{
	NSLog (@"Moved %@ to %@", from_path, [result path]);
	switch (self.state) {
		case UPLOAD_MOVE_DATABASE_TO_BACKUP: {
			[self checkMetadataExists];
		}
		break;
			
		case UPLOAD_MOVE_METADATA_TO_BACKUP: {
			NSLog (@"Finished creating backup %@ for database %@", self.remoteBackupId, self.databaseUid);
			if ([self.delegate respondsToSelector:@selector(dropboxWrapper:createdBackup:forDatabase::)]) {
				[self.delegate dropboxWrapper:self createdBackup:self.remoteBackupId forDatabase:self.databaseUid];
			}
			[self uploadMetadata];
		}
		break;
			
		default: {
			[self stateTransitionError:[NSString stringWithFormat:@"moved from %@ to %@", from_path, [result path]]];
		}
	}
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
	switch (self.state) {
		case UPLOAD_DELETE_LOCKFILE: {
			NSLog (@"Delete failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
			[self reportDatabaseUploadErrorToDelegate:[error description]];
		}
		break;
			
		case OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE: {
			NSLog (@"Delete failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
			[self reportRemoveOptimisticLockErrorToDelegate:[error description]];
		}
		break;
			
		case CLEANUP_DELETE_REDUNDANT_LOCKFILE:
		case CLEANUP_DELETE_OLD_BACKUP:
		case CLEANUP_DELETE_LOCKFILE: {
			NSLog (@"Delete failed in state %@ (%d) :: %@", [self stateString], self.state, [error debugDescription]);
			[self reportCleanupErrorToDelegate:[error description]];
		}
		break;
			
		default: {
			[self stateTransitionError:[NSString stringWithFormat:@"delete failed :: %@", [error debugDescription]]];
		}
	}
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
	switch (self.state) {
		case UPLOAD_DELETE_LOCKFILE: {
			if ([self.delegate respondsToSelector:@selector(dropboxWrapper:successfullyUnockedDatabase:)]) {
				[self.delegate dropboxWrapper:self successfullyUnockedDatabase:self.databaseUid];
			}
			[self setState:IDLE];
			[self.delegate dropboxWrapper:self finishedUploadingDatabase:self.databaseUid];
		}
		break;
			
		case OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE: {
			[self setState:IDLE];
			[self.delegate dropboxWrapper:self finishedRemovingOptimisticLockForDatabase:self.databaseUid];
		}
		break;
			
		case CLEANUP_DELETE_REDUNDANT_LOCKFILE:
		case CLEANUP_DELETE_OLD_BACKUP: {
			if ([self.delegate respondsToSelector:@selector(dropboxWrapper:cleanupDeletedFile:)]) {
				[self.delegate dropboxWrapper:self cleanupDeletedFile:path];
			}
			self.toBeDeletedIndex = self.toBeDeletedIndex + 1;
			if (self.toBeDeletedIndex < [self.toBeDeleted count]) {
				[self.dropboxRestClient deletePath:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
			}else {
				if (self.state == CLEANUP_DELETE_REDUNDANT_LOCKFILE) {
					[self loadBackupsFolderMetadata];
					[self setState:CLEANUP_CHECK_BACKUP_FOLDER_EXISTS];
				}else {
					[self deleteLockFile];
					[self setState:CLEANUP_DELETE_LOCKFILE];
				}
			}
		}
		break;
			
		case CLEANUP_DELETE_LOCKFILE: {
			[self setState:IDLE];
			[self.delegate dropboxWrapper:self finishedCleanupForDatabase:self.databaseUid];
		}
		break;
			
		default: {
			[self stateTransitionError:[NSString stringWithFormat:@"deleted path %@", path]];
		}
	}
}

#pragma mark - public API

- (BOOL)busy
{
	return (self.state != IDLE);
}

- (BOOL)uploadStalledOptimisticLock
{
	return (self.state == UPLOAD_STALLED_OPTIMISTIC_LOCK);
}

- (BOOL)listDatabaseUids
{
	BOOL ret = NO;
	/*
	 NOTE on dispatch_async :: for some obscure reason, something deadlocks if the
	 call to the dropbox lib is not done from the main thread (looks like NSUrl_something),
	 so as a precaution, the first invocation of a rest client method is re-scheduled
	 for the main thread to protect against outside world calling this wrapper from other threads.
	 */
	if (self.state == IDLE) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.dropboxRestClient loadMetadata:@"/"];
		});
		[self setState:LIST_DATABASE_UIDS];
	}
	return ret;
}

- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid
{
	//	NSLog (@"database uid : %@", databaseUid);
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadLockFile];
		});
		[self setState:UPLOAD_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

- (BOOL)continueUploadAndOverwriteOptimisticLock
{
	switch (self.state) {
		case UPLOAD_STALLED_OPTIMISTIC_LOCK: {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self uploadWriteLock:self.remoteLockfileRevision];
			});
			return YES;
		}
		default:
			NSLog (@"Received continue upload and overwrite optimistic lock permission but the current state %@ (%d) is not the correct one %@ (%d)", [self stateString], self.state, [TSDropboxWrapper stateString:UPLOAD_STALLED_OPTIMISTIC_LOCK], UPLOAD_STALLED_OPTIMISTIC_LOCK);
			return NO;
	}
}

- (BOOL)cancelUpload
{
	switch (self.state) {
		case UPLOAD_STALLED_OPTIMISTIC_LOCK:
//		case BLA_BLA:
			[self setState:IDLE];
			return YES;
		default:
			NSLog (@"Received cancel upload request but the current state %@ (%d) is not among the states that support this operation", [self stateString], self.state);
			return NO;
	}
}

- (BOOL)addOptimisticLockForDatabase:(NSString *)databaseUid comment:(NSString *)comment
{
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		self.optimisticLockComment = comment;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadLockFile];
		});
		[self setState:OPTIMISTIC_LOCK_ADD_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

- (BOOL)removeOptimisticLockForDatabase:(NSString *)databaseUid
{
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadLockFile];
		});
		[self setState:OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

- (BOOL)cleanupDatabase:(NSString *)databaseUid
{
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadLockFile];
		});
		[self setState:CLEANUP_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

@end
