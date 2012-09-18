//
//  TSDatabaseMetadata.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSVersion.h"
#import "TSAuthor.h"

/*
 Entity saved in a separate non-encrypted file that accompanies the encrypted
 database. Among other things, this structure holds the random salt used to 
 encrypt the database.
 
 This object is saved to the database.tsm file (local and remote).
 */
@interface TSDatabaseMetadata : NSObject<TSXMLSerializable>

@property(nonatomic, strong) NSString *uid;
@property(nonatomic, strong) TSVersion *version;
@property(nonatomic, strong) NSData *salt;

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *description;

@property(nonatomic, strong) TSAuthor *createdBy;
@property(nonatomic, strong) TSAuthor *lastModifiedBy;

+ (TSDatabaseMetadata *)newDatabaseNamed:(NSString *)name;

@end
