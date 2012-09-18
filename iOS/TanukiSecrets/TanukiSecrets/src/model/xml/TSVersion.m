//
//  TSVersion.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSVersion.h"

#import "TSXMLUtils.h"
#import "TSStringUtils.h"

#define TS_XML_VERSION_TAG_NAME @"version"
#define TS_XML_VERSION_NUMBER_TAG_NAME @"versionNumber"
#define TS_XML_VERSION_LABEL_TAG_NAME @"label"
#define TS_XML_VERSION_CHECKSUM_TAG_NAME @"checksum"

@implementation TSVersion

@synthesize checksum = _checksum, label = _label, versionNumber = _versionNumber;

#pragma mark - initialization

- (id)initWithNumber:(NSInteger)versionNumber andChecksum:(NSString *)checksum
{
	if (self = [super init]) {
		self.checksum = checksum;
		self.versionNumber = versionNumber;
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
	[TSXMLUtils writeSimpleTagNamed:TS_XML_VERSION_NUMBER_TAG_NAME
				 withIntegerContent:self.versionNumber
						   toWriter:writer];
	if ([TSStringUtils isNotBlank:self.label]) {
		[TSXMLUtils writeSimpleTagNamed:TS_XML_VERSION_LABEL_TAG_NAME
					 withStringContent:self.label
							   toWriter:writer];
	}
	[TSXMLUtils writeSimpleTagNamed:TS_XML_VERSION_CHECKSUM_TAG_NAME
				  withStringContent:self.checksum
						   toWriter:writer];
	[writer writeEndElement];
}

- (void)writeTo:(XMLWriter *)writer
{
	[self writeTo:writer usingTagName:TS_XML_VERSION_TAG_NAME];
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element usingTagName:(NSString *)tagName
{
	TSVersion *ret = nil;
	if ([element.name isEqualToString:tagName]) {
		ret = [[TSVersion alloc] init];
		ret.versionNumber = [[element valueWithPath:TS_XML_VERSION_NUMBER_TAG_NAME] integerValue];
		ret.label = [element valueWithPath:TS_XML_VERSION_LABEL_TAG_NAME];
		ret.checksum = [element valueWithPath:TS_XML_VERSION_CHECKSUM_TAG_NAME];
	}
	return ret;
}

+ (id<TSXMLSerializable>)readFrom:(SMXMLElement *)element
{
	return [self readFrom:element usingTagName:TS_XML_VERSION_TAG_NAME];
}

#pragma mark - factory

+ (TSVersion *)versionWithNumber:(NSInteger)number andChecksum:(NSString *)checksum
{
	return [[TSVersion alloc] initWithNumber:number andChecksum:checksum];
}

+ (TSVersion *)newVersion
{
	TSVersion *ret = [[TSVersion alloc] init];
	ret.versionNumber = 0;
	return ret;
}

@end
