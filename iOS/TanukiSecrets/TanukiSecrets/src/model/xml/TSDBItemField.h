//
//  TSDBItemField.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSDBItem.h"

@interface TSDBItemField : NSObject<TSXMLSerializable>

@property(nonatomic, weak) TSDBItem *parent;

//unique inside parent item
@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL encrypted;
@property(nonatomic, strong) NSString *value;

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

//return a template value based on the current state
- (TSDBItemField *)createTemplate;

@end
