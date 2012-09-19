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

+ (NSString *)baseFolderPath;
+ (NSString *)databaseFilePath:(NSString *)databaseUid;
+ (NSString *)metadataFilePath:(NSString *)databaseUid;

+ (NSArray *)listLocalDatabaseIds;//of NSString

///sets a default value for the lastModified if it is nil, writes database and metadata files to local storage
+ (BOOL)saveDatabaseWithMetadata:(TSDatabaseMetadata *)metadata andEncryptedContent:(NSData *)content;

//TODO :: support for N backups needs to be added somewhere

@end
