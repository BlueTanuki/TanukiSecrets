//
//  TSAuthor.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Not the most inspired name, this entity does not only identify the author, but
 also the timestamp when an action was done and an optional comment for the change.
 */
@interface TSAuthor : NSObject//<TSXMLSerializable>

//author UID (== sharedState.instanceUID)
//author name (== device name)

//timestamp
//comment

@end
