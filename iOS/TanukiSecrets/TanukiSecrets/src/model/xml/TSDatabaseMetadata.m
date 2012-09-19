//
//  TSDatabaseMetadata.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDatabaseMetadata.h"

#import "TSXMLUtils.h"
#import "TSStringUtils.h"

#define TS_XML_DB_META_TAG_NAME @"tsdbMetadata"
#define TS_XML_DB_META_UID_TAG_NAME @"uid"
#define TS_XML_DB_META_VERSION_TAG_NAME @"version"
#define TS_XML_DB_META_SALT_TAG_NAME @"salt"
#define TS_XML_DB_META_NAME_TAG_NAME @"name"
#define TS_XML_DB_META_DESCRIPTION_TAG_NAME @"description"
#define TS_XML_DB_META_CREATED_TAG_NAME @"createdBy"
#define TS_XML_DB_META_MODIFIED_TAG_NAME @"lastModifiedBy"

@implementation TSDatabaseMetadata

@synthesize uid = _uid, version = _version, salt = _salt, name = _name,
description= _description, createdBy = _createdBy, lastModifiedBy = _lastModifiedBy;

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer
{
	[writer writeStartDocument];
	[writer writeStartElement:TS_XML_DB_META_TAG_NAME];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_META_UID_TAG_NAME
				  withStringContent:self.uid toWriter:writer];
	[self.version writeTo:writer usingTagName:TS_XML_DB_META_VERSION_TAG_NAME];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_META_SALT_TAG_NAME
				  withBinaryContent:self.salt toWriter:writer];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_META_NAME_TAG_NAME
				  withStringContent:self.name toWriter:writer];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_META_DESCRIPTION_TAG_NAME
				  withStringContent:self.description toWriter:writer];
	[self.createdBy writeTo:writer usingTagName:TS_XML_DB_META_CREATED_TAG_NAME];
	[self.lastModifiedBy writeTo:writer usingTagName:TS_XML_DB_META_MODIFIED_TAG_NAME];
	[writer writeEndElement];
	[writer writeEndDocument];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	TSDatabaseMetadata *ret = nil;
	if ([element.name isEqualToString:TS_XML_DB_META_TAG_NAME]) {
		ret = [[TSDatabaseMetadata alloc] init];
		ret.uid = [element valueWithPath:TS_XML_DB_META_UID_TAG_NAME];
		SMXMLElement *aux = [element childNamed:TS_XML_DB_META_VERSION_TAG_NAME];
		if (aux != nil) {
			ret.version = [TSVersion readFrom:aux usingTagName:TS_XML_DB_META_VERSION_TAG_NAME];
		}
		ret.salt = [TSStringUtils dataFromHexString:[element valueWithPath:TS_XML_DB_META_SALT_TAG_NAME]];
		ret.name = [element valueWithPath:TS_XML_DB_META_NAME_TAG_NAME];
		ret.description = [element valueWithPath:TS_XML_DB_META_DESCRIPTION_TAG_NAME];
		aux = [element childNamed:TS_XML_DB_META_CREATED_TAG_NAME];
		if (aux != nil) {
			ret.createdBy = [TSAuthor readFrom:aux usingTagName:TS_XML_DB_META_CREATED_TAG_NAME];
		}
		aux = [element childNamed:TS_XML_DB_META_MODIFIED_TAG_NAME];
		if (aux != nil) {
			ret.lastModifiedBy = [TSAuthor readFrom:aux usingTagName:TS_XML_DB_META_MODIFIED_TAG_NAME];
		}
	}
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
	TSDatabaseMetadata *ret = nil;
	NSError *error;
	SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
	if (error == nil) {
		ret = (TSDatabaseMetadata *)[self readFrom:[document root]];
	}
	return ret;
}

#pragma mark - factory

+ (TSDatabaseMetadata *)newDatabaseNamed:(NSString *)name
{
	TSDatabaseMetadata *ret = [[TSDatabaseMetadata alloc] init];
	ret.uid = [TSStringUtils generateUid];
	ret.name = name;
	ret.version = [TSVersion newVersion];
	ret.createdBy = [TSAuthor authorFromCurrentDevice];
	return ret;
}

@end
