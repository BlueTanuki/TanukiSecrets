//
//  TSDropboxWrapper.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DropboxSDK/DropboxSDK.h>
#import "TSRemoteStorage.h"


/**
 Wrapper for interacting with Dropbox remote storage. 
 */
@interface TSDropboxWrapper : NSObject<DBRestClientDelegate, TSRemoteStorage>

@end

