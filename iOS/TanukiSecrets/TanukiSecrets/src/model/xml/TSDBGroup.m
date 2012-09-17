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

#define TS_XML_DB_GROUP_TAG_NAME @"group"
#define TS_XML_DB_GROUP_NAME_TAG_NAME @"name"
#define TS_XML_DB_GROUP_SUBGROUPS_TAG_NAME @"subgroups"
#define TS_XML_DB_GROUP_ITEMS_TAG_NAME @"items"

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

-(void)writeTo:(XMLWriter *)writer
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
	NSString *parentUid = @"";
	if (self.parent != nil) {
		parentUid = [self.parent uniqueGlobalId];
	}
	return [parentUid stringByAppendingPathComponent:self.name];
}

@end
