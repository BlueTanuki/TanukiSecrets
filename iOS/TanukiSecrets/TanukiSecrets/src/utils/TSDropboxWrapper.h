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

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMainFileForDatabase:(NSString *)databaseUid;
- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper failedToUploadForDatabase:(NSString *)databaseUid errorString:(NSString *)error;

@end

typedef enum {
	IDLE,
	UPLOADING_METADATA,
	UPLOADING_DATABASE
} DropboxWrapperState;

/**
 Wrapper for interacting with Dropbox remote storage. 
 */
@interface TSDropboxWrapper : NSObject<DBRestClientDelegate>

@property(nonatomic, assign) BOOL busy;
@property(nonatomic, readonly) DropboxWrapperState state;

///start the upload process for the metadata file and the database file [INCOMPLETE!!!]
///return YES if the command was successfully started (cannot start process if already busy)
- (BOOL)uploadDatabaseWithId:(NSString *)databaseUid andReportToDelegate:(id<TSDropboxUploadDelegate>)delegate;

///TODO :: support for N backups needs to be added somewhere

@end

