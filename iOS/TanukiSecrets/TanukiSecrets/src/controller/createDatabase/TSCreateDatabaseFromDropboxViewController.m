//
//  TSCreateDatabaseFromDropboxViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/22/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSCreateDatabaseFromDropboxViewController.h"

#import <DropboxSDK/DropboxSDK.h>

#import "TSSharedState.h"
#import "TSNotifierUtils.h"
#import "TSIOUtils.h"

@interface TSCreateDatabaseFromDropboxViewController ()

@property(nonatomic, strong) TSDatabaseWrapper *dropboxWrapper;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL filteredOutLocalDatabases;

@end

@implementation TSCreateDatabaseFromDropboxViewController

@synthesize dropboxWrapper = _dropboxWrapper;
@synthesize failed, filteredOutLocalDatabases;

#pragma mark - override getters/setters

- (TSDatabaseWrapper *)dropboxWrapper
{
	if ([[DBSession sharedSession] isLinked] == NO) {
		@throw NSInternalInconsistencyException;
	}
	if (_dropboxWrapper == nil) {
		_dropboxWrapper = [TSSharedState dropboxWrapperForDelegate:self];
	}
	return _dropboxWrapper;
}

#pragma mark - communication with subclass

- (TSDatabaseWrapper *)databaseWrapper
{
	return self.dropboxWrapper;
}

- (void)refreshStarted
{
	self.failed = NO;
	self.filteredOutLocalDatabases = NO;
}

- (void)refreshFinished
{
}

- (void)refreshFailed
{
	self.failed = YES;
}

- (NSArray *)filterDatabaseUIDs:(NSArray *)databaseUIDs
{
	NSLog (@"Filter databaseUIDs called.");
	NSMutableArray *aux = [NSMutableArray array];
	NSArray *localDatabaseUIDs = [TSIOUtils listDatabaseUids];
	for (NSString *databaseUID in databaseUIDs) {
		if ([localDatabaseUIDs containsObject:databaseUID] == YES) {
			self.filteredOutLocalDatabases = YES;
		}else {
			[aux addObject:databaseUID];
		}
	}
	return aux;
}

#pragma mark - TableViewController

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (self.working) {
		return @"Fetching database list from Dropbox servers. Please wait.";
	}
	if (self.failed) {
		return @"Communication with Dropbox servers failed. Make sure you have an internet connection and try again later.";
	}
	if ([self.remoteDatabaseUIDs count] > 0) {
		return @"Please choose the database you want to synchronize with.";
	}
	if (self.filteredOutLocalDatabases) {
		return @"You already have local versions of all the databases you have in your Dropbox account.";
	}
	return @"You do not have any databases in your Dropbox account. You must first synchronize an existing database with Dropbox, then you will be able to use it during the database creation process.";
}



@end
