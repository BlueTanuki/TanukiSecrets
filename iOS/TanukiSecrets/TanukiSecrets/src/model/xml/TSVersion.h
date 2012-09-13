//
//  TSVersion.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSVersion : NSObject//<TSXMLSerializable>

//version number (int, incremented each time the database is synchronized with remote version)
//version checksum (a sha512 hash of the unencrypted database, needed in the rather
//				  unlikely case when there are 2 different versions with the same version number)

@end
