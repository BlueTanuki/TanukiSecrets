//
//  TSIOUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/18/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSDatabase.h"
#import "TSDatabaseMetadata.h"

@interface TSIOUtils : NSObject

+ (NSArray *)listDatabaseUids;//of NSString

+ (NSString *)databaseFilePath:(NSString *)databaseUid;
+ (NSString *)metadataFilePath:(NSString *)databaseUid;

+ (NSArray *)listLocalFiles;//of NSString, full paths
+ (BOOL)deleteLocalFile:(NSString *)filePath;

///sets a default value for the lastModified if it is nil, writes database and metadata files to local storage
+ (BOOL)saveDatabaseWithMetadata:(TSDatabaseMetadata *)metadata andEncryptedContent:(NSData *)content;

+ (BOOL)deleteDatabase:(NSString *)databaseUid;

+ (NSString *)backupsFolderPath:(NSString *)databaseUid;
+ (NSArray *)backupIdsForDatabase:(NSString *)databaseUid;//of NSString

+ (NSString *)databaseFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId;
+ (NSString *)metadataFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId;

+ (BOOL)createBackupFor:(NSString *)databaseUid;
+ (BOOL)deleteOldBackupsFor:(NSString *)databaseUid;

/**
 1. encrypts the database
 2. creates a backup copy of the previous version of the database (if needed)
 3. (over)writes the database files [sets a default value for the createdBy if it is nil]
 */
+ (BOOL)saveDatabase:(TSDatabase *)database havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret;

+ (TSDatabaseMetadata *)loadDatabaseMetadataFromFile:(NSString *)filePath;
+ (TSDatabase *)loadDatabaseFromFile:(NSString *)encryptedFilePath havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret;

@end
