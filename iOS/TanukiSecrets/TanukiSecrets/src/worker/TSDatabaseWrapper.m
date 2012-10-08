//
//  TSDatabaseWrapper.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/5/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDatabaseWrapper.h"

#import "TSConstants.h"
#import "TSIOUtils.h"
#import "TSUtils.h"
#import "TSBackupUtils.h"
#import "TSStringUtils.h"
#import "TSSharedState.h"

@interface TSDatabaseWrapper()

@property(nonatomic, copy) NSString *databaseUid;
@property(nonatomic, copy) NSString *remoteBackupId;
@property(nonatomic, copy) NSString *remoteFileRevision;
@property(nonatomic, copy) NSString *optimisticLockComment;

@property(nonatomic, strong) NSArray *toBeDeleted;
@property(nonatomic, assign) NSInteger toBeDeletedIndex;

- (void)setState:(TSDatabaseWrapperState)newState;

@end

@implementation TSDatabaseWrapper

@synthesize delegate = _delegate, worker = _worker,
state = _state, databaseUid = _databaseUid,
remoteBackupId = _remoteBackupId, remoteFileRevision = _remoteFileRevision,
optimisticLockComment = _optimisticLockComment,
toBeDeleted = _toBeDeleted, toBeDeletedIndex = _toBeDeletedIndex;

#pragma mark - initializers

+ (TSDatabaseWrapper *)databaseWrapperWithWorker:(id<TSRemoteStorage>)worker
{
	return [[TSDatabaseWrapper alloc] initWithWorker:worker];
}

- (id)initWithWorker:(id<TSRemoteStorage>)worker
{
	if (self = [super init]) {
		self.worker = worker;
		self.worker.delegate = self;
	}
	return self;
}

#pragma mark - state machine helpers

+ (NSString *)stateString:(TSDatabaseWrapperState)state
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
	return [TSDatabaseWrapper stateString:self.state];
}

- (void)setState:(TSDatabaseWrapperState)newState
{
	NSLog (@"*** STATE TRANSITION :: %@(%d) -> %@(%d)", [self stateString], self.state,
		   [TSDatabaseWrapper stateString:newState], newState);
	_state = newState;
}

- (void) stateTransitionError:(NSString *)eventDescription
{
	NSLog (@"*** INTERNAL STATE MACHINE ERROR *** Event '%@' occurred in unknown state %@ (%d). Switching back to IDLE...", eventDescription, [self stateString], self.state);
	[self setState:IDLE];
}

#pragma mark - misc helper methods

- (NSArray *)namesOfMetadataFilesFromFileList:(NSArray *)filenames
{
	NSMutableArray *ret = [NSMutableArray array];
	for (NSString *filename in filenames) {
		if ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_METADATA]) {
			[ret addObject:[filename stringByDeletingPathExtension]];
		}
	}
	return [ret copy];
}

#pragma mark - reused operations

- (void)reportListDatabaseUidsErrorToDelegate:(NSString *)errorText
{
	[self setState:IDLE];
	[self.delegate databaseWrapper:self listDatabaseUidsFailedWithError:errorText];
}

- (void)reportDatabaseUploadErrorToDelegate:(NSString *)errorText
{
	[self setState:IDLE];
	[self.delegate databaseWrapper:self uploadForDatabase:self.databaseUid failedWithError:errorText];
}

- (void)reportAddOptimisticLockErrorToDelegate:(NSString *)errorText
{
	[self setState:IDLE];
	[self.delegate databaseWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedWithError:errorText];
}

- (void)reportRemoveOptimisticLockErrorToDelegate:(NSString *)errorText
{
	[self setState:IDLE];
	[self.delegate databaseWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedWithError:errorText];
}

- (void)reportCleanupErrorToDelegate:(NSString *)errorText
{
	[self setState:IDLE];
	[self.delegate databaseWrapper:self cleanupForDatabase:self.databaseUid failedWithError:errorText];
}

