//
//  TSDatabaseMetadata.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSXMLSerializable.h"

/*
 Entity saved in a separate non-encrypted file that accompanies the encrypted
 database. Among other things, this structure holds the random salt used to 
 encrypt the database.
 
 This object is saved to the database.tsm file (local and remote).
 */
@interface TSDatabaseMetadata : NSObject//<TSXMLSerializable>

//id == the filename CANNOT be changed, acts as UID for the database
//name (same as the filename probably, need to decide if the name can be changed)
//description
//
//version
//
//encryption salt
//
//createdBy(authorStructure)
//lastModifiedBy(authorStructure)


@end
