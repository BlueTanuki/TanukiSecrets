//
//  TSBackupUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/27/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Component that dictates the backup strategy (naming, how many backups are kept).
 Other components will actually perform the backup, but there is one common strategy,
 regardless of where the backups are saved (local filesystem, Dropbox, iCloud)
 
 Note : only the portable files that are synchronized between clients are backed up
 (i.e. the database metadata file and the encrypted database file). Additional 
 local-only files are not backed up (or if they are, they should be kept in a 
 different location). Lock files are of course not backed up.
  */
@interface TSBackupUtils : NSObject

//returns a string identifier for a new backup that will be created now
+ (NSString *)newBackupId;

//name of the folder that will keep all backups for the specified database
+ (NSString *)backupsFolderName:(NSString *)databaseUid;

//file names that should be used for the specified backup
+ (NSString *)databaseBackupFileName:(NSString *)backupId;
+ (NSString *)metadataBackupFileName:(NSString *)backupId;

/**
 Input : a list of all files currently present in the backup folder
 Output : a list of ids of all (consistent) backups, most recent first.
 */
+ (NSArray *)backupIds:(NSArray *)fileNames;

/**
 Input : a list of all files currently present in the backup folder
 Output : a list of files that should still be kept in the backup folder.
 Files that are not in the array returned by this method can be safely deleted.
 
 Note : this method returns only the name of the files, even if the input 
 contained absolute paths.
 */
+ (NSArray *)retainOnlyNeededBackups:(NSArray *)fileNames;

@end
