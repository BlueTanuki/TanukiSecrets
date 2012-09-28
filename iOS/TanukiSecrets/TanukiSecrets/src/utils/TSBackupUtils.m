//
//  TSBackupUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/27/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSBackupUtils.h"

#import "TSConstants.h"

@implementation TSBackupUtils

static NSDateFormatter *backupIdDateFormat = nil;
+ (NSString *)newBackupId
{
	if (backupIdDateFormat == nil) {
		backupIdDateFormat = [[NSDateFormatter alloc] init];
		[backupIdDateFormat setDateFormat:@"yyyyMMdd_HHmmss"];
	}
	return [backupIdDateFormat stringFromDate:[NSDate date]];
}

+ (NSString *)backupsFolderName:(NSString *)databaseUid
{
	return [databaseUid stringByAppendingString:TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER];
}

+ (NSString *)databaseBackupFileName:(NSString *)backupId
{
	return [backupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE];
}

+ (NSString *)metadataBackupFileName:(NSString *)backupId
{
	return [backupId stringByAppendingString:TS_FILE_SUFFIX_DATABASE_METADATA];
}

+ (NSArray *)backupIds:(NSArray *)fileNames
{
	NSMutableArray *metadataBackupIds = [NSMutableArray array];
	for (NSString *item in fileNames) {
		NSString *filename = [item lastPathComponent];
		if ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE_METADATA]) {
			NSString *backupId = [filename stringByDeletingPathExtension];
			[metadataBackupIds addObject:backupId];
		}
	}
	NSMutableArray *backupIds = [NSMutableArray array];
	for (NSString *item in fileNames) {
		NSString *filename = [item lastPathComponent];
		if ([filename hasSuffix:TS_FILE_SUFFIX_DATABASE]) {
			NSString *backupId = [filename stringByDeletingPathExtension];
			if ([metadataBackupIds containsObject:backupId]) {
				[backupIds addObject:backupId];
			}
		}
	}
	[backupIds sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSString *str1 = (NSString *)obj1;
		NSString *str2 = (NSString *)obj2;
		return [str2 caseInsensitiveCompare:str1];
	}];
	return [backupIds copy];
}

+ (NSArray *)retainOnlyNeededBackups:(NSArray *)fileNames
{
	NSArray *allBackupIds = [self backupIds:fileNames];
	NSArray *retainedBackupIds = allBackupIds;
	if ([allBackupIds count] > TS_NUMBER_OF_BACKUPS) {
		retainedBackupIds = [allBackupIds subarrayWithRange:NSMakeRange(0, TS_NUMBER_OF_BACKUPS)];
	}
	NSMutableArray *retainedFiles = [NSMutableArray array];
	for (NSString *backupId in retainedBackupIds) {
		[retainedFiles addObject:[self databaseBackupFileName:backupId]];
		[retainedFiles addObject:[self metadataBackupFileName:backupId]];
	}
	return [retainedFiles copy];
}

@end
