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

- (void)writeTo:(XMLWriter *)writer
{
	[writer writeStartDocument];
	[self.root writeTo:writer usingTagName:TS_XML_DB_ROOT_TAG_NAME];
	[writer writeEndDocument];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	TSDatabase *ret = [[TSDatabase alloc] init];
	ret.root = [TSDBGroup readFrom:element usingTagName:TS_XML_DB_ROOT_TAG_NAME];
	return ret;
}

#pragma mark - TSBinarySerializable

- (NSData *)toData
{
	XMLWriter *writer = [[XMLWriter alloc] init];
	[self writeTo:writer];
	return [writer toData];
}

+ (id<TSBinarySerializable>)fromData:(NSData *)data
{
	TSDatabase *ret = nil;
	NSError *error;
	SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
	if (error == nil) {
		ret = (TSDatabase *)[self readFrom:[document root]];
	}
	return ret;
}

#pragma mark - factory

+ (TSDatabase *)databaseWithRoot:(TSDBGroup *)root
{
	TSDatabase * ret = [[TSDatabase alloc] init];
	ret.root = root;
	return ret;
}

@end
