//
//  TSRemoteDatabasesViewController.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/22/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TSDatabaseWrapper.h"

/**
 TableViewController that should be used as base class for The various places 
 where a list of remotely stored databases are presented.
 This class cannot be used as is, and subclasses must at least implement the 
 getter for the TSDatabaseWrapper instance that is used by this class.
 */
@interface TSRemoteDatabasesViewController : UITableViewController <TSDatabaseWrapperDelegate>

@property(nonatomic, assign) BOOL working;
@property(nonatomic, strong) NSArray *remoteDatabaseUIDs;//of NSString
@property(nonatomic, strong) NSMutableArray *databaseMetadataFilePaths;//of NSString
@property(nonatomic, strong) NSMutableArray *databaseMetadataArray;//of TSDatabaseMetadata
@property(nonatomic, strong) NSMutableArray *databaseFilePaths;//of NSString

- (void)refreshData:(id)sender;

//subclasses must override this
- (TSDatabaseWrapper *)databaseWrapper;

//callback for subclasses : beginning to (re)fetch the database ids and metadata files
- (void)refreshStarted;
//callback for subclasses : finished (re)fetching the database ids and metadata files
- (void)refreshFinished;
//callback for subclasses : (re)fetching the database ids and metadata files failed
- (void)refreshFailed;
//hook for subclasses to filter the databaseUIDs that will be fetched (e.g. filter out local databases)
//the default implementation does not filter anything out
- (NSArray *)filterDatabaseUIDs:(NSArray *)databaseUIDs;

@end
