//
//  TSDatabaseLock.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDatabaseLock.h"

#define TS_XML_DB_LOCK_TAG_NAME @"tsdbLock"
#define TS_XML_DB_LOCK_OPTIMISTIC_TAG_NAME @"optimisticLock"
#define TS_XML_DB_LOCK_WRITE_TAG_NAME @"writeLock"

@implementation TSDatabaseLock

@synthesize optimisticLock = _optimisticLock, writeLock = _writeLock;

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
{
	[writer writeStartElement:tagName];
	if (self.optimisticLock != nil) {
		[self.optimisticLock writeTo:writer usingTagName:TS_XML_DB_LOCK_OPTIMISTIC_TAG_NAME];
	}
	if (self.writeLock != nil) {
		[self.writeLock writeTo:writer usingTagName:TS_XML_DB_LOCK_WRITE_TAG_NAME];
	}
	[writer writeEndElement];
}

- (void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_DB_LOCK_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSDatabaseLock *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSDatabaseLock alloc] init];
		SMXMLElement *aux = [element childNamed:TS_XML_DB_LOCK_OPTIMISTIC_TAG_NAME];
		if (aux != nil) {
			ret.optimisticLock = [TSAuthor readFrom:aux usingTagName:TS_XML_DB_LOCK_OPTIMISTIC_TAG_NAME];
		}
		aux = [element childNamed:TS_XML_DB_LOCK_WRITE_TAG_NAME];
		if (aux != nil) {
			ret.writeLock = [TSAuthor readFrom:aux usingTagName:TS_XML_DB_LOCK_WRITE_TAG_NAME];
		}
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_DB_LOCK_TAG_NAME];
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
	TSDatabaseLock *ret = nil;
	NSError *error;
	SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
	if (error == nil) {
		ret = (TSDatabaseLock *)[self readFrom:[document root]];
	}
	return ret;
}

#pragma mark - factory

+ (TSDatabaseLock *)optimisticLock
{
	TSAuthor *author = [TSAuthor authorFromCurrentDevice];
	TSDatabaseLock *ret = [[TSDatabaseLock alloc] init];
	ret.optimisticLock = author;
	return ret;
}

+(TSDatabaseLock *)writeLock
{
	TSAuthor *author = [TSAuthor authorFromCurrentDevice];
	TSDatabaseLock *ret = [[TSDatabaseLock alloc] init];
	ret.writeLock = author;
	return ret;
}

@end
