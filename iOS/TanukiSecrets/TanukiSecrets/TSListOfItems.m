//
//  TSListOfItems.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/2/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSListOfItems.h"

@implementation TSListOfItems

@synthesize items;

-(void)addItem:(TSItem *)item
{
	if (self.items == nil) {
		self.items = [[NSMutableArray alloc] init];
	}
	[self.items addObject:item];
}

-(void)writeTo:(XMLWriter *)writer
{
	
	[writer writeStartElement:@"items"];
	if (self.items) {
		int n = [self.items count];
		for (int i=0; i<n; i++) {
			[[self.items objectAtIndex:i] writeTo:writer];
		}
	}
	[writer writeEndElement];
}

+(TSListOfItems *)readFrom:(SMXMLElement *)element
{
	if ([element.name isEqualToString:@"items"]) {
		TSListOfItems *ret = [[TSListOfItems alloc] init];
		for (SMXMLElement *item in [element childrenNamed:@"item"]) {
			[ret addItem:[TSItem readFrom:item]];
		}
		return ret;
	}
	return nil;
}

@end
