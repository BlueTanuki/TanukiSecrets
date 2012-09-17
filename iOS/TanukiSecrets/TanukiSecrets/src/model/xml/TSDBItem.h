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

@property(nonatomic, weak) TSDBGroup *parent;

//unique inside parent group
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *description;

@property(nonatomic, strong) NSMutableArray *tags;//of NSString

@property(nonatomic, strong) NSMutableArray *fields;//of TSDBItemField
@property(nonatomic, strong) NSString *defaultFieldName;//can be nil(?)

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

//return a template value based on the current state
- (TSDBItem *)createTemplate;

@end
