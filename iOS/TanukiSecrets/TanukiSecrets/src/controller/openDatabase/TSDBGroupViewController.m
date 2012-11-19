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
#import "TSUtils.h"
#import "TSIOUtils.h"
#import "TSDBItemViewController.h"

@interface TSDBGroupViewController ()

@property (nonatomic, copy) NSIndexPath *deletedRowIndexPath;

@end

@implementation TSDBGroupViewController

@synthesize group = _group;
@synthesize deletedRowIndexPath;

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

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.group.parent == nil) {
		self.title = [[TSSharedState sharedState] openDatabaseMetadata].name;
	}else {
		self.title = self.group.name;
	}
	[self.tableView reloadData];
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
//		NSLog (@"%d subgroups", [self.group.subgroups count]);
		return [self.group.subgroups count];
	}
//	NSLog (@"%d items", [self.group.items count]);
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
		
		if ([TSStringUtils isBlank:item.quickActionFieldName]) {
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
			
			cell.imageView.image = [UIImage imageNamed:@"file.png"];
			cell.textLabel.text = item.name;
			if (([TSStringUtils isNotBlank:item.subtitleFieldName]) && ([item fieldNamed:item.subtitleFieldName].encrypted == NO)) {
				cell.detailTextLabel.text = [item fieldNamed:item.subtitleFieldName].value;
			}else {
				cell.detailTextLabel.text = nil;
			}
			
			return cell;
		}else {
			TSDBItemField *itemField = [item fieldNamed:item.quickActionFieldName];
			if ([TSStringUtils isBlank:itemField.value]) {
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
				switch (itemField.type) {
					case TSDBFieldType_URL:
						cell.imageView.image = [UIImage imageNamed:@"globe.png"];
						break;
						
					default:
						cell.imageView.image = [UIImage imageNamed:@"file.png"];
						break;
				}
				cell.textLabel.text = item.name;
				if (([TSStringUtils isNotBlank:item.subtitleFieldName]) && ([item fieldNamed:item.subtitleFieldName].encrypted == NO)) {
					cell.detailTextLabel.text = [item fieldNamed:item.subtitleFieldName].value;
				}else {
					cell.detailTextLabel.text = nil;
				}
				return cell;
			}
			
			UITableViewCell *cell;
			switch (itemField.type) {
				case TSDBFieldType_URL:
					cell = [tableView dequeueReusableCellWithIdentifier:@"OpenUrlCell" forIndexPath:indexPath];
					break;
					
				default:
					cell = [tableView dequeueReusableCellWithIdentifier:@"QuickCopyCell" forIndexPath:indexPath];
					break;
			}
			
			UILabel *label = (UILabel *)[cell viewWithTag:1];
			label.text = item.name;
			label = (UILabel *)[cell viewWithTag:2];
			if (([TSStringUtils isNotBlank:item.subtitleFieldName]) && ([item fieldNamed:item.subtitleFieldName].encrypted == NO)) {
				label.text = [item fieldNamed:item.subtitleFieldName].value;
			}else {
				label.text = nil;
			}
			
			return cell;
		}
		
	}
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
// 	NSLog (@"row selection triggered :: %d / %d", indexPath.section, indexPath.row);
	if ((indexPath.section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
		TSDBGroup *subgroup = [self.group.subgroups objectAtIndex:indexPath.row];
		TSDBGroupViewController *aux = [self.storyboard instantiateViewControllerWithIdentifier:@"TSDBGroupViewController"];
		aux.group = subgroup;
		[self.navigationController pushViewController:aux animated:YES];
	}else {
		TSDBItem *item = [self.group.items objectAtIndex:indexPath.row];
		[TSSharedState sharedState].currentItem = item;
		[self performSegueWithIdentifier:@"viewItem" sender:nil];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[TSSharedState sharedState].currentGroup = self.group;
	[TSSharedState sharedState].currentItem = nil;
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		self.deletedRowIndexPath = indexPath;
		NSString *message;
		NSString *title;
		if ((indexPath.section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
			TSDBGroup *subgroup = [self.group.subgroups objectAtIndex:indexPath.row];
			title = @"Please confirm recursive deletion of subgroup";
			message = [NSString stringWithFormat:@"You are about to recursively delete the subgroup named %@. That group and all its children will be deleted and cannot be recovered. Are you sure you want to delete this group?", subgroup.name];
		}else {
			TSDBItem *item = [self.group.items objectAtIndex:indexPath.row];
			title = @"Please confirm deletion of item";
			message = [NSString stringWithFormat:@"You are about to delete the item named %@. The item will be lost and cannot be recovered. Are you sure you want to delete this item?", item.name];
		}
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:self
											  cancelButtonTitle:@"NO"
											  otherButtonTitles:@"YES", nil];
		[alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
	if (([@"YES" isEqualToString:buttonText]) && (self.deletedRowIndexPath != nil)) {
		TSSharedState *sharedState = [TSSharedState sharedState];
		if ([sharedState encryptKeyReady] == NO) {
			[TSUtils notifyEncryptionKeyIsNotReady];
		}else {
			TSAuthor *author = [TSAuthor authorFromCurrentDevice];
			if ((self.deletedRowIndexPath.section == 0) && (self.group.subgroups != nil) && ([self.group.subgroups count] > 0)) {
				TSDBGroup *aux = [self.group.subgroups objectAtIndex:[self.deletedRowIndexPath row]];
				author.comment = [NSString stringWithFormat:@"recursively deleted group %@", [aux uniqueGlobalId]];
				[self.group.subgroups removeObjectAtIndex:[self.deletedRowIndexPath row]];
			}else {
				TSDBItem *aux = [self.group.items objectAtIndex:[self.deletedRowIndexPath row]];
				author.comment = [NSString stringWithFormat:@"deleted item %@", [aux uniqueGlobalId]];
				[self.group.items removeObjectAtIndex:[self.deletedRowIndexPath row]];
			}
			self.deletedRowIndexPath = nil;
			sharedState.openDatabaseMetadata.lastModifiedBy = author;
			
			if ([TSIOUtils createBackupFor:sharedState.openDatabaseMetadata.uid]) {
				
				
				NSData *encryptKey = [sharedState encryptKey];
				NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
																 havingMetadata:sharedState.openDatabaseMetadata
																	   usingKey:encryptKey];
				if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
					[self.tableView reloadData];
				}else {
					[TSNotifierUtils error:@"Local database writing failed."];
				}
			}else {
				[TSNotifierUtils error:@"Could not create backup of database."];
			}
		}
	}
}

