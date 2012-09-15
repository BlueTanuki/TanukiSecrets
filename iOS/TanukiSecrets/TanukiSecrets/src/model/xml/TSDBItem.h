//
//  TSDBItem.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSDBGroup.h"

@interface TSDBItem : NSObject<TSXMLSerializable>

//- (id)copyWithZone:(NSZone *)zone
//{
//    id copy = [[[self class] alloc] init];
//	
//    if (copy) {
//        // Copy NSObject subclasses
//        [copy setVendorID:[[self.vendorID copyWithZone:zone] autorelease]];
//        [copy setAvailableCars:[[self.availableCars copyWithZone:zone] autorelease]];
//		
//        // Set primitives
//        [copy setAtAirport:self.atAirport];
//    }
//	
//    return copy;
//}

@property(nonatomic, weak) TSDBGroup *parent;

//unique inside parent group
@property(nonatomic, strong) NSString *name;

//name (unique among all groups/items belonging to the same parent)
//description (short, can be used as subtitle, can be automatically set from one of the fields)
//		e.g. "User: <valueOfFieldUserName>" is a good subtitle and the password is a good quick-copy source

//list of tags (typically the names of all ancestor groups)

//default field name (the source of the quick-copy command)
//fields (name->value (structure) map)

//item and fields should provide deep copy methods (implement NSCopying???)

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

//return a template value based on the current state
- (TSDBItem *)createTemplate;

@end
