//
//  TSLocalMetadata.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSBinarySerializable.h"
#import "TSDBItem.h"

/*
 Entity stored only locally by the client, accompanies one database and is used
 to keep track of merges between different versions and other metadata.
 
 This object is saved to the database.tss file (local only).
 */
@interface TSLocalMetadata : NSObject//<TSXMLSerializable, TSBinarySerializable>

//current version (changes, is always one version ahead of any of the published versions of the database)
//list of versions that are known to be behind the current version (current version is added here when published)
//	-> maybe not all versions are kept, we can forget versions that are >10 behind the current version
//
//list of sync status objects (things implementing a protocol, first iteration will have dropbox and icloud implementations)



@end