#pragma mark - events

- (TSDBItem *)itemForEvent:(id)sender
{
	//	NSLog (@"%@ :: %@", [sender class], [sender debugDescription]);
	UIButton *button = (UIButton *)sender;
	//	NSLog (@"%@ :: %@", [button.superview class], [button.superview debugDescription]);
	//	NSLog (@"%@ :: %@", [button.superview.superview class], [button.superview.superview debugDescription]);
	UITableViewCell *cell = (UITableViewCell *)button.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	// 	NSLog (@"QuickCopy triggered :: %d / %d", indexPath.section, indexPath.row);
	
	return [self.group.items objectAtIndex:indexPath.row];
}

- (NSString *)valueOfQuickActionFieldForEvent:(id)sender
{
	TSDBItem *item = [self itemForEvent:sender];
	NSString *fieldName = item.quickActionFieldName;
	TSDBItemField *itemField = [item fieldNamed:fieldName];
	if (itemField.encrypted) {
		return [TSCryptoUtils tanukiDecryptField:itemField.value belongingToItem:item.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
	}else {
		return itemField.value;
	}
}

- (IBAction)quickCopy:(id)sender {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	TSDBItem *item = [self itemForEvent:sender];
	NSString *fieldName = item.quickActionFieldName;
	TSDBItemField *itemField = [item fieldNamed:fieldName];
	NSString *value = nil;
	if (itemField.encrypted) {
		value = [TSCryptoUtils tanukiDecryptField:itemField.value belongingToItem:item.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
	}else {
		value = itemField.value;
	}
	if ([TSStringUtils isNotBlank:value]) {
		pasteboard.string = value;
		[TSNotifierUtils infoAtTopOfScreen:[NSString stringWithFormat:@"%@ copied", fieldName]];
	}
}

- (IBAction)openURL:(id)sender {
	NSString *urlString = [self valueOfQuickActionFieldForEvent:sender];
	if ([TSStringUtils isNotBlank:urlString]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"add"]) {
		[TSSharedState sharedState].currentGroup = self.group;
		[TSSharedState sharedState].currentItem = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(databaseContentChanged:)
													 name:TS_NOTIFICATION_OPEN_DATABASE_CONTENT_CHANGED
												   object:nil];
	}else if ([segue.identifier isEqualToString:@"editItem"]) {
		TSDBItemViewController *destinationController = (TSDBItemViewController *)segue.destinationViewController;
		destinationController.performEditSegueOnLoad = YES;
	}
}

- (void)databaseContentChanged:(NSNotification *)notification
{
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"received database content changed notification");
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[TSUtils foreground:^{
		[self.tableView reloadData];
		if ([TSSharedState sharedState].currentItem != nil) {
			[self performSegueWithIdentifier:@"editItem" sender:nil];
		}else if ([TSSharedState sharedState].currentGroup != self.group) {
			TSDBGroup *subgroup = [self.group.subgroups lastObject];
			TSDBGroupViewController *aux = [self.storyboard instantiateViewControllerWithIdentifier:@"TSDBGroupViewController"];
			aux.group = subgroup;
			int64_t delayInMilliseconds = 300;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMilliseconds * NSEC_PER_MSEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[self.navigationController pushViewController:aux animated:YES];
			});
		}
	}];
}

@end
