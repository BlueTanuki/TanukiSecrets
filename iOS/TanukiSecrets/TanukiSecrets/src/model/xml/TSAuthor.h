//
//  TSAuthor.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

#define TS_XML_AUTHOR_TAG_NAME @"author"
#define TS_XML_AUTHOR_UID_TAG_NAME @"uid"
#define TS_XML_AUTHOR_NAME_TAG_NAME @"name"
#define TS_XML_AUTHOR_DATE_TAG_NAME @"date"
#define TS_XML_AUTHOR_COMMENT_TAG_NAME @"comment"

/*
 Not the most inspired name, this entity does not only identify the author, but
 also the timestamp when an action was done and an optional comment for the change.
 */
@interface TSAuthor : NSObject//<TSXMLSerializable>

//@property(nonatomic, strong) NSString *uid;
//@property(nonatomic, strong) NSString *name;
//@property(nonatomic, strong) NSDate *date;
//@property(nonatomic, strong) NSString *comment;//optional
//
//+ (id)authorWithId:(NSString *)uid andName:(NSString *)name;
//
//// Designated initializer
//- (id)initWithId:(NSString *)uid andName:(NSString *)name;
//- (id)init;


@end
