//
//  TSDatabase.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSXMLSerializable.h"
#import "TSDBGroup.h"

@interface TSDatabase : NSObject<TSXMLSerializable>

@property(nonatomic, strong) TSDBGroup *root;

@end
