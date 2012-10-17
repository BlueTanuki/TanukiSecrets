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

+ (NSData *) md5:(NSData *)bytes;
+ (NSData *) md5text:(NSString *)string;

+ (NSData *) tanukiHash:(NSString *)secret usingSalt:(NSData *)salt consumingMemory:(NSInteger)consumedMB;

#pragma mark - Encryption

+ (NSData *) aesCbcWithPaddingEncrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv;
+ (NSData *) aesCbcWithPaddingDecrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv;

+ (NSData *) tanukiEncrypt:(NSData *)data usingSecret:(NSString *)secret andSalt:(NSData *)salt consumingMemory:(NSInteger)consumedMB;
+ (NSData *) tanukiDecrypt:(NSData *)data usingSecret:(NSString *)secret andSalt:(NSData *)salt consumingMemory:(NSInteger)consumedMB;

+ (NSString *) tanukiEncryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					  usingSecret:(NSString *)secret;
+ (NSString *) tanukiDecryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					 usingSecret:(NSString *)secret;

///generates salt, computes checksum, returns encrypted database ready to be written to file
+ (NSData *) tanukiEncryptDatabase:(TSDatabase *)database
					havingMetadata:(TSDatabaseMetadata *)databaseMetadata
					   usingSecret:(NSString *)secret;

+ (TSDatabase *) tanukiDecryptDatabase:(NSData *)encryptedData
						havingMetadata:(TSDatabaseMetadata *)databaseMetadata
						   usingSecret:(NSString *)secret
						ignoreChecksum:(BOOL)ignoreChecksum;

+ (TSDatabase *) tanukiDecryptDatabase:(NSData *)encryptedData
						havingMetadata:(TSDatabaseMetadata *)databaseMetadata
						   usingSecret:(NSString *)secret;

@end
