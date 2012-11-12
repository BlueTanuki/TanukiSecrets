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
#import "TSDBItemField.h"
#import "TSStringUtils.h"
#import "TSNotifierUtils.h"
#import "TSCryptoUtils.h"

@interface TSDBGroupViewController ()

@end

@implementation TSDBGroupViewController

@synthesize group = _group;

#pragma mark - override getters

- (TSDBGroup *)group
{
	if (_group == nil) {
		_group = [TSSharedState sharedState].openDatabase.root;
		if (_group == nil) {
			NSLog (@"FATAL : TSDBGroupViewController reached, but cannot access the root group of the currently open database");
			@throw @"internal failure";
		}
	}
	return _group;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (((self.group.subgroups == nil) || ([self.group.subgroups count] <= 0)) &&
		((self.group.items == nil) || ([self.group.items count] <= 0))) {
		return @"This group does not contain any items. Tap the add button to create a new item or subgroup here.";
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		
		cell.imageView.image = [UIImage imageNamed:@"folder.png"];
		TSDBGroup *subgroup = [self.group.subgroups objectAtIndex:indexPath.row];
		cell.textLabel.text = subgroup.name;
		if ((subgroup.subgroups == nil) || ([subgroup.subgroups count] <= 0)) {
			if ((subgroup.items == nil) || ([subgroup.items count] <= 0)) {
				cell.detailTextLabel.text = @"Empty";
			}else {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%d item(s)", [subgroup.items count]];
			}
		}else {
			if ((subgroup.items == nil) || ([subgroup.items count] <= 0)) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%d subgroup(s)", [subgroup.subgroups count]];
			}else {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%d subgroup(s), %d item(s)", [subgroup.subgroups count], [subgroup.items count]];
			}
		}
		
		return cell;
	}else {
		TSDBItem *item = [self.group.items objectAtIndex:indexPath.row];
		
		if ([TSStringUtils isBlank:item.defaultFieldName]) {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
			
			cell.imageView.image = [UIImage imageNamed:@"file.png"];
			cell.textLabel.text = item.name;
			cell.detailTextLabel.text = @"TBD";
			
			return cell;
		}else {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithButton" forIndexPath:indexPath];
			
			UILabel *label = (UILabel *)[cell viewWithTag:1];
			label.text = item.name;
			label = (UILabel *)[cell viewWithTag:2];
			label.text = @"TBD";
			
			return cell;
		}
	}
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 	NSLog (@"row selection triggered :: %d / %d", indexPath.section, indexPath.row);
   // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)quickCopy:(id)sender {
	NSLog (@"%@ :: %@", [sender class], [sender debugDescription]);
	UIButton *button = (UIButton *)sender;
	NSLog (@"%@ :: %@", [button.superview class], [button.superview debugDescription]);
	NSLog (@"%@ :: %@", [button.superview.superview class], [button.superview.superview debugDescription]);
	UITableViewCell *cell = (UITableViewCell *)button.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
 	NSLog (@"QuickCopy triggered :: %d / %d", indexPath.section, indexPath.row);
	
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	TSDBItem *item = [self.group.items objectAtIndex:indexPath.row];
	NSString *fieldName = item.defaultFieldName;
	TSDBItemField *itemField = [item fieldNamed:fieldName];
	if (itemField.encrypted) {
		pasteboard.string = [TSCryptoUtils tanukiDecryptField:itemField.value belongingToItem:item.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
	}else {
		pasteboard.string = itemField.value;
	}
	[TSNotifierUtils info:[NSString stringWithFormat:@"%@ copied", fieldName]];
}

@end
