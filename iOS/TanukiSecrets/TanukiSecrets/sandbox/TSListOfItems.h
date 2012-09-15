//
//  TSListOfItems.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/2/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSXMLSerializable.h"
#include "TSItem.h"

@interface TSListOfItems : NSObject<TSXMLSerializable>

@property (strong, nonatomic) NSMutableArray* items;

-(void)addItem:(TSItem *)item;

- (NSDictionary *)asDictionary;

@end