- (void)downloadLockFile
{
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileLocalPath = [TSIOUtils temporaryFileNamed:lockfileName];
	NSString *lockfileRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:lockfileName];
	[self.worker downloadFile:lockfileRemotePath andSaveLocallyAs:lockfileLocalPath];
}

- (void)deleteLockFile
{
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:lockfileName];
	[self.worker deleteFile:lockfileRemotePath];
}

- (BOOL)uploadLockFile:(TSDatabaseLock *)databaseLock overwritingRevision:(NSString *)overwrittenRevision
{
	NSData *content = [databaseLock toData];
	NSString *lockfileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
	NSString *lockfileLocalPath = [TSIOUtils temporaryFileNamed:lockfileName];
	NSString *lockfileRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:lockfileName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createFileAtPath:lockfileLocalPath contents:content attributes:nil] == YES) {
		[self.worker uploadFile:lockfileLocalPath toRemotePath:lockfileRemotePath overwritingRevision:overwrittenRevision];
		return YES;
	}else {
		NSLog (@"Failed to create local file at %@", lockfileLocalPath);
		return NO;
	}
}

- (void)uploadWriteLock:(NSString *)overwrittenRevision
{
	if ([self.delegate respondsToSelector:@selector(databaseWrapper:attemptingToLockDatabase:)]) {
		[self.delegate databaseWrapper:self attemptingToLockDatabase:self.databaseUid];
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
	if ([self.delegate respondsToSelector:@selector(databaseWrapper:attemptingToLockDatabase:)]) {
		[self.delegate databaseWrapper:self attemptingToLockDatabase:self.databaseUid];
	}
	TSDatabaseLock *databaseLock = [TSDatabaseLock writeLock];
	databaseLock.writeLock.comment = @"Cleaning up...";
	if ([self uploadLockFile:databaseLock overwritingRevision:nil] == YES) {
		[self setState:CLEANUP_WRITE_LOCKFILE];
	}else {
		[self reportCleanupErrorToDelegate:@"Internal error (lockfile write local)"];
	}
}

- (void)listBackupsFolderContent
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName];
	[self.worker listFilesInFolder:backupsFolderRemotePath];
}

- (void)checkBackupsFolderExistence
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName];
	[self.worker itemExistsAtPath:backupsFolderRemotePath];
}

- (void)createBackupsFolder
{
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *backupsFolderRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName];
	[self.worker createFolder:backupsFolderRemotePath];
	[self setState:UPLOAD_CREATE_BACKUP_FOLDER];
}

- (void)checkDatabaseExists
{
	NSString *databaseFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:databaseFileName];
	[self.worker itemExistsAtPath:databaseRemotePath];
	[self setState:UPLOAD_CHECK_DATABASE_EXISTS];
}

