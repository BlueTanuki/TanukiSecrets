//
//  TSDBGroup.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDBGroup.h"

#import "TSXMLUtils.h"
#import "TSDBItem.h"
#import "TSDBItemField.h"
#import "TSStringUtils.h"

#define TS_XML_DB_GROUP_TAG_NAME @"group"
#define TS_XML_DB_GROUP_NAME_TAG_NAME @"name"
#define TS_XML_DB_GROUP_SUBGROUPS_TAG_NAME @"subgroups"
#define TS_XML_DB_GROUP_ITEMS_TAG_NAME @"items"

@interface TSDBGroup ()

//field name -> occurrence count
- (NSMutableDictionary *)uniqueValuesAndCountForFieldNamed:(NSString *)name ofType:(TSDBFieldType)type;

@end


@implementation TSDBGroup

@synthesize parent = _parent, name = _name, subgroups = _subgroups, items = _items;

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
{
	[writer writeStartElement:tagName];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_DB_GROUP_NAME_TAG_NAME
				  withStringContent:self.name
						   toWriter:writer];
	if ([self.subgroups count] > 0) {
		[TSXMLUtils writeArrayOfTSXMLSerializableObjects:self.subgroups
										usingWrapperNode:TS_XML_DB_GROUP_SUBGROUPS_TAG_NAME
												toWriter:writer];
	}
	if ([self.items count] > 0) {
		[TSXMLUtils writeArrayOfTSXMLSerializableObjects:self.items
										usingWrapperNode:TS_XML_DB_GROUP_ITEMS_TAG_NAME
												toWriter:writer];
	}
	[writer writeEndElement];
}

- (void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_DB_GROUP_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSDBGroup *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSDBGroup alloc] init];
		ret.name = [element valueWithPath:TS_XML_DB_GROUP_NAME_TAG_NAME];
		SMXMLElement *aux = [element childNamed:TS_XML_DB_GROUP_SUBGROUPS_TAG_NAME];
		if (aux != nil) {
			ret.subgroups = [[NSMutableArray alloc] init];
			NSArray *children = aux.children;
			for (SMXMLElement *child in children) {
				TSDBGroup *subgroup = [TSDBGroup readFrom:child];
				subgroup.parent = ret;
				[ret.subgroups addObject:subgroup];
			}
		}
		aux = [element childNamed:TS_XML_DB_GROUP_ITEMS_TAG_NAME];
		if (aux != nil) {
			ret.items = [[NSMutableArray alloc] init];
			NSArray *children = aux.children;
			for (SMXMLElement *child in children) {
				TSDBItem *item = [TSDBItem readFrom:child];
				item.parent = ret;
				[ret.items addObject:item];
			}
		}
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_DB_GROUP_TAG_NAME];
}

#pragma mark - other

- (NSString *)uniqueGlobalId
{
	if (self.parent == nil) {
		return @"/";
	}
	return [[self.parent uniqueGlobalId] stringByAppendingPathComponent:self.name];
}

- (void)addItem:(TSDBItem *)item
{
	if (self.items == nil) {
		self.items = [NSMutableArray arrayWithObject:item];
	}else {
		[self.items addObject:item];
	}
}

- (void)addSubgroup:(TSDBGroup *)group
{
	if (self.subgroups == nil) {
		self.subgroups = [NSMutableArray arrayWithObject:group];
	}else {
		[self.subgroups addObject:group];
	}
}

#pragma mark - factory

+ (TSDBGroup *)groupNamed:(NSString *)name
{
	TSDBGroup *ret = [[TSDBGroup alloc] init];
	ret.name = name;
	return ret;
}

#pragma mark - misc

- (NSMutableDictionary *)uniqueValuesAndCountForFieldNamed:(NSString *)name ofType:(TSDBFieldType)type
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	for (TSDBGroup *subgroup in self.subgroups) {
		NSMutableDictionary *aux = [subgroup uniqueValuesAndCountForFieldNamed:name ofType:type];
		for (NSString *fieldValue in [aux keyEnumerator]) {
			int sum = 0;
			NSNumber *number = (NSNumber *)[ret objectForKey:fieldValue];
			if (number != nil) {
				sum += [number intValue];
			}
			number = (NSNumber *)[aux objectForKey:fieldValue];
			if (number != nil) {
				sum += [number intValue];
			}
			[ret setValue:[NSNumber numberWithInt:sum] forKey:fieldValue];
		}
	}
	for (TSDBItem *item in self.items) {
		for (TSDBItemField *itemField in item.fields) {
			if (([itemField.name isEqualToString:name]) && (itemField.type == type) &&
				([TSStringUtils isNotBlank:itemField.value])) {
				int sum = 1;
				NSNumber *number = (NSNumber *)[ret objectForKey:itemField.value];
				if (number != nil) {
					sum += [number intValue];
				}
				[ret setValue:[NSNumber numberWithInt:sum] forKey:itemField.value];
			}
		}
	}
	return ret;
}

- (NSArray *)mostUsedValuesForFieldNamed:(NSString *)name ofType:(TSDBFieldType)type
{
	NSLog (@"field name %@ of type %@", name, [TSDBItemField interfaceStringForType:type]);
	NSMutableDictionary *valuesAndCounts = [self uniqueValuesAndCountForFieldNamed:name ofType:type];
	NSLog (@"%@", valuesAndCounts);
	NSArray *ret = [valuesAndCounts keysSortedByValueUsingComparator:^(id obj1, id obj2) {
		NSNumber *num1 = (NSNumber *)obj1;
		NSNumber *num2 = (NSNumber *)obj2;
		return [num2 compare:num1];
	}];
	NSLog (@"%@", ret);
	return ret;
}

@end
