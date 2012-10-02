//
//  TSDropboxWrapper.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DropboxSDK/DropboxSDK.h>

#import "TSDatabaseLock.h"

@class TSDropboxWrapper;

@protocol TSDropboxWrapperDelegate <NSObject>

//upload database call finished successfully
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper finishedUploadingDatabase:(NSString *)databaseUid;
//generic failure (most likely communication failure with dropbox servers)
//WARNING : the remote database may be in an inconsistent state (e.g. failure occurred in the middle of uploading the database file)
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
//upload process detected optimistic lock held by another device and requires permission to continue
//after this callback, the upload is paused (state UPLOAD_STALLED_OPTIMISTIC_LOCK)
//the delegate must call either continueUploadAndOverwriteOptimisticLock or cancelUpload
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadForDatabase:(NSString *)databaseUid
isStalledBecauseOfOptimisticLock:(TSDatabaseLock *)databaseLock;
//the upload process failed because somebody else is holding a write lock for the database
//NOTE : nothing has ben uploaded yet, the remote database should be in a consistent state
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadForDatabase:(NSString *)databaseUid
failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper finishedAddingOptimisticLockForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper finishedRemovingOptimisticLockForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock;

@optional
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper attemptingToLockDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper successfullyLockedDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper createdBackup:(NSString *)backupId forDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMainFileForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper successfullyUnockedDatabase:(NSString *)databaseUid;

@end

typedef enum {
	IDLE,
	WAITING,
	
	UPLOAD_READ_LOCKFILE = 100,
	UPLOAD_STALLED_OPTIMISTIC_LOCK,
	UPLOAD_WRITE_LOCKFILE,
	UPLOAD_CHECK_LOCKFILE,
	UPLOAD_RECHECK_LOCKFILE,
	UPLOAD_CHECK_BACKUP_FOLDER_EXISTS,
	UPLOAD_CREATE_BACKUP_FOLDER,
	UPLOAD_CHECK_DATABASE_EXISTS,
	UPLOAD_MOVE_DATABASE_TO_BACKUP,
	UPLOAD_CHECK_METADATA_EXISTS,
	UPLOAD_MOVE_METADATA_TO_BACKUP,
	UPLOAD_METADATA,
	UPLOAD_DATABASE,
	UPLOAD_DELETE_LOCKFILE,
	
	OPTIMISTIC_LOCK_ADD_READ_LOCKFILE = 200,
	OPTIMISTIC_LOCK_ADD_WRITE_LOCKFILE,
	
	OPTIMISTIC_LOCK_REMOVE_READ_LOCKFILE = 250,
	OPTIMISTIC_LOCK_REMOVE_DELETE_LOCKFILE
	
} DropboxWrapperState;

/**
 Wrapper for interacting with Dropbox remote storage. 
 */
@interface TSDropboxWrapper : NSObject<DBRestClientDelegate>

@property(nonatomic, weak) id<TSDropboxWrapperDelegate> delegate;

@property(nonatomic, readonly) DropboxWrapperState state;

+ (NSString *)stateString:(DropboxWrapperState)state;
- (NSString *)stateString;

- (BOOL)busy;
- (BOOL)uploadStalledOptimisticLock;

///start the upload process for the metadata file and the database file
///return YES if the command was successfully started (cannot start process if already busy)
- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid;
//confirmation that the upload should proceed (must be in UPLOAD_STALLED_OPTIMISTIC_LOCK) state for this
- (BOOL)continueUploadAndOverwriteOptimisticLock;
//cancel the stalled upload and return to IDLE (only valid in special states)
- (BOOL)cancelUpload;

- (BOOL)addOptimisticLockForDatabase:(NSString *)databaseUid comment:(NSString *)comment;
- (BOOL)removeOptimisticLockForDatabase:(NSString *)databaseUid;

///TODO :: clean old backups method needed

@end

