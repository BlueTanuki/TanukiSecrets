//
//  TSiCloudWrapper.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSiCloudWrapper.h"

#import "TSStringUtils.h"
#import "TSUIDocument.h"
#import "TSIOUtils.h"

@interface TSiCloudWrapper()

@property(nonatomic, strong) NSURL *iCloudURL;
@property(nonatomic, strong) NSMetadataQuery *iCloudQuery;

@property(nonatomic, copy) NSString *fileLocalPath;
@property(nonatomic, copy) NSString *fileRemotePath;
@property(nonatomic, copy) NSString *fileRemotePath2;

@end

@implementation TSiCloudWrapper

@synthesize delegate = _delegate, operation = _operation,
iCloudURL = _iCloudURL, iCloudQuery = _iCloudQuery,
fileLocalPath = _fileLocalPath, fileRemotePath = _fileRemotePath, fileRemotePath2 = _fileRemotePath2;

- (NSURL *)iCloudURL
{
	if (_iCloudURL == nil) {
		NSLog (@"iCloud storage is not available");
	}
	return _iCloudURL;
}

- (void)refreshUbiquityContainerURL
{
	self.iCloudURL = nil;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSURL *ubiquityContainerURL = [fileManager URLForUbiquityContainerIdentifier:nil];
		if (ubiquityContainerURL != nil) {
			self.iCloudURL = [ubiquityContainerURL URLByAppendingPathComponent:@"Documents"];
		}
	});
}

#pragma mark - misc helper methods

- (void)startCloudQuery
{
	if (self.iCloudQuery == nil) {
		self.iCloudQuery = [[NSMetadataQuery alloc] init];
		self.iCloudQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope];
		self.iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(iCloudFinishedGathering:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:self.iCloudQuery];
		
		[self.iCloudQuery startQuery];
	}
}

- (void)stopCloudQuery
{
	if (self.iCloudQuery != nil) {
		[self.iCloudQuery disableUpdates];
		if ([self.iCloudQuery isStarted]) {
			[self.iCloudQuery stopQuery];
		}
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		self.iCloudQuery = nil;
	}
}

- (void)debugCloudQueryResult:(BOOL)printDetails
{
	NSUInteger resultCount = [self.iCloudQuery resultCount];
	NSLog (@"iCloud query finished gathering : found %d items", resultCount);
	for (int i=0; i<resultCount; i++) {
		NSMetadataItem *item = [self.iCloudQuery resultAtIndex:i];
		if (printDetails) {
			NSLog (@"Item %d...", i);
			NSArray *attributeNames = [item attributes];
			for (NSString *attributeName in attributeNames) {
				NSLog (@"%@ = %@", attributeName, [item valueForAttribute:attributeName]);
			}
		}else {
			NSLog (@"Item %d : %@", i, [item valueForAttribute:NSMetadataItemFSNameKey]);
		}
	}
}

- (NSURL *)urlForRemoteCloudPath:(NSString *)path
{
	return [self.iCloudURL URLByAppendingPathComponent:path];
}

- (NSString *)pathOfItem:(NSString *)absolutePath relativeToBase:(NSString *)basePath
{
	NSString *relativePath;
	if ([absolutePath hasPrefix:basePath]) {
		relativePath = [absolutePath substringFromIndex:[basePath length]];
	}else {
//		NSLog (@"WARNING : the path %@ does not seem to belong to a descendant of %@", absolutePath, basePath);
//		relativePath = absolutePath;
		relativePath = nil;
	}
	return relativePath;
}

- (NSString *)relativePathOfCloudElement:(NSURL *)url
{
	NSString *cloudPath = [self.iCloudURL path];
	NSString *path = [url path];
	return [self pathOfItem:path relativeToBase:cloudPath];
}

- (NSArray *)filenamesOfFirstLevelDescendantsFor:(NSString *)remoteFolder  fromRecursiveListing:(NSArray *)itemURLs
{
	NSURL *baseURL;
	if ((remoteFolder == nil) || ([remoteFolder length] < 1) || ([@"/" isEqualToString:remoteFolder])) {
		baseURL = self.iCloudURL;
	}else {
		baseURL = [self urlForRemoteCloudPath:remoteFolder];
	}
	NSMutableSet *aux = [NSMutableSet set];
	for (NSURL *itemURL in itemURLs) {
		NSString *relativePath = [self pathOfItem:[itemURL path] relativeToBase:[baseURL path]];
		if (relativePath != nil) {
			NSArray *pathComponents = [relativePath pathComponents];
			NSString *filename;
			if ([@"/" isEqualToString:[pathComponents objectAtIndex:0]]) {
				filename = [pathComponents objectAtIndex:1];
			}else {
				filename = [pathComponents objectAtIndex:0];
			}
			[aux addObject:filename];
		}
	}
	return [NSArray arrayWithArray:[aux allObjects]];
}

