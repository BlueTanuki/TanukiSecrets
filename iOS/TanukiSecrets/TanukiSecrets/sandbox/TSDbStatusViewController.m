//
//  TSDbStatusViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/12/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDbStatusViewController.h"

#import "TSDatabaseWrapper.h"
#import "TSSharedState.h"
#import "TSIOUtils.h"
#import "TSNotifierUtils.h"
#import "TSUtils.h"

@interface TSDbStatusViewController () <TSDatabaseWrapperDelegate>

@property(nonatomic, strong) TSDatabaseWrapper *dropboxWrapper;
@property(nonatomic, strong) TSDatabaseWrapper *iCloudWrapper;

@property(nonatomic, strong) NSArray *localDatabaseUIDs;
@property(nonatomic, strong) NSArray *dropboxDatabaseUIDs;
@property(nonatomic, strong) NSArray *iCloudDatabaseUIDs;

@property(nonatomic, assign) BOOL working;
@property(nonatomic, assign) BOOL localReady;
@property(nonatomic, assign) BOOL dropboxReady;
@property(nonatomic, assign) BOOL iCloudReady;

@property(nonatomic, strong) NSArray *toBePrintedBackupIds;
@property(nonatomic, assign) NSInteger toBePrintedBackupIdsIndex;

@end

@implementation TSDbStatusViewController

@synthesize dropboxWrapper = _dropboxWrapper, iCloudWrapper = _iCloudWrapper;
@synthesize localDatabaseUIDs, dropboxDatabaseUIDs, iCloudDatabaseUIDs;
@synthesize working, localReady, dropboxReady, iCloudReady;
@synthesize toBePrintedBackupIds, toBePrintedBackupIdsIndex;

#pragma mark - override getters/setters

- (TSDatabaseWrapper *)dropboxWrapper
{
	if (_dropboxWrapper == nil) {
		_dropboxWrapper = [TSSharedState dropboxWrapperForDelegate:self];
	}
	return _dropboxWrapper;
}

- (TSDatabaseWrapper *)iCloudWrapper
{
	if (_iCloudWrapper == nil) {
		_iCloudWrapper = [TSSharedState iCloudWrapperForDelegate:self];
	}
	return _iCloudWrapper;
}

- (NSString *)secret
{
	return @"TheTanukiSais...NI-PAH~!";
}

#pragma mark - worker methods

- (void)partialUpdateFinished
{
	if (self.localReady && self.dropboxReady && self.iCloudReady) {
		self.working = NO;
		[TSUtils foreground:^{
			UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
													 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
													 target:self
													 action:@selector(refreshData:)];
			self.navigationItem.rightBarButtonItem = refreshDropboxButton;
			[self.tableView reloadData];
		}];
	}else {
		[TSUtils foreground:^{
			[self.tableView reloadData];
		}];
	}
}

- (void)refreshLocal
{
	self.localDatabaseUIDs = [TSIOUtils listDatabaseUids];
	self.localReady = YES;
	[self partialUpdateFinished];
}

- (void)refreshDropbox
{
	[self.dropboxWrapper listDatabaseUids];
}

- (void)refreshICloud
{
	[self.iCloudWrapper listDatabaseUids];
}

- (void)refreshData:(id)sender
{
	if (self.working == NO) {
		self.working = YES;
		self.localReady = NO;
		[TSUtils background:^{
			[self refreshLocal];
		}];
		self.dropboxReady = NO;
		[TSUtils background:^{
			[self refreshDropbox];
		}];
		self.iCloudReady = NO;
		[TSUtils background:^{
			[self refreshICloud];
		}];
		UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc]
										 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[busy startAnimating];
		UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
												 initWithCustomView:busy];
		self.navigationItem.rightBarButtonItem = refreshButton;
	}else {
		NSLog (@"Refresh is already in progress");
	}
}

- (void)debugStatusOfDatabase:(TSDatabase *)database havingMetadata:(TSDatabaseMetadata *)metadata
{
	XMLWriter *writer = [[XMLWriter alloc] init];
	[metadata writeTo:writer];
	NSLog (@"TSDatabaseMetadata :: %@", [writer toString]);
	writer = [[XMLWriter alloc] init];
	[database writeTo:writer];
	NSLog (@"TSDatabase :: %@", [writer toString]);
}

