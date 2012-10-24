//
//  TSIOUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/18/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSIOUtils.h"

#import "TSConstants.h"
#import "TSCryptoUtils.h"
#import "TSBackupUtils.h"

@interface TSIOUtils ()

+ (NSString *)localBaseFolder;//full path

+ (BOOL)fileAtPath:(NSString*)path hasFileType:(NSString *)fileType;
+ (BOOL)isRegularFile:(NSString *)path;
+ (BOOL)isFolder:(NSString *)path;

+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath;//of NSString, full paths, regular files only
+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath filenameOnly:(BOOL)filenameOnly;

+ (NSArray *)namesOfFilesInDirectory:(NSString *)baseFolderPath
					 thatEndInSuffix:(NSString *)fileSuffix
				 removePathExtension:(BOOL)removePathExtension;

+ (BOOL)createDirectory:(NSString *)path;

+ (BOOL)copyFileFromPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder andRenameTo:(NSString *)newFilename;
+ (BOOL)copyFileWithPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder;//full paths

+ (BOOL)deleteFileOrFolder:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)deleteFile:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath;

+ (BOOL)testMetadataFile:(NSString *)metadataPath andDatabaseFile:(NSString *)databasePath usingSecret:(NSString *)secret;

@end

@implementation TSIOUtils

#pragma mark - generic helper methods

+ (NSString *)localBaseFolder
{
	NSArray *aux = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	if ([aux count] != 1) {
		NSLog(@"ERROR : wrong number of URLs in array : %d :: %@", [aux count], aux);
		return nil;
	}
	return [[aux objectAtIndex:0] path];
}

+ (NSString *)localCachesFolder
{
	NSArray *aux = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	if ([aux count] != 1) {
		NSLog(@"ERROR : wrong number of URLs in array : %d :: %@", [aux count], aux);
		return nil;
	}
	return [[aux objectAtIndex:0] path];
}

+ (NSString *)temporaryFileNamed:(NSString *)fileName
{
	return [[self localCachesFolder] stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileAtPath:(NSString*)path hasFileType:(NSString *)fileType
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path] == NO) {
		return NO;
	}
	NSError *error;
	NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
	if (error != nil) {
		NSLog(@"ERROR :: %@", [error debugDescription]);
		return NO;
	}
	return [[attributes fileType] isEqualToString:fileType];
}

+ (BOOL)isRegularFile:(NSString *)path
{
	return [self fileAtPath:path hasFileType:NSFileTypeRegular];
}

+ (BOOL)isFolder:(NSString *)path
{
	return [self fileAtPath:path hasFileType:NSFileTypeDirectory];
}

+ (BOOL)exists:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:path];
}

+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath filenameOnly:(BOOL)filenameOnly
{
	NSMutableArray *ret = nil;
	if (baseFolderPath != nil) {
		NSError *error;
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseFolderPath error:&error];
		if (error != nil) {
			NSLog(@"ERROR :: %@", [error debugDescription]);
		}else {
//			NSLog (@"contentsOfDirectoryAtPath %@ :: %@", baseFolderPath, files);
			ret = [NSMutableArray array];
			for (NSString *name in files) {
				NSString *path = [baseFolderPath stringByAppendingPathComponent:name];
				if ([self isRegularFile:path]) {
					if (filenameOnly) {
						[ret addObject:[path lastPathComponent]];
					}else {
						[ret addObject:path];
					}
				}
			}
		}
	}
	return [ret copy];
}

+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath
{
	return [self listFilesForDirectory:baseFolderPath filenameOnly:NO];
}

+ (NSArray *)listLocalFiles
{
	return [self listFilesForDirectory:[self localBaseFolder]];
}

+ (NSArray *)namesOfFilesInDirectory:(NSString *)baseFolderPath
					 thatEndInSuffix:(NSString *)fileSuffix
				 removePathExtension:(BOOL)removePathExtension
{
	NSMutableArray *ret = nil;
	NSArray *files = [self listFilesForDirectory:baseFolderPath];
	if (files != nil) {
		ret = [NSMutableArray array];
		for (NSString *filepath in files) {
			NSString *filename = [filepath lastPathComponent];
			if ([filename hasSuffix:fileSuffix]) {
				if (removePathExtension) {
					filename = [filename stringByDeletingPathExtension];
				}
				[ret addObject:filename];
			}
		}
	}
	return [ret copy];
}

