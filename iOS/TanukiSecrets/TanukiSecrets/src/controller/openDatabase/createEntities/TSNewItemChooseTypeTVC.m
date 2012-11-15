//
//  TSNewItemChooseTypeTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/15/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewItemChooseTypeTVC.h"

#import "TSDBItem.h"
#import "TSSharedState.h"

@interface TSNewItemChooseTypeTVC ()

@end

@implementation TSNewItemChooseTypeTVC

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = [TSSharedState sharedState].currentItem.name;
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
			return @"What type of item do you want to create?";
			
		case 1:
			return @"System templates";
			
		case 2:
			return @"User templates";

		default:
			return @"?????";
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"This will simply create an empty item for you. You will then be taken to the editing "
			"view where you can add, one by one, all the fields of the new item. "
			"The much simpler and recommended way of creating items is by choosing the type "
			"from one of the templates below.";
			
		case 1:
			return @"These are built-in templates provided by TanukiSecrets, hopefully covering most needs.";
			
		case 2: {
			NSArray *aux = [TSSharedState userTemplates];
			if ((aux == nil) || ([aux count] <= 0)) {
				return @"You have not created any template yet. You can create "
				"new templates at any time, just choose the appropriate command in the detailed view of any existing item.";
			}
			return @"These are templates you created from existing items.";
		}
			
		default:
			return @"?????";
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return 1;
			
		case 1:
			return [[TSDBItem systemTemplates] count];
			
		case 2:
			return [[TSSharedState userTemplates] count];
			
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
	switch (indexPath.section) {
		case 0: {
			cell.textLabel.text = @"Free-form item";
		}
			break;
			
		case 1: {
			TSDBItem *item = [[TSDBItem systemTemplates] objectAtIndex:indexPath.row];
			cell.textLabel.text = item.name;
		}
			break;
			
		case 2: {
			TSDBItem *item = [[TSSharedState userTemplates] objectAtIndex:indexPath.row];
			cell.textLabel.text = item.name;
		}
			break;
			
		default: {
			cell.textLabel.text = @"??????";
		}
			break;
	}
    
    return cell;
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