//first operation of 2-step backup
- (void)moveDatabaseToBackup
{
	NSString *databaseFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePathOld = [[self.worker rootFolderPath] stringByAppendingPathComponent:databaseFileName];
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	self.remoteBackupId = [TSBackupUtils newBackupId];
	NSString *databaseBackupName = [self.remoteBackupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePathNew = [[[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName] stringByAppendingPathComponent:databaseBackupName];
	[self.worker renameFile:databaseRemotePathOld to:databaseRemotePathNew];
	[self setState:UPLOAD_MOVE_DATABASE_TO_BACKUP];
}

- (void)checkMetadataExists
{
	NSString *metadataFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:metadataFileName];
	[self.worker itemExistsAtPath:metadataRemotePath];
	[self setState:UPLOAD_CHECK_METADATA_EXISTS];
}

//second operation of 2-step backup
- (void)moveMetadataToBackup
{
	NSString *metadataFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePathOld = [[self.worker rootFolderPath] stringByAppendingPathComponent:metadataFileName];
	NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
	NSString *metadataBackupName = [self.remoteBackupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePathNew = [[[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName] stringByAppendingPathComponent:metadataBackupName];
	[self.worker renameFile:metadataRemotePathOld to:metadataRemotePathNew];
	[self setState:UPLOAD_MOVE_METADATA_TO_BACKUP];
}

- (void)uploadMetadata
{
	NSString *metadataFilePath = [TSIOUtils metadataFilePath:self.databaseUid];
	NSString *metadataFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
	NSString *metadataRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:metadataFileName];
	[self.worker uploadFile:metadataFilePath toRemotePath:metadataRemotePath];
	[self setState:UPLOAD_METADATA];
}

- (void)uploadDatabase
{
	NSString *databaseFilePath = [TSIOUtils databaseFilePath:self.databaseUid];
	NSString *databaseFileName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
	NSString *databaseRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:databaseFileName];
	[self.worker uploadFile:databaseFilePath toRemotePath:databaseRemotePath];
	[self setState:UPLOAD_DATABASE];
}

#pragma mark - TSRemoteStorageDelegate

- (void)listFilesInFolder:(NSString *)folderPath finished:(NSArray *)filenames
{
	NSLog (@"List files in folder %@ successful, folder contains %d items", folderPath, [filenames count]);
	switch (self.state) {
		case LIST_DATABASE_UIDS: {
			[self setState:IDLE];
			[self.delegate databaseWrapper:self finishedListDatabaseUids:[self namesOfMetadataFilesFromFileList:filenames]];
		}
			break;
			
		case CLEANUP_LIST_LOCKFILES: {
			NSMutableArray *deletedPaths = [NSMutableArray array];
			NSString *realLockfile = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_LOCK];
			for (NSString *filename in filenames) {
				if (([realLockfile isEqualToString:filename] == NO)
					&& ([filename hasPrefix:self.databaseUid])
					&& ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_LOCK])) {
					NSString *path = [[self.worker rootFolderPath] stringByAppendingPathComponent:filename];
					[deletedPaths addObject:path];
				}
			}
			if ([deletedPaths count] > 0) {
				self.toBeDeleted = [deletedPaths copy];
				self.toBeDeletedIndex = 0;
				[self.worker deleteFile:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
				[self setState:CLEANUP_DELETE_REDUNDANT_LOCKFILE];
			}else {
				[self listBackupsFolderContent];
				[self setState:CLEANUP_CHECK_BACKUP_FOLDER_EXISTS];
			}
		}
			break;
			
		case CLEANUP_CHECK_BACKUP_FOLDER_EXISTS: {
			NSMutableArray *deletedPaths = [NSMutableArray array];
			NSString *backupsFolderName = [self.databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
			NSString *backupsFolderRemotePath = [[self.worker rootFolderPath] stringByAppendingPathComponent:backupsFolderName];
			
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
				[self.worker deleteFile:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
				[self setState:CLEANUP_DELETE_OLD_BACKUP];
			}else {
				[self deleteLockFile];
				[self setState:CLEANUP_DELETE_LOCKFILE];
			}
		}
			break;
			
		default:
			[self stateTransitionError:@"list files"];
			break;
	}
}

- (void)listFilesInFolder:(NSString *)folderPath failedWithError:(NSError *)error
{
	NSLog (@"List files in folder %@ failed, error : %@", folderPath, error);
	switch (self.state) {
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
			
		default:
			[self stateTransitionError:@"failed list files"];
			break;
	}
}

- (void)itemAtPath:(NSString *)path exists:(BOOL)exists andIsFolder:(BOOL)isFolder
{
	NSLog (@"Item at path %@ existence test successful, exists=%d, isFolder=%d", path, exists, isFolder);
	switch (self.state) {
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS: {
			if (exists == YES) {
				if (isFolder == YES) {
					[self checkDatabaseExists];
				}else {
					NSLog (@"ERROR : the entity at path %@ is not a directory.", path);
					[self reportDatabaseUploadErrorToDelegate:@"Remote backups folder corrupt???"];
				}
			}else {
				[self createBackupsFolder];
			}
		}
			break;
			
		case UPLOAD_CHECK_DATABASE_EXISTS: {
			if (exists == YES) {
				if (isFolder == NO) {
					[self moveDatabaseToBackup];
				}else {
					NSLog (@"ERROR : the entity at path %@ is not a file.", path);
					[self reportDatabaseUploadErrorToDelegate:@"Remote database file corrupt???"];
				}
			}else {
				[self checkMetadataExists];
			}
		}
			break;
			
		case UPLOAD_CHECK_METADATA_EXISTS: {
			if (exists == YES) {
				if (isFolder == NO) {
					[self moveMetadataToBackup];
				}else {
					NSLog (@"ERROR : the entity at path %@ is not a file.", path);
					[self reportDatabaseUploadErrorToDelegate:@"Remote metadata file corrupt???"];
				}
			}else {
				[self uploadMetadata];
			}
		}
			break;
			
		default:
			[self stateTransitionError:@"path exists"];
			break;
	}
}

