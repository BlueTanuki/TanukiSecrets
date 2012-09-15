//
//  TSAuthor.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSAuthor.h"

#import "TSXMLUtils.h"
#import "TSStringUtils.h"
#import "TSDateUtils.h"

#define TS_XML_AUTHOR_TAG_NAME @"author"
#define TS_XML_AUTHOR_UID_TAG_NAME @"uid"
#define TS_XML_AUTHOR_NAME_TAG_NAME @"name"
#define TS_XML_AUTHOR_DATE_TAG_NAME @"date"
#define TS_XML_AUTHOR_COMMENT_TAG_NAME @"comment"

@implementation TSAuthor

@synthesize uid = _uid, name = _name, date =_date, comment = _comment;

#pragma mark - initialization

+ (id)authorWithId:(NSString *)uid andName:(NSString *)name
{
	return [[TSAuthor alloc] initWithId:uid andName:name];
}

- (id)initWithId:(NSString *)uid andName:(NSString *)name
{
	if (self = [super init]) {
		self.uid = uid;
		self.name = name;
		self.date = [NSDate date];
	}
	return self;
}

- (id)init
{
	return [super init];
}

#pragma mark - TSXMLSerializable

- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
{
	[writer writeStartElement:tagName];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_AUTHOR_UID_TAG_NAME
				  withStringContent:self.uid
						   toWriter:writer];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_AUTHOR_NAME_TAG_NAME
				  withStringContent:self.name
						   toWriter:writer];
	[TSXMLUtils writeSimpleTagNamed:TS_XML_AUTHOR_DATE_TAG_NAME
				withDateTimeContent:self.date
						   toWriter:writer];
	if ([TSStringUtils isNotBlank:self.comment]) {
		[TSXMLUtils writeSimpleTagNamed:TS_XML_AUTHOR_COMMENT_TAG_NAME
					  withStringContent:self.comment
							   toWriter:writer];
	}
	[writer writeEndElement];
}

-(void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_AUTHOR_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSAuthor *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSAuthor alloc] init];
		ret.uid = [element valueWithPath:TS_XML_AUTHOR_UID_TAG_NAME];
		ret.name = [element valueWithPath:TS_XML_AUTHOR_NAME_TAG_NAME];
		ret.date = [TSDateUtils dateFromString:[element valueWithPath:TS_XML_AUTHOR_DATE_TAG_NAME]];
		ret.comment = [element valueWithPath:TS_XML_AUTHOR_COMMENT_TAG_NAME];
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_AUTHOR_TAG_NAME];
}

@end
