//
//  TSDatabaseWrapper.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/5/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSDatabaseLock.h"
#import "TSRemoteStorage.h"

@class TSDatabaseWrapper;


@protocol TSDatabaseWrapperDelegate <NSObject>

//optional but will cause errors in the logs if not implemented when they actually would be called
@optional
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListDatabaseUids:(NSArray *)databaseUids;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listDatabaseUidsFailedWithError:(NSString *)error;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListBackupIds:(NSArray *)backupIds
			forDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listBackupIdsForDatabase:(NSString *)databaseUid
		failedWithError:(NSString *)error;

//upload database call finished successfully
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedUploadingDatabase:(NSString *)databaseUid;
//generic failure (most likely communication failure with remote servers)
//WARNING : the remote database may be in an inconsistent state (e.g. failure occurred in the middle of uploading the database file)
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
//upload process detected optimistic lock held by another device and requires permission to continue
//after this callback, the upload is paused (state UPLOAD_STALLED_OPTIMISTIC_LOCK)
//the delegate must call either continueUploadAndOverwriteOptimisticLock or cancelUpload
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid isStalledBecauseOfOptimisticLock:(TSDatabaseLock *)databaseLock;
//the upload process failed because somebody else is holding a write lock for the database
//NOTE : nothing has ben uploaded yet, the remote database should be in a consistent state
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedAddingOptimisticLockForDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedRemovingOptimisticLockForDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedCleanupForDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid
failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingDatabase:(NSString *)databaseUid
 andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid
 andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deletedDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

//really optional, safe not to implement even if interested in the use case
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper attemptingToLockDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyLockedDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper createdBackup:(NSString *)backupId forDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMainFileForDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyUnlockedDatabase:(NSString *)databaseUid;
- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupDeletedFile:(NSString *)path;

@end


typedef enum {
	TSDatabaseWrapperState_IDLE,
	TSDatabaseWrapperState_WAITING,
	
	TSDatabaseWrapperState_LIST_DATABASE_UIDS = 50,
	TSDatabaseWrapperState_LIST_BACKUP_IDS,
	
	TSDatabaseWrapperState_UPLOAD_READ_LOCKFILE = 100,
	TSDatabaseWrapperState_UPLOAD_STALLED_OPTIMISTIC_LOCK,
	TSDatabaseWrapperState_UPLOAD_WRITE_LOCKFILE,
	TSDatabaseWrapperState_UPLOAD_CHECK_LOCKFILE,
	TSDatabaseWrapperState_UPLOAD_RECHECK_LOCKFILE,
	TSDatabaseWrapperState_UPLOAD_CHECK_BACKUP_FOLDER_EXISTS,
	TSDatabaseWrapperState_UPLOAD_CREATE_BACKUP_FOLDER,
	TSDatabaseWrapperState_UPLOAD_CHECK_DATABASE_EXISTS,
	TSDatabaseWrapperState_UPLOAD_MOVE_DATABASE_TO_BACKUP,
	TSDatabaseWrapperState_UPLOAD_CHECK_METADATA_EXISTS,
	TSDatabaseWrapperState_UPLOAD_MOVE_METADATA_TO_BACKUP,
	TSDatabaseWrapperState_UPLOAD_METADATA,
	TSDatabaseWrapperState_UPLOAD_DATABASE,
	TSDatabaseWrapperState_UPLOAD_DELETE_LOCKFILE,
	
	TSDatabaseWrapperState_OPTIMISTIC_LOCK_ADD_READ_LOCKFILE = 200,
	TSDatabaseWrapperState_OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE,
	
	TSDatabaseWrapperState_OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE = 250,
	TSDatabaseWrapperState_OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE,
	
	TSDatabaseWrapperState_CLEANUP_READ_LOCKFILE = 300,
	TSDatabaseWrapperState_CLEANUP_WRITE_LOCKFILE,
	TSDatabaseWrapperState_CLEANUP_CHECK_LOCKFILE,
	TSDatabaseWrapperState_CLEANUP_LIST_LOCKFILES,
	TSDatabaseWrapperState_CLEANUP_DELETE_REDUNDANT_LOCKFILE,
	TSDatabaseWrapperState_CLEANUP_CHECK_BACKUP_FOLDER_EXISTS,
	TSDatabaseWrapperState_CLEANUP_DELETE_OLD_BACKUP,
	TSDatabaseWrapperState_CLEANUP_DELETE_LOCKFILE,
	
	TSDatabaseWrapperState_DOWNLOAD_METADATA = 400,
	TSDatabaseWrapperState_DOWNLOAD_DATABASE,
	
	TSDatabaseWrapperState_DELETE_READ_LOCKFILE = 500,
	TSDatabaseWrapperState_DELETE_WRITE_LOCKFILE,
	TSDatabaseWrapperState_DELETE_CHECK_LOCKFILE,
	TSDatabaseWrapperState_DELETE_RECHECK_LOCKFILE,
	TSDatabaseWrapperState_DELETE_CHECK_BACKUP_FOLDER_EXISTS,
	TSDatabaseWrapperState_DELETE_BACKUP_FILE,
	TSDatabaseWrapperState_DELETE_BACKUP_FOLDER,
	TSDatabaseWrapperState_DELETE_DATABASE,
	TSDatabaseWrapperState_DELETE_METADATA,
	TSDatabaseWrapperState_DELETE_LOCKFILE
	
} TSDatabaseWrapperState;

@interface TSDatabaseWrapper : NSObject<TSRemoteStorageDelegate>

@property(nonatomic, weak) id<TSDatabaseWrapperDelegate> delegate;
@property(nonatomic, strong) id<TSRemoteStorage> worker;

@property(nonatomic, readonly) TSDatabaseWrapperState state;

+ (TSDatabaseWrapper *)databaseWrapperWithWorker:(id<TSRemoteStorage>)worker;
// Designated initializer
- (id)initWithWorker:(id<TSRemoteStorage>)worker;

#pragma mark - public API

+ (NSString *)stateString:(TSDatabaseWrapperState)state;
- (NSString *)stateString;

- (BOOL)busy;
- (BOOL)uploadStalledOptimisticLock;

- (BOOL)listDatabaseUids;
- (BOOL)listBackupIdsForDatabase:(NSString *)databaseUid;

///start the upload process for the metadata file and the database file
///return YES if the command was successfully started (cannot start process if already busy)
- (BOOL)uploadDatabaseWithUid:(NSString *)databaseUid;
//confirmation that the upload should proceed (must be in UPLOAD_STALLED_OPTIMISTIC_LOCK) state for this
- (BOOL)continueUploadAndOverwriteOptimisticLock;
//cancel the stalled upload and return to IDLE (only valid in special states)
- (BOOL)cancelUpload;

- (BOOL)addOptimisticLockForDatabase:(NSString *)databaseUid comment:(NSString *)comment;
- (BOOL)removeOptimisticLockForDatabase:(NSString *)databaseUid;

//deletes old backups, removes any extra lock files that may have been created during concurrent locking attempts
- (BOOL)cleanupDatabase:(NSString *)databaseUid;

- (BOOL)downloadDatabase:(NSString *)databaseUid;
- (BOOL)downloadBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid;

//WARNING : highly destructive method
- (BOOL)deleteDatabase:(NSString *)databaseUid;

@end
