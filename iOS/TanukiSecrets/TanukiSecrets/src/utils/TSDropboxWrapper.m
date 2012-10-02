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

- (void)setState:(DropboxWrapperState)newState;

@end

@implementation TSDropboxWrapper

@synthesize state = _state,
dropboxRestClient = _dropboxRestClient, delegate = _delegate,
databaseUid = _databaseUid, remoteLockfileRevision = _remoteLockfileRevision,
remoteBackupId = _remoteBackupId,
optimisticLockComment = _optimisticLockComment;

#pragma mark - state machine helpers

+ (NSString *)stateString:(DropboxWrapperState)state
{
	switch (state) {
		case IDLE:
			return @"IDLE";
		case WAITING:
			return @"WAITING";
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

#pragma mark - reused operations

- (void) stateTransitionError:(NSString *)eventDescription
{
	NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Event '%@' occurred in unknown state %@ (%d). Switching back to IDLE...", eventDescription, [self stateString], self.state);
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

- (void)checkBackupsFolderExists
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [@"/" stringByAppendingString:backupsFolderName];
	[self.dropboxRestClient loadMetadata:backupsFolderRemotePath];
	[self setState:UPLOAD_CHECK_BACKUP_FOLDER_EXISTS];
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
						[self checkBackupsFolderExists];
					}
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
			
		default: {
			[self stateTransitionError:[NSString stringWithFormat:@"deleted path %@", path]];
		}
	}
}

#pragma mark - wrapper methods

- (BOOL)busy
{
	return (self.state != IDLE);
}

- (BOOL)uploadStalledOptimisticLock
{
	return (self.state == UPLOAD_STALLED_OPTIMISTIC_LOCK);
}

- (BOOL)continueUploadAndOverwriteOptimisticLock
{
	switch (self.state) {
		case UPLOAD_STALLED_OPTIMISTIC_LOCK:
			[self uploadWriteLock:self.remoteLockfileRevision];
			return YES;
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

- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid
{
//	NSLog (@"database uid : %@", databaseUid);
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		[self downloadLockFile];
		[self setState:UPLOAD_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

- (BOOL)addOptimisticLockForDatabase:(NSString *)databaseUid comment:(NSString *)comment
{
	BOOL ret = NO;
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		self.optimisticLockComment = comment;
		[self downloadLockFile];
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
		[self downloadLockFile];
		[self setState:OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE];
		ret = YES;
	}
	return ret;
}

@end
