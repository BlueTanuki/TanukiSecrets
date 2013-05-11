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
#import "TSDBCommonTypes.h"


@interface TSDBItemField : NSObject<TSXMLSerializable>

@property(nonatomic, weak) TSDBItem *parent;

//unique inside parent item
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) TSDBFieldType type;
@property(nonatomic, assign) BOOL encrypted;
@property(nonatomic, copy) NSString *value;

//string uniquely identifying this field inside the database
- (NSString *)uniqueGlobalId;

//return a template value based on the current state (value is missing, decoupled from parent)
- (TSDBItemField *)createTemplate;
//an identical copy of the field (value included, still decoupled from parent)
- (TSDBItemField *)clone;

+ (TSDBItemField *)fieldWithName:(NSString *)name type:(TSDBFieldType)type andValue:(NSString *)value;
+ (TSDBItemField *)encryptedFieldWithName:(NSString *)name type:(TSDBFieldType)type andValue:(NSString *)value;

+ (NSString *)interfaceStringForType:(TSDBFieldType)type;
+ (NSString *)stringForType:(TSDBFieldType)type;
+ (TSDBFieldType)typeForString:(NSString *)string;

@end