- (void)debugStatusOfLocalDatabase:(NSString *)databaseUId
{
	[TSNotifierUtils info:@"START local db debug print"];
	NSLog (@"*** *** *** Debug information for local database with UID %@", databaseUId);
	NSString *metadataPath = [TSIOUtils metadataFilePath:databaseUId];
	TSDatabaseMetadata *metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataPath];
	NSString *databasePath = [TSIOUtils databaseFilePath:databaseUId];
	TSDatabase *database = [TSIOUtils loadDatabaseFromFile:databasePath havingMetadata:metadata usingSecret:[self secret]];
	[self debugStatusOfDatabase:database havingMetadata:metadata];
	[TSNotifierUtils info:@"local database info dumpded to log"];
	NSArray *backupIDs = [TSIOUtils backupIdsForDatabase:databaseUId];
	if ([backupIDs count] > 0) {
		NSLog (@"*** *** *** This database has %d backups", [backupIDs count]);
		for (NSString *backupID in backupIDs) {
			metadataPath = [TSIOUtils metadataFilePath:databaseUId forBackup:backupID];
			metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataPath];
			databasePath = [TSIOUtils databaseFilePath:databaseUId forBackup:backupID];
			database = [TSIOUtils loadDatabaseFromFile:databasePath havingMetadata:metadata usingSecret:[self secret]];
			NSLog (@"*** *** Backup %@ of database %@", backupID, databaseUId);
			[self debugStatusOfDatabase:database havingMetadata:metadata];
			[TSNotifierUtils info:@"local backup info dumpded to log"];
		}
	}else {
		NSLog (@"*** *** *** This database does not have any backups");
	}
	NSLog (@"*** *** *** END Debug information for local database with UID %@", databaseUId);
	[TSNotifierUtils info:@"END local db debug print"];
}

- (void)debugStatusOfDropboxDatabase:(NSString *)databaseUId
{
	[TSNotifierUtils info:@"START Dropbox db debug print"];
	NSLog (@"*** *** *** Debug information for Dropbox database with UID %@", databaseUId);
	[self.dropboxWrapper downloadDatabase:databaseUId];
}

- (void)debugStatusOfICloudDatabase:(NSString *)databaseUId
{
	[TSNotifierUtils info:@"START iCloud db debug print"];
	NSLog (@"*** *** *** Debug information for iCloud database with UID %@", databaseUId);
	[self.iCloudWrapper downloadDatabase:databaseUId];
}

- (void)deleteLocalDatabase:(NSString *)databaseUid
{
	if ([TSIOUtils deleteDatabase:databaseUid]) {
		[TSNotifierUtils info:@"Local database deleted."];
		int64_t delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self refreshData:nil];
		});
	}else {
		[TSNotifierUtils error:@"Failed to delete local database."];
	}
}

- (void)deleteDropboxDatabase:(NSString *)databaseUid
{
	[self.dropboxWrapper deleteDatabase:databaseUid];
}

- (void)deleteICloudDatabase:(NSString *)databaseUid
{
	[self.iCloudWrapper deleteDatabase:databaseUid];
}

#pragma mark - TSDatabaseWrapperDelegate

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listDatabaseUidsFailedWithError:(NSString *)error
{
	[TSNotifierUtils error:@"List database UIDs failed"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListDatabaseUids:(NSArray *)databaseUids
{
	if (databaseWrapper == self.dropboxWrapper) {
		self.dropboxDatabaseUIDs = databaseUids;
		self.dropboxReady = YES;
	}else if (databaseWrapper == self.iCloudWrapper) {
		self.iCloudDatabaseUIDs = databaseUids;
		self.iCloudReady = YES;
	}else {
		NSLog (@"Received finishedListDatabaseUids callback from unknown database wrapper!!!");
	}
	[self partialUpdateFinished];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	TSDatabaseMetadata *metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataFilePath];
	TSDatabase *database = [TSIOUtils loadDatabaseFromFile:databaseFilePath havingMetadata:metadata usingSecret:[self secret]];
	[self debugStatusOfDatabase:database havingMetadata:metadata];
	[TSNotifierUtils info:@"remote database info dumpded to log"];
	[databaseWrapper listBackupIdsForDatabase:databaseUid];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog (@"Failed to download database with id %@ :: %@", databaseUid, error);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListBackupIds:(NSArray *)backupIds forDatabase:(NSString *)databaseUid
{
	if ([backupIds count] > 0) {
		NSLog (@"*** *** *** This database has %d backups", [backupIds count]);
		self.toBePrintedBackupIds = backupIds;
		self.toBePrintedBackupIdsIndex = 0;
		[databaseWrapper downloadBackup:[self.toBePrintedBackupIds objectAtIndex:self.toBePrintedBackupIdsIndex] ofDatabase:databaseUid];
	}else {
		NSLog (@"*** *** *** This database does not have any backups yet.");
	}
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listBackupIdsForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog (@"Failed to list backups for database with id %@ :: %@", databaseUid, error);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	TSDatabaseMetadata *metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataFilePath];
	TSDatabase *database = [TSIOUtils loadDatabaseFromFile:databaseFilePath havingMetadata:metadata usingSecret:[self secret]];
	[self debugStatusOfDatabase:database havingMetadata:metadata];
	[TSNotifierUtils info:@"remote backup info dumpded to log"];
	self.toBePrintedBackupIdsIndex = self.toBePrintedBackupIdsIndex + 1;
	if (self.toBePrintedBackupIdsIndex < [self.toBePrintedBackupIds count]) {
		[databaseWrapper downloadBackup:[self.toBePrintedBackupIds objectAtIndex:self.toBePrintedBackupIdsIndex] ofDatabase:databaseUid];
	}else {
		NSLog (@"*** *** *** END Debug information for local database with UID %@", databaseUid);
		[TSNotifierUtils info:@"END remote db debug print"];
	}
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deletedDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:@"Delete database finished..."];
	int64_t delayInSeconds = 5.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self refreshData:nil];
	});
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:@"Delete failed"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	[TSNotifierUtils error:@"Database is locked"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog (@"Failed to download backup %@ of database with id %@ :: %@", backupId, databaseUid, error);
}

