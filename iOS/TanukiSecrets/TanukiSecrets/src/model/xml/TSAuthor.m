//
//  TSAuthor.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSAuthor.h"

@implementation TSAuthor

//@synthesize uid = _uid, name = _name, date =_date, comment = _comment;
//
//#pragma mark - initialization
//
//+ (id)authorWithId:(NSString *)uid andName:(NSString *)name
//{
//	return [[TSAuthor alloc] initWithId:uid andName:name];
//}
//
//- (id)initWithId:(NSString *)uid andName:(NSString *)name
//{
//	if (self = [super init]) {
//		self.uid = uid;
//		self.name = name;
//		self.date = [NSDate date];
//	}
//	return self;
//}
//
//- (id)init
//{
//	return [super init];
//}
//
//#pragma mark - TSXMLSerializable
//
//- (void)writeTo:(XMLWriter *)writer usingTagName:(NSString *)tagName
//{
//	[writer writeStartElement:tagName];
//	[TSXMLUtils writeSimpleTagNamed:TS_XML_AUTHOR_UID_TAG_NAME
//				  withStringContent:self.uid
//						   toWriter:writer];
//	[TSXMLUtils writeSimpleTagNamed:TS
//				  withStringContent:self.uid
//						   toWriter:writer];
//	if ([TSStringUtils isNotBlank:self.label]) {
//		[TSXMLUtils writeSimpleTagNamed:TS_XML_VERSION_LABEL_TAG_NAME
//					  withStringContent:self.label
//							   toWriter:writer];
//	}
//	[TSXMLUtils writeSimpleTagNamed:TS_XML_VERSION_CHECKSUM_TAG_NAME
//				  withStringContent:self.checksum
//						   toWriter:writer];
//	[writer writeEndElement];
//}
//
//-(void)writeTo:(XMLWriter *)writer
//{
//	[self writeTo:writer usingTagName:TS_XML_VERSION_TAG_NAME];
//}
//
//+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
//{
//	TSVersion *ret = nil;
//	if ([element.name isEqualToString:tagName]) {
//		ret = [[TSVersion alloc] init];
//		ret.versionNumber = [[element valueWithPath:TS_XML_VERSION_NUMBER_TAG_NAME] integerValue];
//		ret.label = [element valueWithPath:TS_XML_VERSION_LABEL_TAG_NAME];
//		ret.checksum = [element valueWithPath:TS_XML_VERSION_CHECKSUM_TAG_NAME];
//	}
//	return ret;
//}
//
//+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
//{
//	return [self readFrom:element usingTagName:TS_XML_VERSION_TAG_NAME];
//}

@end
