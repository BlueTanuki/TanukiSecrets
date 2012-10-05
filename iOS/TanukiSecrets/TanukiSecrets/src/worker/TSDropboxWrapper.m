//
//  TSDropboxWrapper.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDropboxWrapper.h"

#import "TSStringUtils.h"

@interface TSDropboxWrapper()

@property(nonatomic, strong) DBRestClient *dropboxRestClient;

@property(nonatomic, copy) NSString *fileLocalPath;
@property(nonatomic, copy) NSString *fileRemotePath;
@property(nonatomic, copy) NSString *fileRemotePath2;

@end

@implementation TSDropboxWrapper

@synthesize dropboxRestClient = _dropboxRestClient, delegate = _delegate,
operation = _operation,
fileLocalPath = _fileLocalPath, fileRemotePath = _fileRemotePath, fileRemotePath2 = _fileRemotePath2;

#pragma mark - getter/setter override

- (DBRestClient *)dropboxRestClient
{
	if ([[DBSession sharedSession] isLinked] == NO) {
		NSLog (@"Dropbox session is not linked!");
		return nil;
	}
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

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
	switch (self.operation) {
		case UPLOAD_FILE:
			[self.delegate uploadedFile:srcPath to:destPath];
			break;
			
		default:
			NSLog (@"WARNING : received successful upload callback (source: %@, destination: %@) during unexpected operation (%d)",
				   srcPath, destPath, self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
	switch (self.operation) {
		case UPLOAD_FILE:
			[self.delegate uploadFile:self.fileLocalPath failedWithError:error];
			break;
			
		default:
			NSLog (@"WARNING : received failed upload callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata
{
	switch (self.operation) {
		case DOWNLOAD_FILE:
			[self.delegate downloadedFile:self.fileRemotePath havingRevision:metadata.rev to:destPath];
			break;
			
		default:
			NSLog (@"WARNING : received successful download callback (source: %@, destination: %@) during unexpected operation (%d)",
				   self.fileRemotePath, destPath, self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
	switch (self.operation) {
		case DOWNLOAD_FILE:
			[self.delegate downloadFile:self.fileRemotePath failedWithError:error];
			break;
			
		default:
			NSLog (@"WARNING : received failed download callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
	switch (self.operation) {
		case LIST_FILES: {
			NSArray *filenames = [self filenameListFromMetadata:metadata];
			if (filenames != nil) {
				[self.delegate listFilesInFolder:self.fileRemotePath finished:filenames];
			}else {
				[self.delegate listFilesInFolder:self.fileRemotePath failedWithError:[TSStringUtils simpleError:@"Could not build the list with the folder contents. Is it really a folder?"]];
			}
		}
			break;
			
		case ITEM_EXISTS: 
			if ([metadata isDeleted] == YES) {
				[self.delegate itemAtPath:self.fileRemotePath exists:NO andIsFolder:[metadata isDirectory]];
			}else {
				[self.delegate itemAtPath:self.fileRemotePath exists:YES andIsFolder:[metadata isDirectory]];
			}
			break;
			
		default:
			NSLog (@"WARNING : received successful load metadata callback (source: %@) during unexpected operation (%d)",
				   self.fileRemotePath, self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
	switch (self.operation) {
		case LIST_FILES:
			[self.delegate listFilesInFolder:self.fileRemotePath failedWithError:error];
			break;
			
		case ITEM_EXISTS:
			if ([error code] == 404) {
				[self.delegate itemAtPath:self.fileRemotePath exists:NO andIsFolder:NO];
			}else {
				[self.delegate itemExistsAtPath:self.fileRemotePath failedWithError:error];
			}
			break;
			
		default:
			NSLog (@"WARNING : received failed load metadata callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
	switch (self.operation) {
		case CREATE_FOLDER:
			[self.delegate createdFolder:[folder path]];
			break;
			
		default:
			NSLog (@"WARNING : received successful folder creation callback (destination: %@) during unexpected operation (%d)",
				   [folder path], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
	switch (self.operation) {
		case CREATE_FOLDER:
			[self.delegate createFolder:self.fileRemotePath failedWithError:error];
			break;
			
		default:
			NSLog (@"WARNING : received failed folder creation callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result
{
	switch (self.operation) {
		case RENAME_FILE:
			[self.delegate renamedFile:from_path as:[result path]];
			break;
			
		default:
			NSLog (@"WARNING : received successful move file callback (oldPath: %@, newPath: %@) during unexpected operation (%d)",
				   from_path, [result path], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error
{
	switch (self.operation) {
		case RENAME_FILE:
			[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:error];
			break;
			
		default:
			NSLog (@"WARNING : received failed move file callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
	switch (self.operation) {
		case DELETE_FILE:
			[self.delegate deletedFile:path];
			break;
			
		case DELETE_FOLDER:
			[self.delegate deletedFolder:path];
			break;
			
		default:
			NSLog (@"WARNING : received successful delete callback (path: %@) during unexpected operation (%d)",
				   path, self.operation);
			break;
	}
//	self.operation = NONE;
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
	switch (self.operation) {
		case DELETE_FILE:
			[self.delegate deleteFile:self.fileRemotePath failedWithError:error];
			break;
			
		case DELETE_FOLDER:
			[self.delegate deleteFolder:self.fileRemotePath failedWithError:error];
			break;
			
		default:
			NSLog (@"WARNING : received failed delete callback (reason: %@) during unexpected operation (%d)",
				   [error debugDescription], self.operation);
			break;
	}
//	self.operation = NONE;
}



#pragma mark - TSRemoteStorage

- (NSString *)rootFolderPath
{
	return @"/";
}

- (void)listFilesInFolder:(NSString *)folderPath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : list files called while another operation (%d) is in progress", self.operation);
//	}
	/*
	 NOTE on dispatch_async :: for some obscure reason, something deadlocks if the
	 call to the dropbox lib is not done from the main thread (looks like NSUrl_something),
	 so as a precaution, the first invocation of a rest client method is re-scheduled
	 for the main thread to protect against outside world calling this wrapper from other threads.
	 */
	self.fileRemotePath = folderPath;
	self.operation = LIST_FILES;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient loadMetadata:folderPath];
	});
}

- (void)itemExistsAtPath:(NSString *)remotePath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : item exists at path called while another operation (%d) is in progress", self.operation);
//	}
	self.fileRemotePath = remotePath;
	self.operation = ITEM_EXISTS;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient loadMetadata:remotePath];
	});
}

- (void)createFolder:(NSString *)folderPath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : create folder called while another operation (%d) is in progress", self.operation);
//	}
	self.fileRemotePath = folderPath;
	self.operation = CREATE_FOLDER;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient createFolder:folderPath];
	});
}

- (void)deleteFolder:(NSString *)folderPath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : delete folder called while another operation (%d) is in progress", self.operation);
//	}
	self.fileRemotePath = folderPath;
	self.operation = DELETE_FOLDER;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient deletePath:folderPath];
	});
}

- (void)downloadFile:(NSString *)fileRemotePath andSaveLocallyAs:(NSString *)fileLocalPath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : download file called while another operation (%d) is in progress", self.operation);
//	}
	self.fileLocalPath = fileLocalPath;
	self.fileRemotePath = fileRemotePath;
	self.operation = DOWNLOAD_FILE;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient loadFile:fileRemotePath intoPath:fileLocalPath];
	});
}

- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath overwritingRevision:(NSString *)revision
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : upload file called while another operation (%d) is in progress", self.operation);
//	}
	self.operation = UPLOAD_FILE;
	self.fileLocalPath = fileLocalPath;
	self.fileRemotePath = fileRemotePath;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient uploadFile:[fileLocalPath lastPathComponent]
									toPath:[fileRemotePath stringByDeletingLastPathComponent]
							 withParentRev:revision
								  fromPath:fileLocalPath];
	});
}

- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath
{
	[self uploadFile:fileLocalPath toRemotePath:fileRemotePath overwritingRevision:nil];
}

- (void)deleteFile:(NSString *)fileRemotePath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : delete file called while another operation (%d) is in progress", self.operation);
//	}
	self.fileRemotePath = fileRemotePath;
	self.operation = DELETE_FILE;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient deletePath:fileRemotePath];
	});
}

- (void)renameFile:(NSString *)oldPath to:(NSString *)newPath
{
//	if (self.operation != NONE) {
//		NSLog (@"WARNING : rename file called while another operation (%d) is in progress", self.operation);
//	}
	self.fileRemotePath = oldPath;
	self.fileRemotePath2 = newPath;
	self.operation = RENAME_FILE;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dropboxRestClient moveFrom:oldPath toPath:newPath];
	});
}

@end
