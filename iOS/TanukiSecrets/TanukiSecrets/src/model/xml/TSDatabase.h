//
//  TSDatabase.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSBinarySerializable.h"
#import "TSDBGroup.h"

/*
 Main entity containing the passwords database. When written, this object is
 always encrypted. Unencrypted versions are only allowed in-memory.
 
 This object is saved to the encrypted database.ts file (local and remote).
 */
@interface TSDatabase : NSObject<TSXMLSerializable, TSBinarySerializable>

@property(nonatomic, strong) TSDBGroup *root;

+ (TSDatabase *)databaseWithRoot:(TSDBGroup *)root;

@end
