//
//  TSVersion.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

#define TS_XML_VERSION_TAG_NAME @"version"
#define TS_XML_VERSION_NUMBER_TAG_NAME @"versionNumber"
#define TS_XML_VERSION_LABEL_TAG_NAME @"label"
#define TS_XML_VERSION_CHECKSUM_TAG_NAME @"checksum"

@interface TSVersion : NSObject<TSXMLSerializable>

@property(nonatomic, assign) NSInteger versionNumber;
@property(nonatomic, strong) NSString *label;//optional
@property(nonatomic, strong) NSString *checksum;

+ (id)versionWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;

// Designated initializer
- (id)initWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;
- (id)init;

@end
