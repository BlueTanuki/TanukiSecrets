//
//  TSStringUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/31/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSStringUtils : NSObject

+ (NSString *) hexStringFromData:(NSData *)data;
+ (NSData *) dataFromHexString:(NSString *)string;

+ (NSString *) stringFromInteger:(NSInteger)value;

+ (NSString *) trim:(NSString *)string;
+ (BOOL) isBlank:(NSString *)string;
+ (BOOL) isNotBlank:(NSString *)string;

@end