- (void)itemExistsAtPath:(NSString *)path failedWithError:(NSError *)error
{
	NSLog (@"Item at path %@ existence test failed, error : %@", path, error);
	switch (self.state) {
		case UPLOAD_CHECK_BACKUP_FOLDER_EXISTS: {
			NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
				   [self stateString], self.state, [error code], [error domain], [error userInfo]);
			[self reportDatabaseUploadErrorToDelegate:@"Checking existence of backup folder failed."];
		}
			break;
			
		case UPLOAD_CHECK_DATABASE_EXISTS: {
			NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
				   [self stateString], self.state, [error code], [error domain], [error userInfo]);
			[self reportDatabaseUploadErrorToDelegate:@"Checking existence of database file failed."];
		}
			break;
			
		case UPLOAD_CHECK_METADATA_EXISTS: {
			NSLog (@"Unexpected error in state %@ (%d) :: code=%d, domain=%@, info=%@",
				   [self stateString], self.state, [error code], [error domain], [error userInfo]);
			[self reportDatabaseUploadErrorToDelegate:@"Checking existence of database metadata failed."];
		}
			break;
			
		default:
			[self stateTransitionError:@"failed path exists"];
			break;
	}
}

- (void)createdFolder:(NSString *)folderPath
{
	NSLog (@"Create folder %@ successful", folderPath);
	switch (self.state) {
		case UPLOAD_CREATE_BACKUP_FOLDER:
			[self checkDatabaseExists];
			break;
			
		default:
			[self stateTransitionError:@"create folder"];
			break;
	}
}

- (void)createFolder:(NSString *)folderPath failedWithError:(NSError *)error
{
	NSLog (@"Create folder %@ failed, error : %@", folderPath, error);
	switch (self.state) {
		case UPLOAD_CREATE_BACKUP_FOLDER:
			[self reportDatabaseUploadErrorToDelegate:[error description]];
			break;
			
		default:
			[self stateTransitionError:@"failed create folder"];
			break;
	}
}

- (void)deletedFolder:(NSString *)folderPath
{
	NSLog (@"Delete folder %@ successful", folderPath);
	switch (self.state) {
			
		default:
			[self stateTransitionError:@"delete folder"];
			break;
	}
}

- (void)deleteFolder:(NSString *)folderPath failedWithError:(NSError *)error
{
	NSLog (@"Delete folder %@ failed, error : %@", folderPath, error);
	switch (self.state) {
			
		default:
			[self stateTransitionError:@"failed delete folder"];
			break;
	}
}