+ (BOOL)createDirectory:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory = NO;
	BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	if (exists) {
		return isDirectory;
	}
	NSError *error;
	BOOL created = [fileManager createDirectoryAtPath:path
						  withIntermediateDirectories:YES
										   attributes:nil
												error:&error];
	if (created) {
		return YES;
	}
	NSLog (@"Failed to create folder %@ :: %@", path, [error debugDescription]);
	return NO;
}

+ (BOOL)copyFileFromPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder andRenameTo:(NSString *)newFilename
{
	NSString *destinationPath;
	if (newFilename == nil) {
		destinationPath = [destinationFolder stringByAppendingPathComponent:[sourcePath lastPathComponent]];
	}else {
		destinationPath = [destinationFolder stringByAppendingPathComponent:newFilename];
	}
	
	NSError *error;
	BOOL copied = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
	if (copied) {
//		NSLog (@"Copied file from %@ to %@", sourcePath, destinationPath);
		return YES;
	}
	NSLog (@"Failed to copy from %@ to %@ :: %@", sourcePath, destinationPath, [error debugDescription]);
	return NO;
}

+ (BOOL)copyFileWithPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder
{
	return [self copyFileFromPath:sourcePath toFolder:destinationFolder andRenameTo:nil];
}

+ (BOOL)moveFile:(NSString *)sourcePath to:(NSString *)destinationPath
{
	NSError *error;
	BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destinationPath error:&error];
	if (moved) {
		return YES;
	}
	NSLog (@"Failed to move from %@ to %@ :: %@", sourcePath, destinationPath, [error debugDescription]);
	return NO;
}

+ (BOOL)deleteFileOrFolder:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow
{
	NSString *localFilesPrefix = [self localBaseFolder];
	NSString *localCachesPrefix = [self localCachesFolder];
	BOOL isLocal = [filePath hasPrefix:localFilesPrefix] || [filePath hasPrefix:localCachesPrefix];
	if ((isLocal == NO) && (allow == NO)) {
		NSLog (@"Aborting delete request for non-local file %@", filePath);
		return NO;
	}
	NSError *error;
	BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
	if (deleted) {
		return YES;
	}
	NSLog (@"Failed to delete %@ :: %@", filePath, [error debugDescription]);
	return NO;
}

+ (BOOL)deleteFile:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow
{
	if ([self isRegularFile:filePath] == NO) {
		return NO;
	}
	return [self deleteFileOrFolder:filePath allowDeletionOfNonLocalFiles:allow];
}

+ (BOOL)deleteLocalFile:(NSString *)filePath
{
//	NSLog (@"Delete :: %@", filePath);
	return [self deleteFile:filePath allowDeletionOfNonLocalFiles:NO];
}

+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath allowDeletionOfNonLocalFiles:(BOOL)allow
{
	if ([self exists:folderPath] == NO) {
		return YES;
	}
	if ([self isFolder:folderPath] == NO) {
		return NO;
	}
	return [self deleteFileOrFolder:folderPath allowDeletionOfNonLocalFiles:allow];
}

+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath
{
	return [self recursiveDeleteFolder:folderPath allowDeletionOfNonLocalFiles:NO];
}

#pragma mark - working with databases

+ (NSArray *)listDatabaseUids
{
	return [self namesOfFilesInDirectory:[self localBaseFolder]
						 thatEndInSuffix:TS_FILE_SUFFIX_DATABASE_METADATA
					  removePathExtension:YES];
}

+ (NSString *)databaseFilePath:(NSString *)databaseUid
{
	return [[[self localBaseFolder] stringByAppendingPathComponent:databaseUid]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
}

+ (NSString *)metadataFilePath:(NSString *)databaseUid
{
	return [[[self localBaseFolder] stringByAppendingPathComponent:databaseUid]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
}

+ (BOOL)deleteDatabase:(NSString *)databaseUid
{
	NSString *databaseFilePath = [self databaseFilePath:databaseUid];
	if ([self deleteLocalFile:databaseFilePath]) {
		NSString *metadataFilePath = [self metadataFilePath:databaseUid];
		if ([self deleteLocalFile:metadataFilePath]) {
			NSString *backupsFolder = [self backupsFolderPath:databaseUid];
			if ([self recursiveDeleteFolder:backupsFolder]) {
				return YES;
			}
			NSLog(@"Failed to delete backups folder for database %@", databaseUid);
			return NO;
		}
		NSLog(@"Failed to delete metadata file for database %@", databaseUid);
		return NO;
	}
	NSLog(@"Failed to delete main file for database %@", databaseUid);
	return NO;
}

+ (BOOL)saveDatabaseWithMetadata:(TSDatabaseMetadata *)metadata andEncryptedContent:(NSData *)content
{
	if (metadata.lastModifiedBy == nil) {
		metadata.lastModifiedBy = [TSAuthor authorFromCurrentDevice];
	}
	NSString *databaseFilePath = [self databaseFilePath:metadata.uid];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createFileAtPath:databaseFilePath contents:content attributes:nil] == YES) {
//		NSLog (@"Wrote file %@", databaseFilePath);
		NSString *metadataFilePath = [self metadataFilePath:metadata.uid];
		if ([fileManager createFileAtPath:metadataFilePath contents:[metadata toData] attributes:nil] == YES) {
//			NSLog (@"Wrote file %@", metadataFilePath);
			return YES;
		}
		NSLog(@"Failed to write local file for database metadata");
	}else {
		NSLog(@"Failed to write local file for encrypted database");
	}
	return NO;
}

