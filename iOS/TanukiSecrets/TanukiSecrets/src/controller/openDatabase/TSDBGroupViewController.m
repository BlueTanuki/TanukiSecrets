//
//  TSDBGroupViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/1/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDBGroupViewController.h"

#import "TSSharedState.h"
#import "TSDBGroup.h"
#import "TSDBItem.h"

@interface TSDBGroupViewController ()

@end

@implementation TSDBGroupViewController

@synthesize group;

#pragma mark - initailization

+ (TSDBGroupViewController *)viewControllerForGroup:(TSDBGroup *)group
{
	TSDBGroupViewController *ret = [[TSDBGroupViewController alloc] init];
	ret.group = group;
	return ret;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.group == nil) {
		self.group = [TSSharedState sharedState].openDatabase.root;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger ret = 0;
	if ((self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
		ret++;
	}
	if ((self.group.items != nil) && ([self.group.items count] > 0)) {
		ret++;
	}
    return ret;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ((section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
		return [self.group.subgroups count];
	}
	return [self.group.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	if ((indexPath.section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
		cell.imageView.image = [UIImage imageNamed:@"folder-blue_open.png"];
		TSDBGroup *subgroup = [self.group.subgroups objectAtIndex:indexPath.row];
		cell.textLabel.text = subgroup.name;
	}
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
