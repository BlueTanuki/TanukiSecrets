//
//  TSRemoteStorage.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/5/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSRemoteStorageDelegate <NSObject>

- (void)listFilesInFolder:(NSString *)folderPath finished:(NSArray *)fileNames;
- (void)listFilesInFolder:(NSString *)folderPath failedWithError:(NSError *)error;

- (void)itemAtPath:(NSString *)path exists:(BOOL)exists andIsFolder:(BOOL)isFolder;
- (void)itemExistsAtPath:(NSString *)path failedWithError:(NSError *)error;

- (void)createdFolder:(NSString *)folderPath;
- (void)createFolder:(NSString *)folderPath failedWithError:(NSError *)error;

- (void)deletedFolder:(NSString *)folderPath;
- (void)deleteFolder:(NSString *)folderPath failedWithError:(NSError *)error;

- (void)downloadedFile:(NSString *)fileRemotePath to:(NSString *)fileLocalPath;
- (void)downloadedFile:(NSString *)fileRemotePath havingRevision:(NSString *)revision to:(NSString *)fileLocalPath;
- (void)downloadFile:(NSString *)fileRemotePath failedWithError:(NSError *)error;

- (void)uploadedFile:(NSString *)fileLocalPath to:(NSString *)fileRemotePath;
- (void)uploadFile:(NSString *)fileLocalPath failedWithError:(NSError *)error;

- (void)deletedFile:(NSString *)fileRemotePath;
- (void)deleteFile:(NSString *)fileRemotePath failedWithError:(NSError *)error;

- (void)renamedFile:(NSString *)oldPath as:(NSString *)newPath;
- (void)renameFile:(NSString *)oldPath to:(NSString *)newPath failedWithError:(NSError *)error;

@end

typedef enum {
//	NONE,
	LIST_FILES,
	ITEM_EXISTS,
	CREATE_FOLDER,
	DELETE_FOLDER,
	DOWNLOAD_FILE,
	UPLOAD_FILE,
	DELETE_FILE,
	RENAME_FILE
} TSRemoteStorageOperation;

@protocol TSRemoteStorage <NSObject>

@property(nonatomic, weak) id<TSRemoteStorageDelegate> delegate;
@property(nonatomic, assign) TSRemoteStorageOperation operation;

- (NSString *)rootFolderPath;

- (void)listFilesInFolder:(NSString *)folderPath;

- (void)itemExistsAtPath:(NSString *)remotePath;

- (void)createFolder:(NSString *)folderPath;

- (void)deleteFolder:(NSString *)folderPath;

- (void)downloadFile:(NSString *)fileRemotePath andSaveLocallyAs:(NSString *)fileLocalPath;

- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath;
- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath overwritingRevision:(NSString *)revision;

- (void)deleteFile:(NSString *)fileRemotePath;

- (void)renameFile:(NSString *)oldPath to:(NSString *)newPath;

@end
