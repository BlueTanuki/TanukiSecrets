//
//  TSDeviceUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/11/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSDeviceUtils : NSObject

+ (NSString *) deviceName;

+ (BOOL) isRunningInSimulator;

+ (BOOL) isIPad;
+ (BOOL) isIPhone;

@end
