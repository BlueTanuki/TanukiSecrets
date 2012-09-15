//
//  TSXMLWritable.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/2/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "XMLWriter.h"
#import "SMXMLDocument.h"
#import <Foundation/Foundation.h>

@protocol TSXMLSerializable <NSObject>

- (void)writeTo:(XMLWriter *)writer;
+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element;

@optional
- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName;
+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName;

@end
