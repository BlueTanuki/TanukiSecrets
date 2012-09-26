//
//  TSIOUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/18/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSDatabaseMetadata.h"

@interface TSIOUtils : NSObject

+ (NSArray *)listDatabaseUids;//of NSString

+ (NSString *)databaseFilePath:(NSString *)databaseUid;
+ (NSString *)metadataFilePath:(NSString *)databaseUid;

///sets a default value for the lastModified if it is nil, writes database and metadata files to local storage
+ (BOOL)saveDatabaseWithMetadata:(TSDatabaseMetadata *)metadata andEncryptedContent:(NSData *)content;

+ (BOOL)deleteDatabase:(NSString *)databaseUid;

+ (NSArray *)backupIdsForDatabase:(NSString *)databaseUid;//of NSString

+ (NSString *)databaseFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId;
+ (NSString *)metadataFilePath:(NSString *)databaseUid forBackup:(NSString *)backupId;

+ (BOOL)createBackupFor:(NSString *)databaseUid;
+ (void)deleteOldBackupsFor:(NSString *)databaseUid;

@end
