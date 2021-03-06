//
//  TSDBItemField.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDBItemField.h"

#import "TSXMLUtils.h"

#define TS_XML_DB_ITEM_FIELD_TAG_NAME @"field"
#define TS_XML_DB_ITEM_FIELD_NAME_TAG_NAME @"name"
#define TS_XML_DB_ITEM_FIELD_TYPE_TAG_NAME @"type"
#define TS_XML_DB_ITEM_FIELD_ENCRYPTED_TAG_NAME @"encrypted"
#define TS_XML_DB_ITEM_FIELD_VALUE_TAG_NAME @"value"

@implementation TSDBItemField

@synthesize parent = _parent, name = _name, encrypted = _encrypted, value = _value;

#pragma mark - helpers

+ (NSString *)interfaceStringForType:(TSDBFieldType)type
{
	switch (type) {
		case TSDBFieldType_NUMERIC:
			return @"Numeric";
			break;
			
		case TSDBFieldType_SECRET:
			return @"Secret";
			break;
			
		case TSDBFieldType_TEXT:
			return @"Long text";
			break;
			
		case TSDBFieldType_URL:
			return @"URL";
			break;
			
		default:
			return @"Text";
	}
}

+ (NSString *)stringForType:(TSDBFieldType)type
{
	switch (type) {
		case TSDBFieldType_NUMERIC:
			return @"NUMERIC";
			break;
			
		case TSDBFieldType_SECRET:
			return @"SECRET";
			break;
			
		case TSDBFieldType_TEXT:
			return @"TEXT";
			break;
			
		case TSDBFieldType_URL:
			return @"URL";
			break;
			
		default:
			return @"DEFAULT";
	}
}

+ (TSDBFieldType)typeForString:(NSString *)string
{
	if ([@"NUMERIC" isEqualToString:string]) {
		return TSDBFieldType_NUMERIC;
	}
	if ([@"SECRET" isEqualToString:string]) {
		return TSDBFieldType_SECRET;
	}
	if ([@"TEXT" isEqualToString:string]) {
		return TSDBFieldType_TEXT;
	}
	if ([@"URL" isEqualToString:string]) {
		return TSDBFieldType_URL;
	}
	return TSDBFieldType_DEFAULT;
}

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
{
	[writer writeStartElement:tagName];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_FIELD_NAME_TAG_NAME
				  withStringContent:self.name
						   toWriter:writer];
	//avoid saving magic numbers
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_FIELD_TYPE_TAG_NAME
				 withStringContent:[TSDBItemField stringForType:self.type]
						   toWriter:writer];
	if (self.encrypted) {
		[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_FIELD_ENCRYPTED_TAG_NAME
					  withStringContent:@"true"
							   toWriter:writer];
	}
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_ITEM_FIELD_VALUE_TAG_NAME
				withStringContent:self.value
						   toWriter:writer];
	[writer writeEndElement];
}

- (void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_DB_ITEM_FIELD_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSDBItemField *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSDBItemField alloc] init];
		ret.name = [element valueWithPath:TS_XML_DB_ITEM_FIELD_NAME_TAG_NAME];
		//reconvert the string to a magic number
		ret.type = [self typeForString:[element valueWithPath:TS_XML_DB_ITEM_FIELD_TYPE_TAG_NAME]];
		SMXMLElement *aux = [element childNamed:TS_XML_DB_ITEM_FIELD_ENCRYPTED_TAG_NAME];
		if (aux != nil) {
			ret.encrypted = YES;
		}
		ret.value = [element valueWithPath:TS_XML_DB_ITEM_FIELD_VALUE_TAG_NAME];
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_DB_ITEM_FIELD_TAG_NAME];
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

- (TSDBItemField *)createTemplate
{
	TSDBItemField *ret = [[TSDBItemField alloc] init];
	ret.name = self.name;
	ret.type = self.type;
	ret.encrypted = self.encrypted;
	return ret;
}

- (TSDBItemField *)clone
{
	TSDBItemField *ret = [[TSDBItemField alloc] init];
	ret.name = self.name;
	ret.type = self.type;
	ret.encrypted = self.encrypted;
	ret.value = self.value;
	return ret;
}

#pragma mark - factory

+ (TSDBItemField *)fieldWithName:(NSString *)name type:(TSDBFieldType)type andValue:(NSString *)value
{
	TSDBItemField *ret = [[TSDBItemField alloc] init];
	ret.name = name;
	ret.type = type;
	ret.encrypted = NO;
	ret.value = value;
	return ret;
}

+ (TSDBItemField *)encryptedFieldWithName:(NSString *)name type:(TSDBFieldType)type andValue:(NSString *)value
{
	TSDBItemField *ret = [self fieldWithName:name type:type andValue:value];
	ret.encrypted = YES;
	return ret;
}

@end
