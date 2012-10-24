//
//  TSRemoteDatabasesViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/22/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSRemoteDatabasesViewController.h"

#import "TSNotifierUtils.h"
#import "TSDatabaseMetadata.h"
#import "TSIOUtils.h"
#import "TSDateUtils.h"

@interface TSRemoteDatabasesViewController ()

@property(nonatomic, assign) NSInteger remoteDatabaseUIDsIndex;

@end

@implementation TSRemoteDatabasesViewController

@synthesize working;

@synthesize remoteDatabaseUIDs, databaseMetadataFilePaths, databaseMetadataArray,
databaseFilePaths;
@synthesize remoteDatabaseUIDsIndex;

#pragma mark - communication with subclass

- (TSDatabaseWrapper *)databaseWrapper
{
	@throw NSInternalInconsistencyException;
}

- (void)refreshStarted
{
}

- (void)refreshFinished
{
}

- (void)refreshFailed
{
}

- (NSArray *)filterDatabaseUIDs:(NSArray *)databaseUIDs
{
	return databaseUIDs;
}

#pragma mark - worker methods

- (void)updateFinished
{
	self.working = NO;
	dispatch_async(dispatch_get_main_queue(), ^{
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												 target:self
												 action:@selector(refreshData:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self.tableView reloadData];
		[self refreshFinished];
	});
}

- (void)updateFailed
{
	self.working = NO;
	self.remoteDatabaseUIDs = nil;
	dispatch_async(dispatch_get_main_queue(), ^{
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												 target:self
												 action:@selector(refreshData:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self.tableView reloadData];
		[self refreshFailed];
	});
}

- (void)refreshData:(id)sender
{
	if (self.working == NO) {
		self.remoteDatabaseUIDs = nil;
		self.working = YES;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[self databaseWrapper] listDatabaseUids];
		});
		UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc]
										 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[busy startAnimating];
		UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
										  initWithCustomView:busy];
		self.navigationItem.rightBarButtonItem = refreshButton;
		[self refreshStarted];
		[self.tableView reloadData];
	}else {
		NSLog (@"Refresh is already in progress");
	}
}


#pragma mark - TSDatabaseWrapperDelegate

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listDatabaseUidsFailedWithError:(NSString *)error
{
	[self updateFailed];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListDatabaseUids:(NSArray *)databaseUids
{
	self.remoteDatabaseUIDs = [self filterDatabaseUIDs:databaseUids];
	self.remoteDatabaseUIDsIndex = 0;
	self.databaseMetadataFilePaths = [NSMutableArray array];
	self.databaseMetadataArray = [NSMutableArray array];
	self.databaseFilePaths = [NSMutableArray array];
	if ([self.remoteDatabaseUIDs count] > 0) {
		[databaseWrapper downloadDatabase:[self.remoteDatabaseUIDs objectAtIndex:self.remoteDatabaseUIDsIndex]];
	}else {
		[self updateFinished];
	}
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	TSDatabaseMetadata *metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataFilePath];
	[self.databaseMetadataFilePaths addObject:metadataFilePath];
	[self.databaseMetadataArray addObject:metadata];
	[self.databaseFilePaths addObject:databaseFilePath];
	self.remoteDatabaseUIDsIndex++;
	if (self.remoteDatabaseUIDsIndex < [self.remoteDatabaseUIDs count]) {
		[databaseWrapper downloadDatabase:[self.remoteDatabaseUIDs objectAtIndex:self.remoteDatabaseUIDsIndex]];
	}else {
		[self updateFinished];
	}
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[self updateFailed];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListBackupIds:(NSArray *)backupIds forDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listBackupIdsForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deletedDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper deleteDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper attemptingToLockDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyLockedDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper createdBackup:(NSString *)backupId forDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMainFileForDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyUnlockedDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupDeletedFile:(NSString *)path
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid isStalledBecauseOfOptimisticLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedUploadingDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedAddingOptimisticLockForDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedRemovingOptimisticLockForDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedCleanupForDatabase:(NSString *)databaseUid
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"Unexpected TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
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
	
	[self refreshData:nil];

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSLog (@"Count called : %d", [self.remoteDatabaseUIDs count]);
	return [self.remoteDatabaseUIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog (@"Item at index called : %d", indexPath.row);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    TSDatabaseMetadata *databaseMetadata = [self.databaseMetadataArray objectAtIndex:indexPath.row];
	cell.textLabel.text = [databaseMetadata name];
	TSAuthor *lastModifiedBy = [databaseMetadata lastModifiedBy];
	NSString *aux = [TSDateUtils interfaceStringFromDate:[lastModifiedBy date]];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", aux, [lastModifiedBy name]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [TSNotifierUtils error:@"Not implemented!"];
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
