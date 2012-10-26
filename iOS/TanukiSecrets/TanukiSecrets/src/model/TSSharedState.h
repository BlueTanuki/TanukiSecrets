//
//  TSSharedState.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/10/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSConstants.h"

#import "TSDatabaseWrapper.h"


/*
 Singleton for shared properties. Only properties that need to be shared among
 unrelated objects should go here. Another acceptable use is for properties that
 need a single central means of accessing (for example because they expire 
 after a certain time).
*/
@interface TSSharedState : NSObject

+ (TSSharedState*)sharedState;

//convenience method (if the caller does not need an instance for anything else)
+ (NSString *)instanceUID;

+ (TSDatabaseWrapper *)dropboxWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate;
- (TSDatabaseWrapper *)dropboxWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate;

+ (TSDatabaseWrapper *)iCloudWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate;
- (TSDatabaseWrapper *)iCloudWrapperForDelegate:(id<TSDatabaseWrapperDelegate>)delegate;

@property(nonatomic, readonly) NSString *instanceUID;
@property(nonatomic, strong) NSString *openDatabasePassword;

@end
