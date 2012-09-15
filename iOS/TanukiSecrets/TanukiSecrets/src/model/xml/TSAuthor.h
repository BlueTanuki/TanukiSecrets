//
//  TSAuthor.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"

/*
 Not the most inspired name, this entity does not only identify the author, but
 also the timestamp when an action was done and an optional comment for the change.
 */
@interface TSAuthor : NSObject<TSXMLSerializable>

@property(nonatomic, strong) NSString *uid;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *comment;//optional

+ (id)authorWithId:(NSString *)uid andName:(NSString *)name;

// Designated initializer
- (id)initWithId:(NSString *)uid andName:(NSString *)name;
- (id)init;


@end
