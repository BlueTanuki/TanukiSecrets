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

+ (NSData *) md5:(NSData *) bytes
{
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5([bytes bytes], [bytes length], hash);
	return [NSData dataWithBytes:hash length:CC_MD5_DIGEST_LENGTH];
}

+ (NSData *) md5text:(NSString *) string
{
	NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [self md5:bytes];
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
+ (NSData *) tanukiHash:(NSString *) secret usingSalt:(NSData *)salt
{
	unsigned long bufSize = 1024l * 1024 * 13;
	uint8_t *buf = malloc(bufSize * sizeof(uint8_t));
	NSData *secretBytes = [secret dataUsingEncoding:NSUTF8StringEncoding];
	
	//NOTE : compute the big array's chunks in reverse order so the first chucks that get hashed are the last ones computed
	unsigned long n = bufSize / CC_SHA512_DIGEST_LENGTH;
	CCHmac(kCCHmacAlgSHA512, [secretBytes bytes], [secretBytes length],
		   [salt bytes], [salt length], buf + (n - 1)*CC_SHA512_DIGEST_LENGTH);
	for (unsigned long i=1; i<n; i++) {
		CCHmac(kCCHmacAlgSHA512, [secretBytes bytes], [secretBytes length],
			   buf + (n-i)*CC_SHA512_DIGEST_LENGTH, CC_SHA512_DIGEST_LENGTH,
			   buf + (n-i-1)*CC_SHA512_DIGEST_LENGTH);
	}
	
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(buf, bufSize, hash);
	NSData *ret = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
	free(buf);
	return ret;
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

+ (NSData *)tanukiEncrypt:(NSData *)data usingSecret:(NSString *)secret andSalt:(NSData *)salt
{	
	NSData *key = [self tanukiHash:secret usingSalt:salt];
	NSData *iv = [self md5:salt];
	return [self aesCbcWithPaddingEncrypt:data usingKey:key andIV:iv];
}

+ (NSData *)tanukiDecrypt:(NSData *)data usingSecret:(NSString *)secret andSalt:(NSData *)salt
{	
	NSData *key = [self tanukiHash:secret usingSalt:salt];
	NSData *iv = [self md5:salt];
	return [self aesCbcWithPaddingDecrypt:data usingKey:key andIV:iv];
}

+ (NSString *)tanukiEncryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					 usingSecret:(NSString *)secret
{
	NSData *key = [self md5text:secret];
	NSData *iv = [self md5text:itemId];
	NSData *filedValueBytes = [fieldValue dataUsingEncoding:NSUTF8StringEncoding];
	NSData *encryptedFieldValue = [self aesCbcWithPaddingEncrypt:filedValueBytes usingKey:key andIV:iv];
	return [TSStringUtils hexStringFromData:encryptedFieldValue];
}

+ (NSString *)tanukiDecryptField:(NSString *)fieldValue belongingToItem:(NSString *)itemId
					usingSecret:(NSString *)secret
{
	NSData *key = [self md5text:secret];
	NSData *iv = [self md5text:itemId];
	NSData *filedValueBytes = [TSStringUtils dataFromHexString:fieldValue];
	NSData *decryptedFieldValue = [self aesCbcWithPaddingDecrypt:filedValueBytes usingKey:key andIV:iv];
	return [[NSString alloc] initWithBytes:[decryptedFieldValue bytes]
									length:[decryptedFieldValue length]
								  encoding:NSUTF8StringEncoding];
}

+ (NSData *)tanukiEncryptDatabase:(TSDatabase *)database
				   havingMetadata:(TSDatabaseMetadata *)databaseMetadata
					  usingSecret:(NSString *)secret
{
	NSData *unencryptedDatabase = [database toData];
	
	NSData *salt = [self randomDataOfVariableLengthMinimum:TS_SALT_BYTES_MIN maximum:TS_SALT_BYTES_MAX];
	databaseMetadata.salt = salt;
	
	if (databaseMetadata.version == nil) {
		databaseMetadata.version = [TSVersion newVersion];
	}
	databaseMetadata.version.checksum = [TSStringUtils hexStringFromData:[self sha512:unencryptedDatabase]];
	
	return [self tanukiEncrypt:unencryptedDatabase usingSecret:secret andSalt:salt];
}

+ (TSDatabase *)tanukiDecryptDatabase:(NSData *)encryptedData
					   havingMetadata:(TSDatabaseMetadata *)databaseMetadata
						  usingSecret:(NSString *)secret
					   ignoreChecksum:(BOOL)ignoreChecksum
{
	NSData *data = [self tanukiDecrypt:encryptedData usingSecret:secret andSalt:databaseMetadata.salt];
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
						  usingSecret:(NSString *)secret
{
	return [self tanukiDecryptDatabase:encryptedData havingMetadata:databaseMetadata usingSecret:secret ignoreChecksum:NO];
}

@end
