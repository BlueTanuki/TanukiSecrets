//
//  TSDatabaseLock.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Similar to the database metadata object, this entity is saved in a separate 
 non-encrypted file. This object will hold various types of locks and is used
 to synchronize access to the database.
 
 This object is saved to the database.tsl file (remote only).
 */
@interface TSDatabaseLock : NSObject//<TSXMLSerializable>

//optimistic lock (author structure) - when the database is changed by one client
//	-> advisory, should still allow different clients to push changes, but warn them before continuing
//
//write lock - blocking lock, set by the client when it wants to push changes to the database
//	-> since many things can go wrong, clients will not disallow access if the lock is set
//This lock is to be used as follows :
//	0. client checks to see if the optimistic lock is his, and if not warns the user and waits for confirmation before continuing
//	1. client sets this lock (if it is already set the client is allowed to overwrite it
//							  only after a confirmation from the user)
//	2. client waits a few seconds
//	3. client checks the lock, and fails the update if the lock is not his
//	4. client waits a few seconds again
//	5. client checks the lock one last time, then pushes the changes to the database
//	6. client releases the write lock and the optimistic lock as well.

@end