- (void)deleteItem:(NSString *)remotePath
{
	NSError *error;
	NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	[fileCoordinator coordinateWritingItemAtURL:[self urlForRemoteCloudPath:remotePath]
										options:NSFileCoordinatorWritingForDeleting
										  error:&error
									 byAccessor:^(NSURL* writingURL) {
		 NSFileManager* fileManager = [NSFileManager defaultManager];
		 NSError *error2;
		 BOOL ok = [fileManager removeItemAtURL:writingURL error:&error2];
		 if (ok) {
			 switch (self.operation) {
				 case DELETE_FOLDER:
					 [self.delegate deletedFolder:remotePath];
					 break;
					 
				 case DELETE_FILE:
					 [self.delegate deletedFile:remotePath];
					 break;
					 
				 default:
					 NSLog (@"ERROR : delete of %@ succeeded during unknown operation (%d)", writingURL, self.operation);
					 break;
			 }
		 }else {
			 switch (self.operation) {
				 case DELETE_FOLDER:
					 [self.delegate deleteFolder:remotePath failedWithError:error2];
					 break;
					 
				 case DELETE_FILE:
					 [self.delegate deleteFile:remotePath failedWithError:error2];
					 break;
					 
				 default:
					 NSLog (@"ERROR : delete failed during unknown operation (%d)", self.operation);
					 break;
			 }
		 }
	 }];
	if (error) {
		NSLog (@"Could not delete cloud item %@ (%@) :: %@", remotePath, [self urlForRemoteCloudPath:remotePath], [error debugDescription]);
		switch (self.operation) {
			case DELETE_FOLDER:
				[self.delegate deleteFolder:remotePath failedWithError:error];
				break;
				
			case DELETE_FILE:
				[self.delegate deleteFile:remotePath failedWithError:error];
				break;
				
			default:
				NSLog (@"ERROR : delete failed during unknown operation (%d)", self.operation);
				break;
		}
	}
}

#pragma mark - iCloud callbacks

