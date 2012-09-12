//
//  TSItem.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/2/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSXMLSerializable.h"

@interface TSItem : NSObject<TSXMLSerializable>

@property (readwrite, copy) NSDate* date;
@property (readwrite, copy) NSString* string;
@property (readwrite, assign) NSInteger integer;

@end
