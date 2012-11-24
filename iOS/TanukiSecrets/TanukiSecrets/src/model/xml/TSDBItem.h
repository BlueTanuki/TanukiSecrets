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

@class TSDBItemField;
@interface TSDBItem : NSObject<TSXMLSerializable>

@property(nonatomic, weak) TSDBGroup *parent;

//unique inside parent group
@property(nonatomic, copy) NSString *name;

@property(nonatomic, strong) NSMutableArray *tags;//of NSString

@property(nonatomic, strong) NSMutableArray *fields;//of TSDBItemField
@property(nonatomic, copy) NSString *quickActionFieldName;//can be nil
@property(nonatomic, copy) NSString *subtitleFieldName;//can be nil

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

//return a template value based on the current state (not an identical copy, structure is the same but values will be missing)
- (TSDBItem *)createTemplate;

//return copy of the current object that can be used while editing.
//similar to createTemplate, the returned copy is detached from the database tree.
//unlike createTemplate, the returned object will also have all the field values
//Usage: when the editing begins call this method to obtain an item usable during editing while keeping the original intact
- (TSDBItem *)editingCopy;
//when editing changes, call this method when saving the item to commit any changes made while editing
//Note : do not use the itemUsedForEditing instance after this call. Obtain a fresh copy for additional editing
- (void)commitEditingChanges:(TSDBItem *)itemUsedForEditing;

- (void) addField:(TSDBItemField *)field;
- (TSDBItemField *)fieldNamed:(NSString *)fieldName;

+ (TSDBItem *)itemNamed:(NSString *)name;

+ (NSArray *)systemTemplates;//of TSDBItem

@end
