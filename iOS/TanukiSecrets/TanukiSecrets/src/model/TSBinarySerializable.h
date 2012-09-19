//
//  TSBinarySerializable.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSBinarySerializable <NSObject>

- (NSData *) toData;
+ (id<TSBinarySerializable>) fromData:(NSData *)data;

@end
