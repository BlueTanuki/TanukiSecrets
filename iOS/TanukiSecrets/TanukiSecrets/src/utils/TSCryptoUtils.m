//
//  TSCryptoUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/31/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSCryptoUtils.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/Security.h>

#import "TSStringUtils.h"
#import "TSConstants.h"

#define TS_SALT_BYTES_MIN 64
#define TS_SALT_BYTES_MAX 128

@implementation TSCryptoUtils

#pragma mark - Random data generation

+ (NSData *) randomDataOfLength:(NSInteger)length
{
	uint8_t *buf = malloc( length * sizeof(uint8_t) );
	OSStatus sanityCheck = SecRandomCopyBytes(kSecRandomDefault, length, buf);
	NSData *ret = nil;
	if (sanityCheck == noErr) {
		ret = [[NSData alloc] initWithBytes:buf length:length];
	}
	free(buf);
	buf = NULL;
	return ret;
}

+ (NSData *)randomDataOfVariableLengthMinimum:(NSInteger)min maximum:(NSInteger)max
{
	return [self randomDataOfLength:(min + arc4random() % (max - min + 1))];
}

#pragma mark - Hashing

+ (NSData *) sha512:(NSData *) bytes
{
	unsigned char hash[CC_SHA512_DIGEST_LENGTH];
	CC_SHA512([bytes bytes], [bytes length], hash);
	return [NSData dataWithBytes:hash length:CC_SHA512_DIGEST_LENGTH];
}

+ (NSData *) sha512text:(NSString *) string
{
	NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [self sha512:bytes];
}

+ (NSData *)firstHalfOfSha256:(NSData *)bytes
{
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];//32-byte
	CC_SHA256([bytes bytes], [bytes length], hash);
	return [NSData dataWithBytes:hash length:CC_MD5_DIGEST_LENGTH];//16-byte, first half
}

+(NSData *)firstHalfOfSha256text:(NSString *)string
{
	NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [self firstHalfOfSha256:bytes];
}

+ (NSData *) tanukiHashXX:(NSString *) secret usingSalt:(NSData *)salt
{
	unsigned long bufSize = 1024l * 1024 * 13;
	uint8_t *buf = malloc(bufSize * sizeof(uint8_t));
	NSData *secretBytes = [secret dataUsingEncoding:NSUTF8StringEncoding];
	
	//cannot use, all it does is fill the array with zeros
	//it appears it only works for very small sizes (16, 32)
	//for a 13M key, it fails miserably...
//	CCKeyDerivationPBKDF(kCCPBKDF2, [secretBytes bytes], [secretBytes length],
//						 [salt bytes], [salt length],
//						 kCCPRFHmacAlgSHA1, 100,
//						 buf, bufSize);
	CC_SHA512([secretBytes bytes], [secretBytes length], buf);
	CC_SHA512([salt bytes], [salt length], buf + CC_SHA512_DIGEST_LENGTH);
	unsigned long n = bufSize / CC_SHA512_DIGEST_LENGTH;
	for (unsigned long i=2; i<n; i++) {
		CC_SHA512(buf + (i - 2) * CC_SHA512_DIGEST_LENGTH, CC_SHA512_DIGEST_LENGTH,
				  buf + i * CC_SHA512_DIGEST_LENGTH);
	}
	
	//	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	//	CC_MD5(buf, bufSize, hash);
	//	NSData *ret = [NSData dataWithBytes:hash length:CC_MD5_DIGEST_LENGTH];
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(buf, bufSize, hash);
	NSData *ret = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
	free(buf);
	return ret;
}

/*
 PBKDF2 implementation (using HMAC-SHA512) modified for memory usage : instead of 
 XORing the Ui values, all are collected in a big (13*1024*1024 bytes) array, 
 and the entire array is SHA256'd to produce the result of the hash.
 (note : this roughly translates to a 212'992-round PBKDF2, but all intermediary
 values U1...U212992 are needed in-memory)
 */
