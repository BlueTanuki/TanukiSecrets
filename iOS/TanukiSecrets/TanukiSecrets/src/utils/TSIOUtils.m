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

@implementation TSIOUtils

+ (NSString *)baseFolderPath
{
	NSURL *ret = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *aux = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	if ([aux count] != 1) {
		NSLog(@"ERROR : wrong number of URLs in array : %d", [aux count]);
	}else {
		ret = [aux objectAtIndex:0];
	}
	return [ret path];
}

+ (NSString *)databaseFilePath:(NSString *)databaseUid
{
	return [[[self baseFolderPath] stringByAppendingPathComponent:databaseUid]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
}

+ (NSString *)metadataFilePath:(NSString *)databaseUid
{
	return [[[self baseFolderPath] stringByAppendingPathComponent:databaseUid]
			stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
}

+ (NSArray *)listLocalFiles
{
	NSMutableArray *ret = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *baseFolderPath = [self baseFolderPath];
	if (baseFolderPath != nil) {
		NSError *error;
		NSArray *files = [fileManager contentsOfDirectoryAtPath:baseFolderPath error:&error];
		if (error) {
			NSLog(@"ERROR :: %@", [error debugDescription]);
		}else {
			ret = [NSMutableArray array];
			for (NSString *filepath in files) {
				[ret addObject:filepath];
			}
		}
	}
	return [ret copy];
}

+ (BOOL)deleteLocalFile:(NSString *)filename
{
	NSLog (@"Delete request for %@", filename);
	NSString *deletedFilePath = [[self baseFolderPath] stringByAppendingPathComponent:[filename lastPathComponent]];
	NSLog (@"Deleted item translated to full path %@", deletedFilePath);
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL ret = NO;
	NSError *error;
	if ([fileManager removeItemAtPath:deletedFilePath error:&error]) {
		if (error) {
			NSLog (@"Could not delete %@ :: %@", deletedFilePath, [error debugDescription]);
		}else {
			ret = YES;
		}
	}else {
		NSLog (@"Could not delete %@", deletedFilePath);
	}
	return ret;
}

+ (NSArray *)listLocalDatabaseUids
{
	NSMutableArray *ret = nil;
	NSArray *files = [self listLocalFiles];
	if (files != nil) {
		ret = [NSMutableArray array];
		for (NSString *filepath in files) {
			NSString *filename = [filepath lastPathComponent];
			if ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_METADATA]) {
				[ret addObject:[filename stringByDeletingPathExtension]];
			}
		}
	}
	return [ret copy];
}

+ (BOOL)deleteLocalDatabase:(NSString *)databaseUid
{
	@throw @"Not implemented";
}

+ (BOOL)saveDatabaseWithMetadata:(TSDatabaseMetadata *)metadata andEncryptedContent:(NSData *)content
{
	if (metadata.lastModifiedBy == nil) {
		metadata.lastModifiedBy = [TSAuthor authorFromCurrentDevice];
	}
	BOOL ret = NO;
	NSString *databaseFilePath = [self databaseFilePath:metadata.uid];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createFileAtPath:databaseFilePath contents:content attributes:nil]) {
		NSString *metadataFilePath = [self metadataFilePath:metadata.uid];
		if ([fileManager createFileAtPath:metadataFilePath contents:[metadata toData] attributes:nil]) {
			ret = YES;
		}else {
			NSLog(@"Failed to write local file for database metadata");
		}
	}else {
		NSLog(@"Failed to write local file for encrypted database");
	}
	return ret;
}

@end