+ (BOOL)testMetadataFile:(NSString *)metadataPath andDatabaseFile:(NSString *)databasePath usingSecret:(NSString *)secret
{
	TSDatabaseMetadata *metadata = [self loadDatabaseMetadataFromFile:metadataPath];
	if (metadata != nil) {
		TSDatabase *database = [self loadDatabaseFromFile:databasePath havingMetadata:metadata usingSecret:secret];
		if (database != nil) {
			return YES;
		}
	}
	return NO;
}

#pragma mark - database backups

+ (NSString *)backupsFolderPath:(NSString *)databaseUid
{
	NSString *backupsFolderName = [TSBackupUtils backupsFolderName:databaseUid];
	return [[self localBaseFolder] stringByAppendingPathComponent:backupsFolderName];
}

+ (NSArray *)backupIdsForDatabase:(NSString *)databaseUid
{
//	NSLog (@"Listing backups for %@", databaseUid);
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
//	NSLog (@"Backup folder is %@", backupsFolder);
	NSArray *fileNames = [self listFilesForDirectory:backupsFolder filenameOnly:YES];
//	NSLog (@"Found %d files : %@", [fileNames count], fileNames);
	return [TSBackupUtils backupIds:fileNames];
}

+ (NSString *)databaseFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId
{
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	NSString *databaseBackupFilename = [TSBackupUtils databaseBackupFileName:backupId];
	return [backupsFolder stringByAppendingPathComponent:databaseBackupFilename];
}

+ (NSString *)metadataFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId
{
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	NSString *metadataBackupFilename = [TSBackupUtils metadataBackupFileName:backupId];
	return [backupsFolder stringByAppendingPathComponent:metadataBackupFilename];
}

+ (BOOL)createBackupFor:(NSString *)databaseUid
{
	NSString *backupId = [TSBackupUtils newBackupId];
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	if ([self createDirectory:backupsFolder] == NO) {
		NSLog (@"Backup folder cannot be used or could not be created. Aborting backup.");
		return NO;
	}
	
	NSString *databaseFilePath = [self databaseFilePath:databaseUid];
	NSString *databaseBackupFilename = [TSBackupUtils databaseBackupFileName:backupId];
	if ([self copyFileFromPath:databaseFilePath toFolder:backupsFolder andRenameTo:databaseBackupFilename]) {
		NSString *metadataFilePath = [self metadataFilePath:databaseUid];
		NSString *metadataBackupFilename = [TSBackupUtils metadataBackupFileName:backupId];
		if ([self copyFileFromPath:metadataFilePath toFolder:backupsFolder andRenameTo:metadataBackupFilename]) {
			return YES;
		}
		NSLog(@"Failed to create backup %@ for metadata file of database %@", backupId, databaseUid);
	}else {
		NSLog(@"Failed to create backup %@ for main file of database %@", backupId, databaseUid);
	}
	return NO;
}

+ (BOOL)deleteOldBackupsFor:(NSString *)databaseUid
{
//	NSLog (@"Delete old backups called for database %@", databaseUid);
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	NSArray *fileNames = [self listFilesForDirectory:backupsFolder filenameOnly:YES];
//	NSLog (@"Before cleanup : %@", fileNames);
	
	NSArray *retainedFiles = [TSBackupUtils retainOnly: TS_NUMBER_OF_LOCAL_BACKUPS backups:fileNames];
//	NSLog (@"Retained files : %@", retainedFiles);
	for (NSString *filename in fileNames) {
		if ([retainedFiles containsObject:filename] == NO) {
//			NSLog (@"Delete %@", filename);
			if ([self deleteLocalFile:[backupsFolder stringByAppendingPathComponent:filename]] == NO) {
				NSLog (@"Delete %@/%@ failed...", backupsFolder, filename);
				return NO;
			}
		}
	}
	return YES;
}

