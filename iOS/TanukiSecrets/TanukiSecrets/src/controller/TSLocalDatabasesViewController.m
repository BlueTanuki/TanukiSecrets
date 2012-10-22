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

@interface TSLocalDatabasesViewController ()

@property(nonatomic, strong) NSArray *localDatabaseUIDs;
@property(nonatomic, strong) NSArray *databaseMetadataArray;

@end

@implementation TSLocalDatabasesViewController

@synthesize localDatabaseUIDs = _localDatabaseUIDs;
@synthesize databaseMetadataArray;

#pragma mark - Override getters

- (NSArray *)localDatabaseUIDs
{
	if (_localDatabaseUIDs == nil) {
		_localDatabaseUIDs = [TSIOUtils listDatabaseUids];
		if (_localDatabaseUIDs != nil) {
			NSMutableArray *aux = [NSMutableArray arrayWithCapacity:[_localDatabaseUIDs count]];
			for (NSString *databaseUid in _localDatabaseUIDs) {
				TSDatabaseMetadata *databaseMetadata = [TSIOUtils loadDatabaseMetadata:databaseUid];
				[aux addObject:databaseMetadata];
			}
			self.databaseMetadataArray = [aux copy];
		}
	}
	return _localDatabaseUIDs;
}

#pragma mark - presenting view controller

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
	_localDatabaseUIDs = nil;
	[super dismissModalViewControllerAnimated:animated];
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
