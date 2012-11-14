//
//  TSUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/29/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

//Other utility methods that do not clearly belong to any of the other
//more specialized *Utils helpers
@interface TSUtils : NSObject

#pragma mark - random numbers generation

+ (double)randomDouble;//[0, 1]
+ (double)randomDoubleBetween:(double)a and:(double)b;//[a, b]

#pragma mark - GCD helpers

+ (void)background:(void (^)(void))block;
+ (void)foreground:(void (^)(void))block;

#pragma mark - presenting various reusable dialogs

+ (void)notifyEncryptionKeyIsNotReady;

@end
