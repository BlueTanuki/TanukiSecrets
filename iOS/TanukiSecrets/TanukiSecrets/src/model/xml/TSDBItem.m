//
//  TSDBItem.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDBItem.h"

#import "TSXMLUtils.h"
#import "TSStringUtils.h"
#import "TSDBItemField.h"

#define TS_XML_DB_ITEM_TAG_NAME @"item"
#define TS_XML_DB_ITEM_NAME_TAG_NAME @"name"
#define TS_XML_DB_ITEM_DESCRIPTION_TAG_NAME @"description"
#define TS_XML_DB_ITEM_TAGS_TAG_NAME @"tags"
#define TS_XML_DB_ITEM_TAG_TAG_NAME @"tag"
#define TS_XML_DB_ITEM_FIELDS_TAG_NAME @"fields"
#define TS_XML_DB_ITEM_DEFAULT_FIELD_TAG_NAME @"defaultFieldName"

@implementation TSDBItem

@synthesize parent = _parent, name = _name, description = _description,
tags = _tags, fields = _fields, defaultFieldName = _defaultFieldName;

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
{
	[writer writeStartElement:tagName];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_NAME_TAG_NAME
				  withStringContent:self.name
						   toWriter:writer];
	if ([TSStringUtils isNotBlank:self.description]) {
		[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_DESCRIPTION_TAG_NAME
					  withStringContent:self.description
							   toWriter:writer];
	}
	if ([self.tags count] > 0) {
		[TSXMLUtils writeStringArray:self.tags
						usingTagName:TS_XML_DB_ITEM_TAG_NAME
					  andWrapperNode:TS_XML_DB_ITEM_TAGS_TAG_NAME
							toWriter:writer];
	}
	if ([self.fields count] > 0) {
		[TSXMLUtils writeArrayOfTSXMLSerializableObjects:self.fields
										usingWrapperNode:TS_XML_DB_ITEM_FIELDS_TAG_NAME
												toWriter:writer];
	}
	if ([TSStringUtils isNotBlank:self.defaultFieldName]) {
		[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_DEFAULT_FIELD_TAG_NAME
					  withStringContent:self.defaultFieldName
							   toWriter:writer];
	}
	[writer writeEndElement];
}

- (void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_DB_ITEM_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSDBItem *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSDBItem alloc] init];
		ret.name = [element valueWithPath:TS_XML_DB_ITEM_NAME_TAG_NAME];
		ret.description = [element valueWithPath:TS_XML_DB_ITEM_DESCRIPTION_TAG_NAME];
		SMXMLElement *aux = [element childNamed:TS_XML_DB_ITEM_TAGS_TAG_NAME];
		if (aux != nil) {
			ret.tags = [[NSMutableArray alloc] init];
			NSArray *children = [aux childrenNamed:TS_XML_DB_ITEM_TAG_TAG_NAME];
			for (SMXMLElement *child in children) {
				[ret.tags addObject:child.value];
			}
		}
		aux = [element childNamed:TS_XML_DB_ITEM_FIELDS_TAG_NAME];
		if (aux != nil) {
			ret.fields = [[NSMutableArray alloc] init];
			NSArray *children = aux.children;
			for (SMXMLElement *child in children) {
				TSDBItemField *field = [TSDBItemField readFrom:child];
				field.parent = ret;
				[ret.tags addObject:field];
			}
		}
		ret.defaultFieldName = [element valueWithPath:TS_XML_DB_ITEM_DEFAULT_FIELD_TAG_NAME];
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_DB_ITEM_TAG_NAME];
}

#pragma mark - other

- (NSString *)uniqueGlobalId
{
	NSString *parentUid = @"";
	if (self.parent != nil) {
		parentUid = [self.parent uniqueGlobalId];
	}
	return [parentUid stringByAppendingPathComponent:self.name];
}

- (TSDBItem *)createTemplate
{
	TSDBItem *ret = [[TSDBItem alloc] init];
	ret.name = [self.name copy];
	ret.description = [self.description copy];
	if ([self.tags count] > 0) {
		ret.tags = [NSMutableArray arrayWithArray:[self.tags copy]];
	}
	if ([self.fields count] > 0) {
		ret.fields = [[NSMutableArray alloc] initWithCapacity:[self.fields count]];
		for (TSDBItemField *field in self.fields) {
			[ret.fields addObject:[field createTemplate]];
		}
	}
	ret.defaultFieldName = [self.defaultFieldName copy];
	return ret;
}

- (void) addField:(TSDBItemField *)field
{
	if (self.fields == nil) {
		self.fields = [NSMutableArray arrayWithObject:field];
	}else {
		[self.fields addObject:field];
	}
}

#pragma mark - factory

+ (TSDBItem *)itemNamed:(NSString *)name
{
	TSDBItem *ret = [[TSDBItem alloc] init];
	ret.name = name;
	return ret;
}

@end
