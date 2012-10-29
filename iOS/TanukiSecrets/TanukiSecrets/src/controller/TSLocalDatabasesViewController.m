//
//  TSLocalDatabasesViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSLocalDatabasesViewController.h"

#import "TSIOUtils.h"
#import "TSDatabaseMetadata.h"
#import "TSDateUtils.h"
#import "TSConstants.h"
#import "TSUtils.h"
#import "TSSharedState.h"
#import "TSNotifierUtils.h"
#import "TSUnlockViewController.h"
#import "TSDeviceUtils.h"

@interface TSLocalDatabasesViewController ()

@property(nonatomic, strong) NSArray *localDatabaseUIDs;
@property(nonatomic, strong) NSArray *databaseMetadataArray;

@end

@implementation TSLocalDatabasesViewController

@synthesize localDatabaseUIDs = _localDatabaseUIDs;
@synthesize databaseMetadataArray;

#pragma mark - worker

- (void)reloadDatabaseList:(id)sender
{
	[TSUtils foreground:^{
		_localDatabaseUIDs = [TSIOUtils listDatabaseUids];
		if (_localDatabaseUIDs != nil) {
			NSMutableArray *aux = [NSMutableArray arrayWithCapacity:[_localDatabaseUIDs count]];
			for (NSString *databaseUid in _localDatabaseUIDs) {
				TSDatabaseMetadata *databaseMetadata = [TSIOUtils loadDatabaseMetadata:databaseUid];
				[aux addObject:databaseMetadata];
			}
			self.databaseMetadataArray = [aux copy];
		}
		[self.tableView reloadData];
	}];
}

#pragma mark - Override getters

- (NSArray *)localDatabaseUIDs
{
	if (_localDatabaseUIDs == nil) {
		[self reloadDatabaseList:nil];
	}
	return _localDatabaseUIDs;
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
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if ([self.localDatabaseUIDs count] > 0) {
		return @"Tap the name of the database you want to open.";
	}
	return @"You do not have any databases at the moment. Tap the add button to begin the guided database creation process.";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.localDatabaseUIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"Cell"];
    
    TSDatabaseMetadata *databaseMetadata = [self.databaseMetadataArray objectAtIndex:indexPath.row];
	cell.textLabel.text = [databaseMetadata name];
	TSAuthor *author = [databaseMetadata lastModifiedBy];
	if (author == nil) {
		author = [databaseMetadata createdBy];
	}
	NSString *aux = [TSDateUtils interfaceStringFromDate:[author date]];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", aux, [author name]];
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TSDatabaseMetadata *databaseMetadata = [self.databaseMetadataArray objectAtIndex:indexPath.row];
	TSSharedState *sharedState = [TSSharedState sharedState];
	sharedState.openDatabaseMetadata = databaseMetadata;
	sharedState.openDatabase = nil;
	sharedState.openDatabasePassword = nil;
	[self performSegueWithIdentifier:@"openDatabase" sender:nil];
}

#pragma mark - listeners

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"createNewDatabase"]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(localDatabaseListChanged:)
													 name:TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED
												   object:nil];
	}else if ([[segue identifier] isEqualToString:@"openDatabase"]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(databaseWasUnlockedSuccessfully:)
													 name:TS_NOTIFICATION_DATABASE_WAS_UNLOCKED_SUCCESSFULLY
												   object:nil];
	}
	[super prepareForSegue:segue sender:sender];
}

- (void)localDatabaseListChanged:(NSNotification *)notification
{
//	NSLog (@"received localDatabaseListChanged notification");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self reloadDatabaseList:nil];
}

- (void)databaseWasUnlockedSuccessfully:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	UIStoryboard *openDatabaseStoryboard = nil;
	if ([TSDeviceUtils isIPhone]) {
		openDatabaseStoryboard = [UIStoryboard storyboardWithName:@"OpenDatabaseStoryboard_iPhone" bundle:nil];
	}
	if (openDatabaseStoryboard) {
		UIViewController *initialViewController = [openDatabaseStoryboard instantiateInitialViewController];
		initialViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:initialViewController animated:YES completion:nil];
	}else {
		[TSNotifierUtils error:@"NOT YET IMPLEMENTED"];
	}
}

- (IBAction)switchToSandboxStoryboard:(id)sender {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(localDatabaseListChanged:)
												 name:TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED
											   object:nil];
	if (self.presentingViewController) {
		NSLog (@"Storyboard switch by dismissing self");
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}else {
		NSLog (@"Storyboard switch by modally presenting other");
		UIStoryboard *sandboxStoryboard = [UIStoryboard storyboardWithName:@"Sandbox" bundle:nil];
		UIViewController *sandboxInitialViewController = [sandboxStoryboard instantiateInitialViewController];
		sandboxInitialViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:sandboxInitialViewController animated:YES completion:nil];
	}
}

@end
