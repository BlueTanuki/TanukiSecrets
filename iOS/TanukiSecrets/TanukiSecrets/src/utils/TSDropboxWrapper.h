//
//  TSDropboxWrapper.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DropboxSDK/DropboxSDK.h>

@class TSDropboxWrapper;

@protocol TSDropboxUploadDelegate <NSObject>

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper finishedUploadingDatabase:(NSString *)databaseUid;

@optional
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMainFileForDatabase:(NSString *)databaseUid;

@end

typedef enum {
	IDLE,
	WAITING,
	
	UPLOAD_READ_LOCKFILE = 100,
	UPLOAD_WRITE_LOCKFILE,
	UPLOAD_CHECK_LOCKFILE,
	UPLOAD_RECHECK_LOCKFILE,
	UPLOAD_CHECK_BACKUP_FOLDER_EXISTS,
	UPLOAD_CREATE_BACKUP_FOLDER,
	UPLOAD_MOVE_DATABASE_TO_BACKUP,
	UPLOAD_MOVE_METADATA_TO_BACKUP,
	UPLOAD_METADATA,
	UPLOAD_DATABASE,
	UPLOAD_DELETE_LOCKFILE
	
} DropboxWrapperState;

/**
 Wrapper for interacting with Dropbox remote storage. 
 */
@interface TSDropboxWrapper : NSObject<DBRestClientDelegate>

@property(nonatomic, assign) BOOL busy;
@property(nonatomic, readonly) DropboxWrapperState state;

///start the upload process for the metadata file and the database file
///return YES if the command was successfully started (cannot start process if already busy)
- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid andReportToDelegate:(id<TSDropboxUploadDelegate>)delegate;

///TODO :: support for N backups needs to be added somewhere

@end

