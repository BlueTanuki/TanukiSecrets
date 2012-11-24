//
//  TSConstants.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#ifndef TanukiSecrets_TSConstants_h
#define TanukiSecrets_TSConstants_h

#define TS_DEV_DEBUG_ALL 0
#define TS_DEV_DEBUG_SELECTIVE 0

#define TS_INSTANCE_UID_KEY @"TS_INSTANCE_UID_KEY"

#define TS_FILE_SUFFIX_DATABASE @".ts"
#define TS_FILE_SUFFIX_DATABASE_METADATA @".tsm"
#define TS_FILE_SUFFIX_DATABASE_LOCK @".tsl"
#define TS_FILE_SUFFIX_DATABASE_LOCAL_METADATA @".tsml"
#define TS_FILE_SUFFIX_DATABASE_BACKUPS_FOLDER @".bak"

#define TS_NUMBER_OF_LOCAL_BACKUPS 25
#define TS_LOCAL_BACKUPS_AUTOCLEAN_THRESHOLD 41
#define TS_NUMBER_OF_REMOTE_BACKUPS 3

#define TANUKI_HASH_MIN_MEMORY_MB 5
#define TANUKI_HASH_MAX_MEMORY_MB 25
#define TANUKI_HASH_DEFAULT_MEMORY_MB 13

#define TS_NOTIFICATION_DROPBOX_WAS_LINKED @"TSDropboxWasLinkedNotification"
#define TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED @"TSLocalDatabaseListChanged"
#define TS_NOTIFICATION_DATABASE_WAS_UNLOCKED_SUCCESSFULLY @"TSDatabaseWasUnlockedSuccessfully"
#define TS_NOTIFICATION_DATABASE_WAS_LOCKED_SUCCESSFULLY @"TSDatabaseWasLockedSuccessfully"
#define TS_NOTIFICATION_OPEN_DATABASE_CONTENT_CHANGED @"TSOpenDatabaseContentChangedNotification"
#define TS_NOTIFICATION_ITEM_CONTENT_CHANGED @"TSItemContentChangedNotification"

#endif
