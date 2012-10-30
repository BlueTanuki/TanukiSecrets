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
#import "TSDatabaseLock.h"

@interface TSIOUtils : NSObject

+ (NSString *)localCachesFolder;
//returns the full path of a temporary file with the given name (caller responsible with deletion)
+ (NSString *)temporaryFileNamed:(NSString *)fileName;

+ (BOOL)moveFile:(NSString *)sourcePath to:(NSString *)destinationPath;

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
//cleanup outdated and incomplete backups
+ (BOOL)deleteOldBackupsFor:(NSString *)databaseUid;
//cleanup apparently complete but corrupt backups (i.e. files exist but cannot be read)
//WARNING: this method is dangerous, it may delete perfectly good backups if the secret is not the same for all backups
+ (BOOL)deleteCorruptBackupsFor:(NSString *)databaseUid usingSecret:(NSString *)secret;

/**
 1. encrypts the database
 2. creates a backup copy of the previous version of the database (if needed)
 3. (over)writes the database files [sets a default value for the createdBy if it is nil]
 */
+ (BOOL)saveDatabase:(TSDatabase *)database havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret;
//the preferred way of saving the database, the encrypt key MUST correspond to the current metadata.salt(!!!)
+ (BOOL)saveDatabase:(TSDatabase *)database havingMetadata:(TSDatabaseMetadata *)metadata usingKey:(NSData *)encryptKey;

+ (TSDatabaseMetadata *)loadDatabaseMetadata:(NSString *)databaseUid;
+ (TSDatabaseMetadata *)loadDatabaseMetadataFromFile:(NSString *)filePath;
+ (TSDatabase *)loadDatabase:(NSString *)databaseUid havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret;
//the preferred way of loading the database, the decrypt key MUST correspond to the current metadata.salt(!!!)
+ (TSDatabase *)loadDatabase:(NSString *)databaseUid havingMetadata:(TSDatabaseMetadata *)metadata usingKey:(NSData *)decryptKey;
+ (TSDatabase *)loadDatabaseFromFile:(NSString *)encryptedFilePath havingMetadata:(TSDatabaseMetadata *)metadata usingSecret:(NSString *)secret;
//the preferred way of loading the database, the decrypt key MUST correspond to the current metadata.salt(!!!)
+ (TSDatabase *)loadDatabaseFromFile:(NSString *)encryptedFilePath havingMetadata:(TSDatabaseMetadata *)metadata usingKey:(NSData *)decryptKey;

+ (TSDatabaseLock *)loadDatabaseLockFromFile:(NSString *)filePath;

+ (BOOL)testDatabase:(NSString *)databaseUid usingSecret:(NSString *)secret;
+ (BOOL)testBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid usingSecret:(NSString *)secret;

@end
