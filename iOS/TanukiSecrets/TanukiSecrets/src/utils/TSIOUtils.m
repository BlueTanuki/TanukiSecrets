//
//  TSIOUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/18/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSIOUtils.h"

#import "TSNotifierUtils.h"
#import "TSConstants.h"

@interface TSIOUtils ()

+ (NSString *)localBaseFolder;//full path

+ (BOOL)fileAtPath:(NSString*)path hasFileType:(NSString *)fileType;
+ (BOOL)isRegularFile:(NSString *)path;
+ (BOOL)isFolder:(NSString *)path;

+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath;//of NSString, full paths, regular files only
+ (NSArray *)listLocalFiles;//of NSString, full paths

+ (NSArray *)namesOfFilesInDirectory:(NSString *)baseFolderPath
					 thatEndInSuffix:(NSString *)filenameSuffix
						removeSuffix:(BOOL)remove;

+ (BOOL)createDirectory:(NSString *)path;

+ (BOOL)copyFileFromPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder andRenameTo:(NSString *)newFilename;
+ (BOOL)copyFileWithPath:(NSString *)sourcePath toFolder:(NSString *)destinationFolder;//full paths

+ (BOOL)moveFile:(NSString *)sourcePath to:(NSString *)destinationPath;

+ (BOOL)deleteFileOrFolder:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)deleteFile:(NSString *)filePath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)deleteFile:(NSString *)filePath;
+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath allowDeletionOfNonLocalFiles:(BOOL)allow;
+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath;

+ (NSString *)backupsFolderPath:(NSString *)databaseUid;
+ (NSString *)newBackupId;

@end

@implementation TSIOUtils

#pragma mark - generic helper methods

+ (NSString *)localBaseFolder
{
	NSArray *aux = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	if ([aux count] != 1) {
		NSLog(@"ERROR : wrong number of URLs in array : %d", [aux count]);
		return nil;
	}
	return [[aux objectAtIndex:0] path];
}

+ (BOOL)fileAtPath:(NSString*)path hasFileType:(NSString *)fileType
{
	NSError *error;
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
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

+ (NSArray *)listFilesForDirectory:(NSString *)baseFolderPath
{
	NSMutableArray *ret = nil;
	if (baseFolderPath != nil) {
		NSError *error;
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseFolderPath error:&error];
		if (error != nil) {
			NSLog(@"ERROR :: %@", [error debugDescription]);
		}else {
			ret = [NSMutableArray array];
			for (NSString *path in files) {
				if ([self isRegularFile:path]) {
					[ret addObject:path];
				}
			}
		}
	}
	return [ret copy];
}

+ (NSArray *)listLocalFiles
{
	return [self listFilesForDirectory:[self localBaseFolder]];
}

+ (NSArray *)namesOfFilesInDirectory:(NSString *)baseFolderPath
					 thatEndInSuffix:(NSString *)filenameSuffix
						removePathExtension:(BOOL)removePathExtension
{
	NSMutableArray *ret = nil;
	NSArray *files = [self listFilesForDirectory:baseFolderPath];
	if (files != nil) {
		ret = [NSMutableArray array];
		for (NSString *filepath in files) {
			NSString *filename = [filepath lastPathComponent];
			if ([filename hasSuffix:filenameSuffix]) {
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
	BOOL isLocal = [filePath hasPrefix:localFilesPrefix];
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

+ (BOOL)deleteFile:(NSString *)filePath
{
	return [self deleteFile:filePath allowDeletionOfNonLocalFiles:NO];
}

+ (BOOL)recursiveDeleteFolder:(NSString *)folderPath allowDeletionOfNonLocalFiles:(BOOL)allow
{
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
	if ([self deleteFile:databaseFilePath]) {
		NSString *metadataFilePath = [self metadataFilePath:databaseUid];
		if ([self deleteFile:metadataFilePath]) {
			NSString *backupsFolder = [self backupsFolderPath:databaseUid];
			if ([self recursiveDeleteFolder:backupsFolder]) {
				return YES;
			}
			NSLog(@"Failed to delete backups folder for database %@", databaseUid);
		}
		NSLog(@"Failed to delete metadata file for database %@", databaseUid);
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
	if ([fileManager createFileAtPath:databaseFilePath contents:content attributes:nil]) {
		NSString *metadataFilePath = [self metadataFilePath:metadata.uid];
		if ([fileManager createFileAtPath:metadataFilePath contents:[metadata toData] attributes:nil]) {
			return YES;
		}
		NSLog(@"Failed to write local file for database metadata");
	}else {
		NSLog(@"Failed to write local file for encrypted database");
	}
	return NO;
}

#pragma mark - database backups

+ (NSString *)backupsFolderPath:(NSString *)databaseUid
{
	return [[self localBaseFolder] stringByAppendingPathComponent:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
}

+ (NSArray *)backupIdsForDatabase:(NSString *)databaseUid
{
	NSArray *aux = [self namesOfFilesInDirectory:[self backupsFolderPath:databaseUid]
								 thatEndInSuffix:TS_FILE_SUFFIX_DATABASE_METADATA
							 removePathExtension:YES];
	return [aux sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

+ (NSString *)databaseFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId
{
	return [[[self backupsFolderPath:databaseUid] stringByAppendingPathComponent:backupId]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
}

+ (NSString *)metadataFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId
{
	return [[[self backupsFolderPath:databaseUid] stringByAppendingPathComponent:backupId]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
}

static NSDateFormatter *backupIdDateFormat = nil;
+ (NSString *)newBackupId
{
	if (backupIdDateFormat == nil) {
		backupIdDateFormat = [[NSDateFormatter alloc] init];
		[backupIdDateFormat setDateFormat:@"yyyyMMdd_HHmmss"];
	}
	return [backupIdDateFormat stringFromDate:[NSDate date]];
}

+ (BOOL)createBackupFor:(NSString *)databaseUid
{
	NSString *backupId = [self newBackupId];
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	
	NSString *databaseFilePath = [self databaseFilePath:databaseUid];
	NSString *databaseBackupName = [backupId stringByAppendingPathExtension:TS_FILE_SUFFIX_DATABASE];
	if ([self copyFileFromPath:databaseFilePath toFolder:backupsFolder andRenameTo:databaseBackupName]) {
		NSString *metadataFilePath = [self metadataFilePath:databaseUid];
		NSString *metadataBackupName = [backupId stringByAppendingPathExtension:TS_FILE_SUFFIX_DATABASE_METADATA];
		if ([self copyFileFromPath:metadataFilePath toFolder:backupsFolder andRenameTo:metadataBackupName]) {
			return YES;
		}
		NSLog(@"Failed to create backup %@ for metadata file of database %@", backupId, databaseUid);
	}else {
		NSLog(@"Failed to create backup %@ for main file of database %@", backupId, databaseUid);
	}
	return NO;
}

+ (void)deleteOldBackupsFor:(NSString *)databaseUid
{
	NSString *backupsFolder = [self backupsFolderPath:databaseUid];
	NSArray *backupIds = [self backupIdsForDatabase:databaseUid];
	if ([backupIds count] > TS_NUMBER_OF_BACKUPS) {
		keep only the most recent backups,
		check for and delete inconsistent backups (that have either meta or data file but not both)
	}
}

@end