+ (NSData *) tanukiHash:(NSString *) secret usingSalt:(NSData *)salt consumingMemory:(NSInteger)consumedMB
{
	int bufSizeMB = TANUKI_HASH_DEFAULT_MEMORY_MB;
	if (consumedMB < TANUKI_HASH_MIN_MEMORY_MB) {
		NSLog (@"WARNING : the consumed memory is not allowed to be below %dMB, using this minimum value instead of %d", TANUKI_HASH_MIN_MEMORY_MB, consumedMB);
		bufSizeMB = TANUKI_HASH_MIN_MEMORY_MB;
	}else if (consumedMB > TANUKI_HASH_MAX_MEMORY_MB) {
		NSLog (@"WARNING : for performace reasons, the consumed memory is not allowed to be above %dMB, using this maximum value instead of %d", TANUKI_HASH_MAX_MEMORY_MB, consumedMB);
		bufSizeMB = TANUKI_HASH_MAX_MEMORY_MB;
	}else {
		bufSizeMB = consumedMB;
	}
	unsigned long bufSize = 1024l * 1024 * bufSizeMB;
	uint8_t *buf = malloc(bufSize * sizeof(uint8_t));
	NSData *secretBytes = [secret dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned long debugCount = 0;
	
	//NOTE : compute the big array's chunks in funny order dictated by a pseudorandom permutation
	unsigned long n = bufSize / CC_SHA512_DIGEST_LENGTH;
	CCHmac(kCCHmacAlgSHA512, [secretBytes bytes], [secretBytes length],
		   [salt bytes], [salt length], buf);
	unsigned long oldBlockOffset = 0;
	for (unsigned long i=1; i<n; i++) {
		//first put the new block in its normal position
		unsigned long newBlockOffset = i * CC_SHA512_DIGEST_LENGTH;
		CCHmac(kCCHmacAlgSHA512, [secretBytes bytes], [secretBytes length],
			   buf + oldBlockOffset, CC_SHA512_DIGEST_LENGTH,
			   buf + newBlockOffset);
		//then compute a new index for the block (as the sum of its bytes modulo i+1)
		unsigned long newIndex = buf[newBlockOffset];
		if (i <= debugCount) {
			NSLog (@"add %d", buf[newBlockOffset]);
		}
		for (int j=1; j<CC_SHA512_DIGEST_LENGTH; j++) {
			newIndex = (newIndex * 13 + buf[newBlockOffset + j]) % (i + 1);
			if (i <= debugCount) {
				NSLog (@"add %d", buf[newBlockOffset + j]);
			}
		}
		if (i <= debugCount) {
			NSLog (@"new index is %ld", newIndex);
		}
		//this value should roughly be a uniform random over 0..i
		//now swap the block with the one of that position
		if (newIndex != i) {
			unsigned long relocatedOffset = newIndex * CC_SHA512_DIGEST_LENGTH;
			if (i <= debugCount) {
				NSLog (@"swap blocks %ld and %ld (offset %ld and %ld)", i, newIndex, newBlockOffset, relocatedOffset);
			}
			for (int j=0; j<CC_SHA512_DIGEST_LENGTH; j++) {
				if (i <= debugCount) {
					NSLog (@"swap %d and %d", buf[relocatedOffset + j], buf[newBlockOffset + j]);
				}
				uint8_t swap = buf[relocatedOffset + j];
				buf[relocatedOffset + j] = buf[newBlockOffset + j];
				buf[newBlockOffset + j] = swap;
			}
			oldBlockOffset = relocatedOffset;
		}else {
			oldBlockOffset = i * CC_SHA512_DIGEST_LENGTH;
		}
	}
	
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(buf, bufSize, hash);
	NSData *ret = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
	free(buf);
	return ret;
}

+ (NSData *)tanukiEncryptKey:(TSDatabaseMetadata *)databaseMetadata usingSecret:(NSString *)secret
{
	NSData *salt = [self randomDataOfVariableLengthMinimum:TS_SALT_BYTES_MIN maximum:TS_SALT_BYTES_MAX];
	databaseMetadata.salt = salt;
	return [self tanukiHash:secret usingSalt:salt consumingMemory:databaseMetadata.hashUsedMemory];
}

+ (NSData *)tanukiDecryptKey:(TSDatabaseMetadata *)databaseMetadata usingSecret:(NSString *)secret
{
	return [self tanukiHash:secret usingSalt:databaseMetadata.salt consumingMemory:databaseMetadata.hashUsedMemory];
}

#pragma mark - Encryption

+ (NSData *)aesCbcWithPaddingEncrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv
{
	NSMutableData *encryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	size_t outLength;
	CCCryptorStatus cryptStatus =
	CCCrypt(
			kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
			[key bytes], [key length], [iv bytes],
			[data bytes], [data length],
			[encryptedData mutableBytes], [encryptedData length],
			&outLength);
	if (cryptStatus == kCCSuccess) {
		[encryptedData setLength:outLength];
	}else {
		encryptedData = nil;
	}
	
	return encryptedData;	
}

+ (NSData *)aesCbcWithPaddingDecrypt:(NSData *)data usingKey:(NSData *)key andIV:(NSData *)iv
{
	NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	size_t outLength;
	CCCryptorStatus cryptStatus =
	CCCrypt(
			kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
			[key bytes], [key length], [iv bytes],
			[data bytes], [data length],
			[decryptedData mutableBytes], [decryptedData length],
			&outLength);
	if (cryptStatus == kCCSuccess) {
		[decryptedData setLength:outLength];
	}else {
		decryptedData = nil;
	}
	
	return decryptedData;
}

+ (NSData *)tanukiEncrypt:(NSData *)data usingKey:(NSData *)key andSalt:(NSData *)salt
{	
	NSData *iv = [self firstHalfOfSha256:salt];
	return [self aesCbcWithPaddingEncrypt:data usingKey:key andIV:iv];
}

+ (NSData *)tanukiDecrypt:(NSData *)data usingKey:(NSData *)key andSalt:(NSData *)salt
{	
	NSData *iv = [self firstHalfOfSha256:salt];
	return [self aesCbcWithPaddingDecrypt:data usingKey:key andIV:iv];
}

+ (NSString *)tanukiEncryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					 usingSecret:(NSString *)secret
{
	NSData *key = [self firstHalfOfSha256text:secret];
	NSData *iv = [self firstHalfOfSha256text:itemId];
	NSData *filedValueBytes = [fieldValue dataUsingEncoding:NSUTF8StringEncoding];
	NSData *encryptedFieldValue = [self aesCbcWithPaddingEncrypt:filedValueBytes usingKey:key andIV:iv];
	return [TSStringUtils hexStringFromData:encryptedFieldValue];
}

+ (NSString *)tanukiDecryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					usingSecret:(NSString *)secret
{
	NSData *key = [self firstHalfOfSha256text:secret];
	NSData *iv = [self firstHalfOfSha256text:itemId];
	NSData *filedValueBytes = [TSStringUtils dataFromHexString:fieldValue];
	NSData *decryptedFieldValue = [self aesCbcWithPaddingDecrypt:filedValueBytes usingKey:key andIV:iv];
	return [[NSString alloc] initWithBytes:[decryptedFieldValue bytes]
									length:[decryptedFieldValue length]
								  encoding:NSUTF8StringEncoding];
}

+ (NSData *)tanukiEncryptDatabase:(TSDatabase *)database
				   havingMetadata:(TSDatabaseMetadata *)databaseMetadata
						 usingKey:(NSData *)key
{
	NSData *unencryptedDatabase = [database toData];
//	NSLog (@"unencrypted : %@", [unencryptedDatabase debugDescription]);
//	NSLog (@"unencrypted string : %@", [[NSString alloc] initWithBytes:[unencryptedDatabase bytes]
//		   length:[unencryptedDatabase length]
//		   encoding:NSUTF8StringEncoding]);
	
	if (databaseMetadata.version == nil) {
		databaseMetadata.version = [TSVersion newVersion];
	}
	databaseMetadata.version.checksum = [TSStringUtils hexStringFromData:[self sha512:unencryptedDatabase]];
	
	NSData *encryptedDatabase = [self tanukiEncrypt:unencryptedDatabase usingKey:key andSalt:databaseMetadata.salt];
	//	NSLog (@"encrypted : %@", [encryptedDatabase debugDescription]);
	return encryptedDatabase;
}

+ (TSDatabase *)tanukiDecryptDatabase:(NSData *)encryptedData
					   havingMetadata:(TSDatabaseMetadata *)databaseMetadata
							 usingKey:(NSData *)key
					   ignoreChecksum:(BOOL)ignoreChecksum
{
//	NSLog (@"encrypted : %@", [encryptedData debugDescription]);
	NSData *data = [self tanukiDecrypt:encryptedData usingKey:key andSalt:databaseMetadata.salt];
//	NSLog (@"unencrypted : %@", [data debugDescription]);
//	NSLog (@"unencrypted string : %@", [[NSString alloc] initWithBytes:[data bytes]
//																length:[data length]
//															  encoding:NSUTF8StringEncoding]);
	if (data == nil) {
		NSLog (@"ERROR : decrypt database %@ failed!", databaseMetadata.uid);
		return nil;
	}
	if (ignoreChecksum == NO) {
		NSString *checksum = [TSStringUtils hexStringFromData:[self sha512:data]];
		if ([checksum isEqualToString:databaseMetadata.version.checksum] == NO) {
			NSLog (@"CHECKSUM ERROR : database with id %@ was correctly decrypted but the checsum (%@) did not match the expected checksum taken from the metadata file (%@)",
				   databaseMetadata.uid, checksum, databaseMetadata.version.checksum);
			return nil;
		}
	}
	return (TSDatabase *)[TSDatabase fromData:data];
}

+ (TSDatabase *)tanukiDecryptDatabase:(NSData *)encryptedData
					   havingMetadata:(TSDatabaseMetadata *)databaseMetadata
							 usingKey:(NSData *)key
{
	return [self tanukiDecryptDatabase:encryptedData havingMetadata:databaseMetadata usingKey:key ignoreChecksum:NO];
}

@end
