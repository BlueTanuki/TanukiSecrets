//
//  TSCryptoUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/31/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSDatabase.h"
#import "TSDatabaseMetadata.h"

@interface TSCryptoUtils : NSObject

#pragma mark - Random data generation

+ (NSData *)randomDataOfLength:(NSInteger)length;
+ (NSData *)randomDataOfVariableLengthMinimum:(NSInteger)min maximum:(NSInteger) max;

#pragma mark - Hashing

+ (NSData *) sha512:(NSData *)bytes;
+ (NSData *) sha512text:(NSString *)string;

+ (NSData *) firstHalfOfSha256:(NSData *)bytes;
+ (NSData *) firstHalfOfSha256text:(NSString *)string;

+ (NSData *) tanukiHash:(NSString *)secret usingSalt:(NSData *)salt consumingMemory:(NSInteger)consumedMB;

//generates the salt and sets the metadata property, returns the key
+ (NSData *) tanukiEncryptKey:(TSDatabaseMetadata *)databaseMetadata usingSecret:(NSString *)secret;
//uses the salt from the metadata to compute and return the key
+ (NSData *) tanukiDecryptKey:(TSDatabaseMetadata *)databaseMetadata usingSecret:(NSString *)secret;

#pragma mark - Encryption

+ (NSData *) aesCbcWithPaddingEncrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv;
+ (NSData *) aesCbcWithPaddingDecrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv;

+ (NSData *) tanukiEncrypt:(NSData *)data usingKey:(NSData *)key andSalt:(NSData *)salt;
+ (NSData *) tanukiDecrypt:(NSData *)data usingKey:(NSData *)key andSalt:(NSData *)salt;

//NOTE: much weaker encryption than the database, uses firstHalfOfSha256(secret) as key
+ (NSString *) tanukiEncryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					  usingSecret:(NSString *)secret;
+ (NSString *) tanukiDecryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					 usingSecret:(NSString *)secret;

///generates salt, computes checksum, returns encrypted database ready to be written to file
+ (NSData *) tanukiEncryptDatabase:(TSDatabase *)database
					havingMetadata:(TSDatabaseMetadata *)databaseMetadata
						  usingKey:(NSData *)key;

+ (TSDatabase *) tanukiDecryptDatabase:(NSData *)encryptedData
						havingMetadata:(TSDatabaseMetadata *)databaseMetadata
							  usingKey:(NSData *)key
						ignoreChecksum:(BOOL)ignoreChecksum;

+ (TSDatabase *) tanukiDecryptDatabase:(NSData *)encryptedData
						havingMetadata:(TSDatabaseMetadata *)databaseMetadata
							  usingKey:(NSData *)key;

@end
