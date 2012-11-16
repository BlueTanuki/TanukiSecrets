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
#import "TSUtils.h"
#import "TSNotifierUtils.h"
#import "TSCryptoUtils.h"
#import "TSIOUtils.h"

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
			return @"Just an empty item, without any predefined fields. Not recommended, whenever possible use a template.";
			
		case 1:
			return @"These are built-in templates provided by TanukiSecrets, hopefully "
			"providing a good starting point for most cases.";
			
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
	TSSharedState *sharedState = [TSSharedState sharedState];
	if ([sharedState encryptKeyReady] == NO) {
		[TSUtils notifyEncryptionKeyIsNotReady];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	
	NSString *itemName = sharedState.currentItem.name;
	TSDBItem *createdItem;
	switch (indexPath.section) {
		case 0: 
			createdItem = sharedState.currentItem;
			break;
			
		case 1: {
			TSDBItem *item = [[TSDBItem systemTemplates] objectAtIndex:indexPath.row];
			createdItem = [item createTemplate];
			createdItem.name = itemName;
		}
			break;
			
		case 2: {
			TSDBItem *item = [[TSSharedState userTemplates] objectAtIndex:indexPath.row];
			createdItem = [item createTemplate];
			createdItem.name = itemName;
		}
			break;
			
		default:
			[TSNotifierUtils error:@"Unknown row selection!!!"];
		return;
	}
	
	TSAuthor *author = [TSAuthor authorFromCurrentDevice];
	author.comment = [NSString stringWithFormat:@"added item %@ as child of %@", itemName, [sharedState.currentGroup uniqueGlobalId]];
	sharedState.openDatabaseMetadata.lastModifiedBy = author;
	createdItem.parent = sharedState.currentGroup;
	[sharedState.currentGroup addItem:createdItem];
	//NOTE: adding a new item does not trigger a backup, the operation is too irrelevant.
	NSData *encryptKey = [sharedState encryptKey];
	NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
													 havingMetadata:sharedState.openDatabaseMetadata
														   usingKey:encryptKey];
	
	if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
		sharedState.currentItem = createdItem;
		[[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
			NSNotification *notification = [NSNotification notificationWithName:TS_NOTIFICATION_OPEN_DATABASE_CONTENT_CHANGED object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}];
	}else {
		[TSNotifierUtils error:@"Local database writing failed"];
	}
}

@end
