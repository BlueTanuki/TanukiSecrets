//
//  TSItem.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/2/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSItem.h"
#import "TSDateUtils.h"

@implementation TSItem

@synthesize date, string, integer;

-(void)writeTo:(XMLWriter *)writer
{
	[writer writeStartElement:@"item"];
	[writer writeStartElement:@"string"];
	[writer writeCharacters:self.string];
	[writer writeEndElement];
	[writer writeStartElement:@"date"];
	[writer writeCharacters:[TSDateUtils stringFromDate:self.date]];
	[writer writeEndElement];
	[writer writeStartElement:@"int"];
	[writer writeCharacters:[NSString stringWithFormat:@"%d", self.integer]];
	[writer writeEndElement];
	[writer writeEndElement];
}

+(TSItem *)readFrom:(SMXMLElement *)element
{
	if ([element.name isEqualToString:@"item"]) {
		TSItem *ret = [[TSItem alloc] init];
		ret.string = [element valueWithPath:@"string"];
		ret.date = [TSDateUtils dateFromString:[element valueWithPath:@"date"]];
		ret.integer = [[element valueWithPath:@"int"] intValue];
		return ret;
	}
	return nil;
}

- (NSDictionary *)asDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				self.date, @"date",
				self.string, @"string",
				self.integer, @"int",
			nil];
}

@end
