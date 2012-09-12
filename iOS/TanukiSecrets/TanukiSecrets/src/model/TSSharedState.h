//
//  TSSharedState.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSConstants.h"

/*
 Singleton for shared properties. Only properties that need to be shared among
 unrelated objects should go here. Another acceptable use is for properties that
 need a single central means of accessing (for example because they expire 
 after a certain time).
*/
@interface TSSharedState : NSObject

- (NSString *) instanceUID;

@end