+ (BOOL)deleteCorruptBackupsFor:(NSString *)databaseUid usingSecret:(NSString *)secret
{
	NSArray *backupIds = [self backupIdsForDatabase:databaseUid];
	NSLog (@"Found %d backups for database %@", [backupIds count], databaseUid);
	for (NSString *backupId in backupIds) {
		NSString *metadataPath = [self metadataFilePath:databaseUid forBackup:backupId];
		NSString *databasePath = [self databaseFilePath:databaseUid forBackup:backupId];
		if ([self isRegularFile:metadataPath] && [self isRegularFile:databasePath]) {
			if ([self testMetadataFile:metadataPath andDatabaseFile:databasePath usingSecret:secret] == NO) {
				NSLog (@"Will delete corrupt backup %@ for database %@", backupId, databaseUid);
				if ([self deleteLocalFile:metadataPath]) {
					if ([self deleteLocalFile:databasePath]) {
						//ok
					}else {
						NSLog (@"Delete database file failed, cleanup aborted.");
						return NO;
					}
				}else {
					NSLog (@"Delete metadata file failed, cleanup aborted.");
					return NO;
				}
			}
		}
	}
	return YES;
}

#pragma mark - complex operations

+ (BOOL)saveDatabase:(TSDatabase *)database havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret
{
	NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:database
													 havingMetadata:metadata
														usingSecret:secret];
	NSString *databaseFilePath = [self databaseFilePath:metadata.uid];
	if ([self isRegularFile:databaseFilePath]) {
//		NSLog (@"Database already exists, will try to create a backup.");
		if ([self createBackupFor:metadata.uid] == NO) {
			NSLog (@"Failed to create backup, aborting save.");
			return NO;
		}
	}else {
//		NSLog (@"Database does not exists, no backup needed.");
	}
	if (metadata.createdBy == nil) {
		metadata.createdBy = [TSAuthor authorFromCurrentDevice];
	}
	return [self saveDatabaseWithMetadata:metadata andEncryptedContent:encryptedContent];
}

+ (TSDatabaseMetadata *)loadDatabaseMetadataFromFile:(NSString *)filePath
{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	if (data != nil) {
		return (TSDatabaseMetadata *)[TSDatabaseMetadata fromData:data];
	}
	NSLog (@"Failed to read content of file %@", filePath);
	return nil;
}

+ (TSDatabaseMetadata *)loadDatabaseMetadata:(NSString *)databaseUid
{
	return [self loadDatabaseMetadataFromFile:[self metadataFilePath:databaseUid]];
}

+ (TSDatabase *)loadDatabaseFromFile:(NSString *)encryptedFilePath havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret
{
	NSData *encryptedData = [NSData dataWithContentsOfFile:encryptedFilePath];
	if (encryptedData == nil) {
		NSLog (@"Failed to read content of file %@", encryptedFilePath);
		return nil;
	}
	return [TSCryptoUtils tanukiDecryptDatabase:encryptedData havingMetadata:metadata usingSecret:secret];
}

+ (TSDatabase *)loadDatabase:(NSString *)databaseUid havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret
{
	return [self loadDatabaseFromFile:[self databaseFilePath:databaseUid] havingMetadata:metadata usingSecret:secret];
}

+ (TSDatabaseLock *)loadDatabaseLockFromFile:(NSString *)filePath
{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	if (data != nil) {
		return (TSDatabaseLock *)[TSDatabaseLock fromData:data];
	}
	NSLog (@"Failed to read content of file %@", filePath);
	return nil;
}

+ (BOOL)testDatabase:(NSString *)databaseUid usingSecret:(NSString *)secret
{
	NSString *metadataPath = [self metadataFilePath:databaseUid];
	NSString *databasePath = [self databaseFilePath:databaseUid];
	return [self isRegularFile:metadataPath] && [self isRegularFile:databasePath] &&
	[self testMetadataFile:metadataPath andDatabaseFile:databasePath usingSecret:secret];
}

+ (BOOL)testBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid usingSecret:(NSString *)secret
{
	NSString *metadataPath = [self metadataFilePath:databaseUid forBackup:backupId];
	NSString *databasePath = [self databaseFilePath:databaseUid forBackup:backupId];
	return [self isRegularFile:metadataPath] && [self isRegularFile:databasePath] &&
	[self testMetadataFile:metadataPath andDatabaseFile:databasePath usingSecret:secret];
}

@end
