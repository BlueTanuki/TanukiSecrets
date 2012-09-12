//
//  TSDateUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSDateUtils : NSObject

+ (NSDateFormatter *) dateTimeFormat;
+ (NSString *) stringFromDate:(NSDate *)date;
+ (NSDate *) dateFromString:(NSString *)string;

@end
