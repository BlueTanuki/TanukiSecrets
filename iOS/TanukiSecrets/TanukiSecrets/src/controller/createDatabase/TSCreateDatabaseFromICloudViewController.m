//
//  TSCreateDatabaseFromICloudViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/23/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSCreateDatabaseFromICloudViewController.h"

#import "TSSharedState.h"
#import "TSIOUtils.h"
#import "TSNotifierUtils.h"

@interface TSCreateDatabaseFromICloudViewController ()

@property(nonatomic, strong) TSDatabaseWrapper *iCloudWrapper;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL filteredOutLocalDatabases;

@end

@implementation TSCreateDatabaseFromICloudViewController

@synthesize iCloudWrapper = _iCloudWrapper;
@synthesize failed, filteredOutLocalDatabases;

#pragma mark - override getters/setters

- (TSDatabaseWrapper *)iCloudWrapper
{
	if (_iCloudWrapper == nil) {
		_iCloudWrapper = [TSSharedState iCloudWrapperForDelegate:self];
	}
	return _iCloudWrapper;
}

#pragma mark - communication with subclass

- (TSDatabaseWrapper *)databaseWrapper
{
	return self.iCloudWrapper;
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
		return @"Fetching database list from iCloud. Please wait.";
	}
	if (self.failed) {
		return @"Communication with iCloud servers failed. Make sure you have an internet connection and try again later.";
	}
	if ([self.remoteDatabaseUIDs count] > 0) {
		return @"Please choose the database you want to synchronize with.";
	}
	if (self.filteredOutLocalDatabases) {
		return @"You already have local versions of all the databases you have synchronized with iCloud.";
	}
	return @"You do not have any databases in iCloud. You must first synchronize an existing database with iCloud using the same Apple ID, then you will be able to use it during the database creation process.";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *databaseUid = [self.remoteDatabaseUIDs objectAtIndex:indexPath.row];
	NSString *metadataFilePath = [self.databaseMetadataFilePaths objectAtIndex:indexPath.row];
	NSString *databaseFilePath = [self.databaseFilePaths objectAtIndex:indexPath.row];
	if ([TSIOUtils moveFile:databaseFilePath to:[TSIOUtils databaseFilePath:databaseUid]]) {
		if ([TSIOUtils moveFile:metadataFilePath to:[TSIOUtils metadataFilePath:databaseUid]]) {
			[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
				NSNotification *notificaton = [NSNotification notificationWithName:TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED object:nil];
				[[NSNotificationCenter defaultCenter] postNotification:notificaton];
			}];
		}else {
			[TSNotifierUtils error:@"Failed (metadata rename)"];
		}
	}else {
		[TSNotifierUtils error:@"Failed (database rename)"];
	}
}


@end
