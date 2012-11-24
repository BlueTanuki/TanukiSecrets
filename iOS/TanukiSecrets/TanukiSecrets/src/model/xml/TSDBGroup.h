//
//  TSDBGroup.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

@class TSDBItem;

@interface TSDBGroup : NSObject<TSXMLSerializable>

@property(nonatomic, weak) TSDBGroup *parent;

//unique inside parent group
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) NSMutableArray *subgroups;//of TSDBGroup
@property(nonatomic, strong) NSMutableArray *items;//of TSDBItem

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

- (void)addSubgroup:(TSDBGroup *)group;
- (void)addItem:(TSDBItem *)item;

+ (TSDBGroup *)groupNamed:(NSString *)name;

@end
