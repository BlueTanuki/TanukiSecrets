//
//  TSUserDefaults.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Collection of helper methods wrapping NSUserDefaults <TYPE>ForKey: methods,
 that automtically set the value to the given default if it is not set.
 */
@interface TSUserDefaults : NSObject

+ (NSString *) stringForKey:(NSString *)key usingDefaultValue:(NSString *)defaultValue;

+ (NSInteger) integerForKey:(NSString *)key usingDefaultValue:(NSInteger)defaultValue;

@end