- (void)iCloudFinishedGathering:(NSNotification *)notification
{
	[self.iCloudQuery disableUpdates];
//	[self debugCloudQueryResult:NO];
	NSUInteger resultCount = [self.iCloudQuery resultCount];
	NSMutableArray *aux = [NSMutableArray arrayWithCapacity:resultCount];
	for (int i=0; i<resultCount; i++) {
		NSMetadataItem *item = [self.iCloudQuery resultAtIndex:i];
		NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
		[aux addObject:itemURL];
	}
	NSArray *itemURLs = [aux copy];
	[self stopCloudQuery];
	
	switch (self.operation) {
		case LIST_FILES: {
			NSArray *filenames = [self filenamesOfFirstLevelDescendantsFor:self.fileRemotePath fromRecursiveListing:itemURLs];
			[self.delegate listFilesInFolder:self.fileRemotePath finished:filenames];
		}
			break;
			
		case ITEM_EXISTS: {
			NSString *path = [[self urlForRemoteCloudPath:self.fileRemotePath] path];
			BOOL isDirectory = NO;
			BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
			[self.delegate itemAtPath:self.fileRemotePath exists:exists andIsFolder:isDirectory];
		}
			break;
			
		case DOWNLOAD_FILE: {
			NSURL *url = [self urlForRemoteCloudPath:self.fileRemotePath];
			BOOL isDirectory;
			BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
			if (exists) {
				if (isDirectory == NO) {
					TSUIDocument *document = [[TSUIDocument alloc] initWithFileURL:url];
					[document openWithCompletionHandler:^(BOOL success) {
						if (success) {
							if ([document saveToLocalFilesystem:self.fileLocalPath]) {
								[self.delegate downloadedFile:self.fileRemotePath to:self.fileLocalPath];
							}else {
								[self.delegate downloadFile:self.fileRemotePath failedWithError:[TSStringUtils simpleError:@"local filesystem write failed"]];
							}
						}else {
							[self.delegate downloadFile:self.fileRemotePath failedWithError:[TSStringUtils simpleError:@"iCloud read failed"]];
						}
						[document closeWithCompletionHandler:nil];
					}];
				}else {
					[self.delegate downloadFile:self.fileRemotePath failedWithError:[TSStringUtils simpleError:@"download file called for folder"]];
				}
			}else {
				[self.delegate downloadFile:self.fileRemotePath failedWithError:[TSStringUtils simpleError:@"file does not exist" withCode:404]];
			}
		}
			break;
			
		case UPLOAD_FILE: {
			NSURL *url = [self urlForRemoteCloudPath:self.fileRemotePath];
			NSString *path = [url path];
			BOOL isDirectory;
			BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
			UIDocumentSaveOperation createOrOverwrite = exists ? UIDocumentSaveForOverwriting : UIDocumentSaveForCreating;
			TSUIDocument *document = [[TSUIDocument alloc] initWithFileURL:url];
			[document loadFromLocalFilesystem:self.fileLocalPath];
			[document saveToURL:document.fileURL
			   forSaveOperation:createOrOverwrite
			  completionHandler:^(BOOL success) {
				  if (success) {
					  // Saving implicitly opens the file. An open document will restore the its (remotely) deleted file representation.
					  [document closeWithCompletionHandler:nil];
					  [self.delegate uploadedFile:self.fileLocalPath to:self.fileRemotePath];
				  }else {
					  NSLog(@"%s error while saving", __PRETTY_FUNCTION__);
					  [self.delegate uploadFile:self.fileLocalPath failedWithError:[TSStringUtils simpleError:@"iCloud problem"]];
				  }
			  }];
		}
			break;
			
		case RENAME_FILE: {
			//not sure how to properly implement this in a single step, so doing it in two steps
			NSURL *oldURL = [self urlForRemoteCloudPath:self.fileRemotePath];
			if ([[NSFileManager defaultManager] fileExistsAtPath:[oldURL path]]) {
				NSString *temporaryLocation = [TSIOUtils temporaryFileNamed:[oldURL lastPathComponent]];
				TSUIDocument *document = [[TSUIDocument alloc] initWithFileURL:oldURL];
				[document openWithCompletionHandler:^(BOOL success) {
					if (success) {
						if ([document saveToLocalFilesystem:temporaryLocation]) {
							[document closeWithCompletionHandler:^(BOOL success) {
								if (success) {
									NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
									NSError *error;
									[fileCoordinator coordinateWritingItemAtURL:oldURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL* writingURL) {
										NSURL *newURL = [self urlForRemoteCloudPath:self.fileRemotePath2];
										BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[newURL path]];
										
										NSString *parentFolderPath = [[newURL path] stringByDeletingLastPathComponent];
										BOOL parentIsDirectory;
										BOOL parentExists = [[NSFileManager defaultManager] fileExistsAtPath:parentFolderPath isDirectory:&parentIsDirectory];
										if (parentExists == NO) {
											[[NSFileManager defaultManager] createDirectoryAtPath:parentFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
										}
										
										UIDocumentSaveOperation createOrOverwrite = exists ? UIDocumentSaveForOverwriting : UIDocumentSaveForCreating;
										TSUIDocument *document = [[TSUIDocument alloc] initWithFileURL:newURL];
										document.tsuiDocData = [NSData dataWithContentsOfFile:temporaryLocation];
										[document saveToURL:document.fileURL
										   forSaveOperation:createOrOverwrite
										  completionHandler:^(BOOL success) {
											  if (success) {
												  // Saving implicitly opens the file. An open document will restore the its (remotely) deleted file representation.
												  [document closeWithCompletionHandler:nil];
												  NSError *error2;
												  BOOL ok = [[NSFileManager defaultManager] removeItemAtURL:writingURL error:&error2];
												  if (ok) {
													  [self.delegate renamedFile:self.fileRemotePath as:self.fileRemotePath2];
												  }else {
													  [self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:error2];
												  }
											  }else {
												  NSLog(@"%s error while saving", __PRETTY_FUNCTION__);
												  [self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:[TSStringUtils simpleError:@"iCloud problem"]];
											  }
										  }];
									}];
									if (error) {
										[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:error];
									}
								}else {
									[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:[TSStringUtils simpleError:@"failed to close source document after opening it for reading"]];
								}
							}];
						}else {
							[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:[TSStringUtils simpleError:@"could not create a local copy of the file"]];
							[document closeWithCompletionHandler:nil];
						}
					}else {
						[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:[TSStringUtils simpleError:@"could not open source for reading"]];
						[document closeWithCompletionHandler:nil];
					}
				}];
			}else {
				[self.delegate renameFile:self.fileRemotePath to:self.fileRemotePath2 failedWithError:[TSStringUtils simpleError:@"source does not exist"]];
			}
		}
			break;
			
		default:
			NSLog (@"ERROR : received iCloudFinishedGathering notification but was not expecting any results (current operation is %d)", self.operation);
			break;
	}
}