#pragma mark - TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Local";
			break;
			
		case 1:
			return @"Dropbox";
			break;
			
		case 2:
			return @"iCloud";
			break;
			
		default:
			return @"???";
			break;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *aux = nil;
	switch (section) {
		case 0:
			aux = self.localDatabaseUIDs;
			break;
			
		case 1:
			aux = self.dropboxDatabaseUIDs;
			break;
			
		case 2:
			aux = self.iCloudDatabaseUIDs;
			break;
			
		default:
			NSLog (@"WARNING : numberOfRows called for unknown section : %d", section);
			break;
	}
	if (aux == nil) {
		[self refreshData:nil];
		return 0;
	}
	return [aux count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *aux = nil;
	switch (indexPath.section) {
		case 0:
			aux = self.localDatabaseUIDs;
			break;
			
		case 1:
			aux = self.dropboxDatabaseUIDs;
			break;
			
		case 2:
			aux = self.iCloudDatabaseUIDs;
			break;
			
		default:
			NSLog (@"WARNING : numberOfRows called for unknown section : %d", indexPath.section);
			break;
	}
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FSCell"];
	if (aux == nil) {
		cell.textLabel.text = @"ERROR";
	}else {
		cell.textLabel.text = [aux objectAtIndex:indexPath.row];
	}
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		switch (indexPath.section) {
			case 0: {
				NSString *databaseUid = [self.localDatabaseUIDs objectAtIndex:indexPath.row];
				[self deleteLocalDatabase:databaseUid];
			}
				break;
				
			case 1: {
				NSString *databaseUid = [self.dropboxDatabaseUIDs objectAtIndex:indexPath.row];
				[self deleteDropboxDatabase:databaseUid];
				[TSNotifierUtils info:@"Delete database starting..."];
			}
				break;
				
			case 2: {
				NSString *databaseUid = [self.iCloudDatabaseUIDs objectAtIndex:indexPath.row];
				[self deleteICloudDatabase:databaseUid];
				[TSNotifierUtils info:@"Delete database starting..."];
			}
				break;
				
			default:
				NSLog (@"WARNING : commitEditingStyle called for unknown section : %d", indexPath.section);
				break;
		}
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case 0: {
			[TSUtils background:^{
				[self debugStatusOfLocalDatabase:[self.localDatabaseUIDs objectAtIndex:indexPath.row]];
			}];
		}
			break;
			
		case 1: {
			[TSUtils background:^{
				[self debugStatusOfDropboxDatabase:[self.dropboxDatabaseUIDs objectAtIndex:indexPath.row]];
			}];
		}
			break;
			
		case 2: {
			[TSUtils background:^{
				[self debugStatusOfICloudDatabase:[self.iCloudDatabaseUIDs objectAtIndex:indexPath.row]];
			}];
		}
			break;
			
		default:
			NSLog (@"WARNING : didSelectRowAtIndexPath called for unknown section : %d", indexPath.section);
			break;
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
