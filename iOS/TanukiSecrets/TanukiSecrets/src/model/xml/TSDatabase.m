//
//  TSDatabase.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDatabase.h"

#define TS_XML_DB_ROOT_TAG_NAME @"tanukiSecretsDatabase"

@implementation TSDatabase

@synthesize root = _root;

#pragma mark - TSXMLSerializable

-(void)writeTo:(XMLWriter *)writer
{
	[self.root writeTo:writer usingTagName:TS_XML_DB_ROOT_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	TSDatabase *ret = [[TSDatabase alloc] init];
	ret.root = [TSDBGroup readFrom:element usingTagName:TS_XML_DB_ROOT_TAG_NAME];
	return ret;
}

@end