#pragma mark - TSRemoteStorage

- (NSString *)rootFolderPath
{
	return @"";
}

- (void)listFilesInFolder:(NSString *)folderPath
{
	/*
	 NOTE on dispatch_async :: NSURLConnections created in async mode cause problems
	 when the method that creates the object is executed from a background thread.
	 (it seems the connection gets freed or something)
	 This pretty much means that the caller has to take care and know to only call
	 such methods from the main thread... ;_;
	 Yet another fuckup from the brilliant minds that decided iPhone does not need
	 upsideDown orientation and thought it is a good idea to disable support for it inside UIViewController.
	 */
	if (self.iCloudQuery == nil) {
		self.fileRemotePath = folderPath;
		self.operation = LIST_FILES;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self startCloudQuery];
		});
	}else {
		NSLog (@"ERROR : cannot start a new iQuery before the previous one finishes.");
		dispatch_async(dispatch_get_current_queue(), ^{
			[self.delegate listFilesInFolder:folderPath failedWithError:[TSStringUtils simpleError:@"another iQuery is still running"]];
		});
	}
}

- (void)itemExistsAtPath:(NSString *)remotePath
{
	if (self.iCloudQuery == nil) {
		self.fileRemotePath = remotePath;
		self.operation = ITEM_EXISTS;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self startCloudQuery];
		});
	}else {
		NSLog (@"ERROR : cannot start a new iQuery before the previous one finishes.");
		dispatch_async(dispatch_get_current_queue(), ^{
			[self.delegate itemExistsAtPath:remotePath failedWithError:[TSStringUtils simpleError:@"another iQuery is still running"]];
		});
	}
}

- (void)createFolder:(NSString *)folderPath
{
	//NOTE : createFolder is NO-OP, folder is automatically created when you upload the first file to it
	dispatch_async(dispatch_get_current_queue(), ^{
		[self.delegate createdFolder:folderPath];
	});
}

- (void)deleteFolder:(NSString *)folderPath
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		self.operation = DELETE_FOLDER;
		[self deleteItem:folderPath];
	});
}

- (void)downloadFile:(NSString *)fileRemotePath andSaveLocallyAs:(NSString *)fileLocalPath
{
	if (self.iCloudQuery == nil) {
		self.fileLocalPath = fileLocalPath;
		self.fileRemotePath = fileRemotePath;
		self.operation = DOWNLOAD_FILE;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self startCloudQuery];
		});
	}else {
		NSLog (@"ERROR : cannot start a new iQuery before the previous one finishes.");
		dispatch_async(dispatch_get_current_queue(), ^{
			[self.delegate downloadFile:fileRemotePath failedWithError:[TSStringUtils simpleError:@"another iQuery is still running"]];
		});
	}
}

- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath overwritingRevision:(NSString *)revision
{
	
	if (self.iCloudQuery == nil) {
		self.fileLocalPath = fileLocalPath;
		self.fileRemotePath = fileRemotePath;
		self.operation = UPLOAD_FILE;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self startCloudQuery];
		});
	}else {
		NSLog (@"ERROR : cannot start a new iQuery before the previous one finishes.");
		dispatch_async(dispatch_get_current_queue(), ^{
			[self.delegate uploadFile:fileLocalPath failedWithError:[TSStringUtils simpleError:@"another iQuery is still running"]];
		});
	}
}

- (void)uploadFile:(NSString *)fileLocalPath toRemotePath:(NSString *)fileRemotePath
{
	[self uploadFile:fileLocalPath toRemotePath:fileRemotePath overwritingRevision:nil];
}

- (void)deleteFile:(NSString *)fileRemotePath
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		self.operation = DELETE_FILE;
		[self deleteItem:fileRemotePath];
	});
}

- (void)renameFile:(NSString *)oldPath to:(NSString *)newPath
{
	if (self.iCloudQuery == nil) {
		self.fileRemotePath = oldPath;
		self.fileRemotePath2 = newPath;
		self.operation = RENAME_FILE;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self startCloudQuery];
		});
	}else {
		NSLog (@"ERROR : cannot start a new iQuery before the previous one finishes.");
		dispatch_async(dispatch_get_current_queue(), ^{
			[self.delegate renameFile:oldPath to:newPath failedWithError:[TSStringUtils simpleError:@"another iQuery is still running"]];
		});
	}
}

@end