- (void)downloadedFile:(NSString *)fileRemotePath havingRevision:(NSString *)revision to:(NSString *)fileLocalPath
{
	NSLog (@"Download file %@ successful, has revision %@ and was saved to %@",
		   fileRemotePath, revision, fileLocalPath);
	switch (self.state) {
		case UPLOAD_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				if (databaseLock.writeLock != nil) {
					[self setState:IDLE];
					[self.delegate databaseWrapper:self uploadForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
				}else if ((databaseLock.optimisticLock != nil) && ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					[self setState:UPLOAD_STALLED_OPTIMISTIC_LOCK];
					self.remoteFileRevision = revision;
					[self.delegate databaseWrapper:self uploadForDatabase:self.databaseUid isStalledBecauseOfOptimisticLock:databaseLock];
				}else {
					[self uploadWriteLock:revision];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
			break;
			
		case OPTIMISTIC_LOCK_ADD_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				if ((databaseLock.optimisticLock == nil) || ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == YES)) {
					if (databaseLock.writeLock == nil) {
						[self uploadOptimisticLock:revision];
					}else {
						[self setState:IDLE];
						[self.delegate databaseWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					}
				}else {
					[self setState:IDLE];
					[self.delegate databaseWrapper:self addingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportAddOptimisticLockErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
			break;
			
		case OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE: {
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				if ((databaseLock.optimisticLock != nil) && ([databaseLock.optimisticLock.uid isEqualToString:[TSSharedState instanceUID]] == YES)) {
					if (databaseLock.writeLock == nil) {
						[self deleteLockFile];
						[self setState:OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE];
					}else {
						[self setState:IDLE];
						[self.delegate databaseWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
					}
				}else {
					[self setState:IDLE];
					[self.delegate databaseWrapper:self removingOptimisticLockForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
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
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				if ((databaseLock.writeLock == nil) || ([databaseLock.writeLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					NSLog (@"Lockfile check failed, the lock is not held by the current device");
					[self setState:IDLE];
					[self.delegate databaseWrapper:self uploadForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
				}else {
					if (self.state == UPLOAD_CHECK_LOCKFILE) {
						NSLog (@"Lockfile check ok, waiting a little more then performing a recheck");
						[self setState:WAITING];
						[NSThread sleepForTimeInterval:[TSUtils randomDoubleBetween:1.5 and:4]];
						[self downloadLockFile];
						[self setState:UPLOAD_RECHECK_LOCKFILE];
					}else {
						NSLog (@"Lockfile re-check ok, proceeding with backup");
						if ([self.delegate respondsToSelector:@selector(databaseWrapper:successfullyLockedDatabase:)]) {
							[self.delegate databaseWrapper:self successfullyLockedDatabase:self.databaseUid];
						}
						[self checkBackupsFolderExistence];
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
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				[self setState:IDLE];
				[self.delegate databaseWrapper:self cleanupForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportCleanupErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
			break;
			
		case CLEANUP_CHECK_LOCKFILE:
		{
			TSDatabaseLock *databaseLock = [TSIOUtils loadDatabaseLockFromFile:fileLocalPath];
			if (databaseLock != nil) {
				if ((databaseLock.writeLock == nil) || ([databaseLock.writeLock.uid isEqualToString:[TSSharedState instanceUID]] == NO)) {
					NSLog (@"Lockfile check failed, the lock is not held by the current device");
					[self setState:IDLE];
					[self.delegate databaseWrapper:self cleanupForDatabase:self.databaseUid failedDueToDatabaseLock:databaseLock];
				}else {
					[self.worker listFilesInFolder:[self.worker rootFolderPath]];
					[self setState:CLEANUP_LIST_LOCKFILES];
				}
			}else {
				NSLog (@"*** INTERNAL ERROR : download of lockfile succeeded but the file could not be read correctly!");
				[self reportDatabaseUploadErrorToDelegate:@"Internal error (lockfile read)"];
			}
		}
			break;
			
		default: {
			[self stateTransitionError:@"file download"];
		}
	}
}

- (void)downloadedFile:(NSString *)fileRemotePath to:(NSString *)fileLocalPath
{
	[self downloadedFile:fileRemotePath havingRevision:nil to:fileLocalPath];
}

- (void)downloadFile:(NSString *)fileRemotePath failedWithError:(NSError *)error
{
	NSLog (@"Download file %@ failed, error : %@", fileRemotePath, error);
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
				[self setState:IDLE];
				[self.delegate databaseWrapper:self finishedRemovingOptimisticLockForDatabase:self.databaseUid];
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

- (void)uploadedFile:(NSString *)fileLocalPath to:(NSString *)fileRemotePath
{
	NSLog (@"Upload file %@ successful, remote path is %@", fileLocalPath, fileRemotePath);
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
			if ([self.delegate respondsToSelector:@selector(databaseWrapper:uploadedMetadataFileForDatabase:)]) {
				[self.delegate databaseWrapper:self uploadedMetadataFileForDatabase:self.databaseUid];
			}
			[self uploadDatabase];
		}
			break;
			
		case UPLOAD_DATABASE: {
			if ([self.delegate respondsToSelector:@selector(databaseWrapper:uploadedMainFileForDatabase:)]) {
				[self.delegate databaseWrapper:self uploadedMainFileForDatabase:self.databaseUid];
			}
			[self deleteLockFile];
			[self setState:UPLOAD_DELETE_LOCKFILE];
		}
			break;
			
		case OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE: {
			[self setState:IDLE];
			[self.delegate databaseWrapper:self finishedAddingOptimisticLockForDatabase:self.databaseUid];
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
			
		default: 
			[self stateTransitionError:@"file upload"];
			break;
	}
}

- (void)uploadFile:(NSString *)fileLocalPath failedWithError:(NSError *)error
{
	NSLog (@"Upload file %@ failed, error : %@", fileLocalPath, error);
	switch (self.state) {
		case UPLOAD_WRITE_LOCKFILE:
		case UPLOAD_METADATA:
		case UPLOAD_DATABASE:
			[self reportDatabaseUploadErrorToDelegate:[error description]];
			break;
			
		case OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE:
			[self reportAddOptimisticLockErrorToDelegate:[error description]];
			break;
			
		case CLEANUP_WRITE_LOCKFILE:
			[self reportCleanupErrorToDelegate:[error description]];
			break;
			
		default:
			[self stateTransitionError:@"failed file upload"];
			break;
	}
}

- (void)deletedFile:(NSString *)fileRemotePath
{
	NSLog (@"Delete file %@ successful", fileRemotePath);
	switch (self.state) {
		case UPLOAD_DELETE_LOCKFILE: {
			if ([self.delegate respondsToSelector:@selector(databaseWrapper:successfullyUnlockedDatabase:)]) {
				[self.delegate databaseWrapper:self successfullyUnlockedDatabase:self.databaseUid];
			}
			[self setState:IDLE];
			[self.delegate databaseWrapper:self finishedUploadingDatabase:self.databaseUid];
		}
			break;
			
		case OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE: {
			[self setState:IDLE];
			[self.delegate databaseWrapper:self finishedRemovingOptimisticLockForDatabase:self.databaseUid];
		}
			break;
			
		case CLEANUP_DELETE_REDUNDANT_LOCKFILE:
		case CLEANUP_DELETE_OLD_BACKUP: {
			if ([self.delegate respondsToSelector:@selector(databaseWrapper:cleanupDeletedFile:)]) {
				[self.delegate databaseWrapper:self cleanupDeletedFile:fileRemotePath];
			}
			self.toBeDeletedIndex = self.toBeDeletedIndex + 1;
			if (self.toBeDeletedIndex < [self.toBeDeleted count]) {
				[self.worker deleteFile:[self.toBeDeleted objectAtIndex:self.toBeDeletedIndex]];
			}else {
				if (self.state == CLEANUP_DELETE_REDUNDANT_LOCKFILE) {
					[self listBackupsFolderContent];
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
			[self.delegate databaseWrapper:self finishedCleanupForDatabase:self.databaseUid];
		}
			break;
			
		default:
			[self stateTransitionError:@"delete file"];
			break;
	}
}

- (void)deleteFile:(NSString *)fileRemotePath failedWithError:(NSError *)error
{
	NSLog (@"Delete file %@ failed, error : %@", fileRemotePath, error);
	switch (self.state) {
		case UPLOAD_DELETE_LOCKFILE: 
			[self reportDatabaseUploadErrorToDelegate:[error description]];
			break;
			
		case OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE: 
			[self reportRemoveOptimisticLockErrorToDelegate:[error description]];
			break;
			
		case CLEANUP_DELETE_REDUNDANT_LOCKFILE:
		case CLEANUP_DELETE_OLD_BACKUP:
		case CLEANUP_DELETE_LOCKFILE: 
			[self reportCleanupErrorToDelegate:[error description]];
			break;
			
		default:
			[self stateTransitionError:@"failed delete file"];
			break;
	}
}

- (void)renamedFile:(NSString *)oldPath as:(NSString *)newPath
{
	NSLog (@"Rename file %@ successful, new path is %@", oldPath, newPath);
	switch (self.state) {
		case UPLOAD_MOVE_DATABASE_TO_BACKUP: 
			[self checkMetadataExists];
			break;
			
		case UPLOAD_MOVE_METADATA_TO_BACKUP: {
			NSLog (@"Finished creating backup %@ for database %@", self.remoteBackupId, self.databaseUid);
			if ([self.delegate respondsToSelector:@selector(databaseWrapper:createdBackup:forDatabase::)]) {
				[self.delegate databaseWrapper:self createdBackup:self.remoteBackupId forDatabase:self.databaseUid];
			}
			[self uploadMetadata];
		}
			break;
			
		default:
			[self stateTransitionError:@"rename file"];
			break;
	}
}

- (void)renameFile:(NSString *)oldPath to:(NSString *)newPath failedWithError:(NSError *)error
{
	NSLog (@"Rename file from %@ to %@ failed, error : %@", oldPath, newPath, error);
	switch (self.state) {
		case UPLOAD_MOVE_DATABASE_TO_BACKUP:
		case UPLOAD_MOVE_METADATA_TO_BACKUP: 
			[self reportDatabaseUploadErrorToDelegate:[error description]];
			break;
			
		default:
			[self stateTransitionError:@"rename file"];
			break;
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
	if (self.state == IDLE) {
		[self.worker listFilesInFolder:[self.worker rootFolderPath]];
		[self setState:LIST_DATABASE_UIDS];
		return YES;
	}
	NSLog (@"Rejected listDatabaseUids request, wrapper is not idle (current state is %@ (%d)", [self stateString], self.state);
	return NO;
}

- (BOOL)uploadDatabaseWithUid:(NSString *)databaseUid
{
//	NSLog (@"uploadDatabaseWithUid uid : %@", databaseUid);
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		[self downloadLockFile];
		[self setState:UPLOAD_READ_LOCKFILE];
		return YES;
	}
	NSLog (@"Rejected uploadDatabaseWithUid request, wrapper is not idle (current state is %@ (%d)", [self stateString], self.state);
	return NO;
}

- (BOOL)continueUploadAndOverwriteOptimisticLock
{
	switch (self.state) {
		case UPLOAD_STALLED_OPTIMISTIC_LOCK: {
			[self uploadWriteLock:self.remoteFileRevision];
			return YES;
		}
			
		default:
			NSLog (@"Received continue upload and overwrite optimistic lock permission but the current state %@ (%d) is not the correct one %@ (%d)", [self stateString], self.state, [TSDatabaseWrapper stateString:UPLOAD_STALLED_OPTIMISTIC_LOCK], UPLOAD_STALLED_OPTIMISTIC_LOCK);
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
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		self.optimisticLockComment = comment;
		[self downloadLockFile];
		[self setState:OPTIMISTIC_LOCK_ADD_READ_LOCKFILE];
		return YES;
	}
	NSLog (@"Rejected addOptimisticLockForDatabase request, wrapper is not idle (current state is %@ (%d)", [self stateString], self.state);
	return NO;
}

- (BOOL)removeOptimisticLockForDatabase:(NSString *)databaseUid
{
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		[self downloadLockFile];
		[self setState:OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE];
		return YES;
	}
	NSLog (@"Rejected removeOptimisticLockForDatabase request, wrapper is not idle (current state is %@ (%d)", [self stateString], self.state);
	return NO;
}

- (BOOL)cleanupDatabase:(NSString *)databaseUid
{
	if (self.state == IDLE) {
		self.databaseUid = databaseUid;
		[self downloadLockFile];
		[self setState:CLEANUP_READ_LOCKFILE];
		return YES;
	}
	NSLog (@"Rejected cleanupDatabase request, wrapper is not idle (current state is %@ (%d)", [self stateString], self.state);
	return NO;
}


@end
