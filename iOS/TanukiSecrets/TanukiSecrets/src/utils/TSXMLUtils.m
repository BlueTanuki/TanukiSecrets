//
//  TSXMLUtils.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/14/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSXMLUtils.h"

#import "TSStringUtils.h"
#import "TSDateUtils.h"

@implementation TSXMLUtils

+ (void)writeSimpleTagNamed:(NSString *)tagName withStringContent:(NSString *)content toWriter:(XMLWriter *)writer
{
	[writer writeStartElement:tagName];
	[writer writeCharacters:content];
	[writer writeEndElement];
}

+ (void)writeSimpleTagNamed:(NSString *)tagName withIntegerContent:(NSInteger)content toWriter:(XMLWriter *)writer
{
	[self writeSimpleTagNamed:tagName withStringContent:[TSStringUtils stringFromInteger:content] toWriter:writer];
}

+ (void)writeSimpleTagNamed:(NSString *)tagName withBinaryContent:(NSData *)content toWriter:(XMLWriter *)writer
{
	[self writeSimpleTagNamed:tagName withStringContent:[TSStringUtils hexStringFromData:content] toWriter:writer];
}

+ (void)writeSimpleTagNamed:(NSString *)tagName withDateTimeContent:(NSDate *)content toWriter:(XMLWriter *)writer
{
	[self writeSimpleTagNamed:tagName withStringContent:[TSDateUtils stringFromDate:content] toWriter:writer];
}

+ (void)writeSimpleNodesNamed:(NSArray *)tagNames
				  andContents:(NSArray *)stringContents
					 toWriter:(XMLWriter *)writer
{
	NSUInteger n = [tagNames count];
	if (n > [stringContents count]) {
		n = [stringContents count];
	}
	for (int i=0; i<n; i++) {
		NSString *tagName = [tagNames objectAtIndex:i];
		NSString *tagContent = [stringContents objectAtIndex:i];
		if ([TSStringUtils isNotBlank:tagName] && [TSStringUtils isNotBlank:tagContent]) {
			[self writeSimpleTagNamed:tagName
					withStringContent:tagContent
							 toWriter:writer];
		}
	}
}

+ (void)writeSimpleNodesNamed:(NSArray *)tagNames
				  andContents:(NSArray *)stringContents
	   insideWrapperNodeNamed:(NSString *)parentNodeName
					 toWriter:(XMLWriter *)writer
{
	[writer writeStartElement:parentNodeName];
	[self writeSimpleNodesNamed:tagNames andContents:stringContents toWriter:writer];
	[writer writeEndElement];
}

@end
