//
//  TSVersion.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

@interface TSVersion : NSObject<TSXMLSerializable>

@property(nonatomic, assign) NSInteger versionNumber;
@property(nonatomic, copy) NSString *label;//optional
@property(nonatomic, copy) NSString *checksum;

/// Designated initializer
- (id)initWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;
- (id)init;

+ (TSVersion *)versionWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;
+ (TSVersion *)newVersion;

@end
