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
#import "TSUtils.h"

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
	[TSUtils foreground:^{
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												 target:self
												 action:@selector(refreshData:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self.tableView reloadData];
		[self refreshFinished];
	}];
}

- (void)updateFailed
{
	self.working = NO;
	self.remoteDatabaseUIDs = nil;
	[TSUtils foreground:^{
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												 target:self
												 action:@selector(refreshData:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self.tableView reloadData];
		[self refreshFailed];
	}];
}

- (void)refreshData:(id)sender
{
	if (self.working == NO) {
		self.remoteDatabaseUIDs = nil;
		self.working = YES;
		[TSUtils background:^{
			[[self databaseWrapper] listDatabaseUids];
		}];
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
