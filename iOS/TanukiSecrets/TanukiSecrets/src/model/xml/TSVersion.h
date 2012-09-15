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
@property(nonatomic, strong) NSString *label;//optional
@property(nonatomic, strong) NSString *checksum;

+ (id)versionWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;

/// Designated initializer
- (id)initWithNumber:(NSInteger)number andChecksum:(NSString *)checksum;
- (id)init;

@end
