//
//  TSiCloudWrapper.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSRemoteStorage.h"

@interface TSiCloudWrapper : NSObject<TSRemoteStorage>

- (void)refreshUbiquityContainerURL;

@end
