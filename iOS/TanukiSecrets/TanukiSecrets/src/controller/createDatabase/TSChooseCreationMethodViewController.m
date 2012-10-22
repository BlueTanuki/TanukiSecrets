//
//  TSChooseCreationMethodViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/19/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSChooseCreationMethodViewController.h"

#import <DropboxSDK/DropboxSDK.h>

@interface TSChooseCreationMethodViewController ()

@end

@implementation TSChooseCreationMethodViewController

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
	if (section == 0) {
		return @"How should the database be created?";
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Choose this option if you want to create a new empty database.";
			
		case 1:
			return @"Choose this option if you want to create the database from an already existing version stored in your Dropbox account.";

		case 2:
			return @"Choose this option if you want to create the database from an already existing iCloud version.";
			
		default:
			return @"This table has only 3 sections...";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
	switch (indexPath.section) {
		case 0:
			cell.textLabel.text = @"New database";
			break;
			
		case 1:
			cell.textLabel.text = @"Dropbox import";
			break;

		case 2:
			cell.textLabel.text = @"iCloud import";
			break;
	
		default:
			cell.textLabel.text = @"This table has only 3 sections...";
			break;
	}
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case 0:
			[self performSegueWithIdentifier:@"newDatabase" sender:nil];
			break;
			
		case 1:
			if ([[DBSession sharedSession] isLinked] == NO) {
				[self performSegueWithIdentifier:@"LinkWithDropbox" sender:nil];
			}else {
				[self performSegueWithIdentifier:@"Dropbox" sender:nil];
			}
			break;
			
		case 2:
			[self performSegueWithIdentifier:@"iCloud" sender:nil];
			break;
			
		default:
			NSLog (@"This table has only 3 sections...");
			break;
	}
}

#pragma mark - listeners

- (IBAction)cancel:(id)sender {
	[self.presentingViewController dismissModalViewControllerAnimated:YES];
}


@end
