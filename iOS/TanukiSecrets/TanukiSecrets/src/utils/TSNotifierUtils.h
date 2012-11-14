//
//  TSNotifierUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSNotifierUtils : NSObject

+ (void)info:(NSString *)text;
+ (void)error:(NSString *)text;

+ (void)infoAtTopOfScreen:(NSString *)text;
+ (void)errorAtTopOfScreen:(NSString *)text;

@end
