//
//  TSDBItemViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/16/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSDBItemViewController.h"

#import "TSDBItem.h"
#import "TSDBItemField.h"
#import "TSSharedState.h"
#import "TSCryptoUtils.h"
#import "TSUtils.h"
#import "TSNotifierUtils.h"
#import "TSStringUtils.h"

@interface TSDBItemViewController ()

@property(nonatomic, strong) NSMutableDictionary *indexPathToFieldItem;
@property(nonatomic, assign) NSInteger numberOfSections;
@property(nonatomic, strong) NSMutableArray *numberOfRowsForSection;
@property(nonatomic, strong) NSMutableArray *encryptedRowsShownPlaintext;

@end

@implementation TSDBItemViewController

@synthesize indexPathToFieldItem, numberOfRowsForSection, numberOfSections,
encryptedRowsShownPlaintext, performEditSegueOnLoad;

#pragma mark - worker methods

- (void)initializeTableStuctureFromItem:(TSDBItem *)item
{
	int section = 0;
	int row = 0;
	self.indexPathToFieldItem = [NSMutableDictionary dictionary];
	self.numberOfRowsForSection = [NSMutableArray array];
	for (TSDBItemField *itemField in item.fields) {
		switch (itemField.type) {
			case TSDBFieldType_TEXT: {
				//textarea fields are always in a separate section
				if (row > 0) {
					//current section already has rows, close section and advance section
					[self.numberOfRowsForSection addObject:[NSNumber numberWithInt:row]];
					section++;
				}
				//textarea is always at row 0 in the section
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
				[self.indexPathToFieldItem setObject:itemField forKey:indexPath];
				//close the section, size is always 1
				[self.numberOfRowsForSection addObject:[NSNumber numberWithInt:1]];
				section++;
				row = 0;
			}
				break;
				
			default: {
				//normal rows are simple, just group them together and advance the row count
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:section];
				[self.indexPathToFieldItem setObject:itemField forKey:indexPath];
				row++;
			}
				break;
		}
	}
	if (row > 0) {
		//last section had normal rows, close it
		[self.numberOfRowsForSection addObject:[NSNumber numberWithInt:row]];
		self.numberOfSections = section + 1;
	}else {
		//last section had nothing, meaning that the last field was a textarea field
		self.numberOfSections = section;
	}
	self.encryptedRowsShownPlaintext = [NSMutableArray array];
}

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	TSDBItem *item = [TSSharedState sharedState].currentItem;
	self.title = item.name;
	[self initializeTableStuctureFromItem:item];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (self.performEditSegueOnLoad) {
		self.performEditSegueOnLoad = NO;
		int64_t delayInMilliseconds = 300;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMilliseconds * NSEC_PER_MSEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self performSegueWithIdentifier:@"edit" sender:nil];
		});
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSNumber *number = [self.numberOfRowsForSection objectAtIndex:section];
    return [number integerValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
	TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
	switch (field.type) {
		case TSDBFieldType_TEXT: {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
			TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
			return field.name;
		}
			
		default:
			return nil;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
	switch (field.type) {
		case TSDBFieldType_TEXT:
			return 100;
			
		default:
			return self.tableView.rowHeight;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
	TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
	switch (field.type) {
		case TSDBFieldType_TEXT: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"TextareaCell" forIndexPath:indexPath];
			UITextView *textView = (UITextView *)[cell viewWithTag:1];
			if (field.encrypted) {
				if ([self.encryptedRowsShownPlaintext containsObject:indexPath]) {
					textView.text = [TSCryptoUtils tanukiDecryptField:field.value belongingToItem:field.parent.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
				}else {
					textView.text = @"Text hidden, tap to show.";
				}
			}else {
				textView.text = field.value;
			}
		}
			break;
			
		case TSDBFieldType_URL: {
			if ([TSStringUtils isBlank:field.value]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
				cell.textLabel.text = field.name;
				cell.detailTextLabel.text = nil;
			}else {
				cell = [tableView dequeueReusableCellWithIdentifier:@"OpenUrlCell" forIndexPath:indexPath];
				UILabel *label = (UILabel *)[cell viewWithTag:1];
				label.text = field.name;
				label = (UILabel *)[cell viewWithTag:2];
				if (field.encrypted) {
					if ([self.encryptedRowsShownPlaintext containsObject:indexPath]) {
						label.text = [TSCryptoUtils tanukiDecryptField:field.value belongingToItem:field.parent.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
					}else {
						label.text = @"URL hidden, tap to show.";
					}
				}else {
					label.text = field.value;
				}
			}
		}
			break;
			
		default: {
			if ([TSStringUtils isBlank:field.value]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
				cell.textLabel.text = field.name;
				cell.detailTextLabel.text = nil;
			}else {
				cell = [tableView dequeueReusableCellWithIdentifier:@"QuickCopyCell" forIndexPath:indexPath];
				UILabel *label = (UILabel *)[cell viewWithTag:1];
				label.text = field.name;
				label = (UILabel *)[cell viewWithTag:2];
				if (field.encrypted) {
					if (TS_DEV_DEBUG_ALL) {
						NSLog (@"row %@ is encrypted and plaintext array is %@", indexPath, [self.encryptedRowsShownPlaintext debugDescription]);
					}
					if ([self.encryptedRowsShownPlaintext containsObject:indexPath]) {
						label.text = [TSCryptoUtils tanukiDecryptField:field.value belongingToItem:field.parent.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
					}else {
						label.text = @"Value hidden, tap to show.";
					}
				}else {
					label.text = field.value;
				}
			}
		}
			break;
	}
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
	if ((field.encrypted) && ([self.encryptedRowsShownPlaintext containsObject:indexPath] == NO)) {
		[self.encryptedRowsShownPlaintext addObject:indexPath];
		[self.tableView reloadData];
		if (TS_DEV_DEBUG_ALL) {
			NSLog (@"tapped encrypted field %@, encrypted shown array is now %@", field.name, [self.encryptedRowsShownPlaintext debugDescription]);
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
	if ((field.encrypted) && ([self.encryptedRowsShownPlaintext containsObject:indexPath] == NO)) {
		return YES;
	}
	return NO;
}

#pragma mark - events

- (TSDBItemField *)itemFieldForEvent:(id)sender
{
	//	NSLog (@"%@ :: %@", [sender class], [sender debugDescription]);
	UIButton *button = (UIButton *)sender;
	//	NSLog (@"%@ :: %@", [button.superview class], [button.superview debugDescription]);
	//	NSLog (@"%@ :: %@", [button.superview.superview class], [button.superview.superview debugDescription]);
	UITableViewCell *cell = (UITableViewCell *)button.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	// 	NSLog (@"QuickCopy triggered :: %d / %d", indexPath.section, indexPath.row);
	
	return [self.indexPathToFieldItem objectForKey:indexPath];
}

- (NSString *)valueOfQuickActionFieldForEvent:(id)sender
{
	TSDBItemField *itemField = [self itemFieldForEvent:sender];
	if (itemField.encrypted) {
		return [TSCryptoUtils tanukiDecryptField:itemField.value belongingToItem:itemField.parent.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
	}else {
		return itemField.value;
	}
}

- (IBAction)quickCopy:(id)sender {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	TSDBItemField *itemField = [self itemFieldForEvent:sender];
	NSString *value = nil;
	if (itemField.encrypted) {
		value = [TSCryptoUtils tanukiDecryptField:itemField.value belongingToItem:itemField.parent.name usingSecret:[[TSSharedState sharedState] openDatabasePassword]];
	}else {
		value = itemField.value;
	}
	if ([TSStringUtils isNotBlank:value]) {
		pasteboard.string = value;
		[TSNotifierUtils infoAtTopOfScreen:[NSString stringWithFormat:@"%@ copied", itemField.name]];
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
	if ([segue.identifier isEqualToString:@"edit"]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(itemContentChanged:)
													 name:TS_NOTIFICATION_ITEM_CONTENT_CHANGED
												   object:nil];
	}
}

- (void)itemContentChanged:(NSNotification *)notification
{
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"received item content changed notification");
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[TSUtils foreground:^{
		TSDBItem *item = [TSSharedState sharedState].currentItem;
		self.title = item.name;
		[self initializeTableStuctureFromItem:item];
		[self.tableView reloadData];
	}];
}

@end
