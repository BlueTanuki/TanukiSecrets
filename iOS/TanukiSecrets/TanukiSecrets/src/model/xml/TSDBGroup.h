//
//  TSDBGroup.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

@interface TSDBGroup : NSObject<TSXMLSerializable>

@property(nonatomic, weak) TSDBGroup *parent;

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSArray *subgroups;//of TSDBGroup
@property(nonatomic, strong) NSArray *items;//of TSDBItem

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

@end
