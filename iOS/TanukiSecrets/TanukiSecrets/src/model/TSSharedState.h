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
#import "TSDatabaseMetadata.h"
#import "TSDatabase.h"


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
@property(nonatomic, copy) NSString *openDatabasePassword;
@property(nonatomic, strong) TSDatabaseMetadata *openDatabaseMetadata;
@property(nonatomic, strong) TSDatabase *openDatabase;
@property(nonatomic, weak) TSDBGroup *currentGroup;
@property(nonatomic, weak) TSDBItem *currentItem;

//WARNING : preparing the next encryption key overwrites openDatabaseMetadata.salt
//if for some reason the database needs to be re-decrypted, the metadata needs to be re-read also
//WARNING : always check before requesting the encrypt key (it may not be ready)
//NOTE : invoke this manually when opening the database and when changing the password
//WARNING: do NOT request the encryption except when actually needed, generating the next key burns a lot of cpu and memory
//a new invocation is automatically made when the encrypt key is requested
- (void)startPreparingNextEncryptKey;
- (BOOL)encryptKeyReady;
- (NSData *)encryptKey;

@end
