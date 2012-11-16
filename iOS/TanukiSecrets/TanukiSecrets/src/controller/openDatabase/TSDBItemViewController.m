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

@interface TSDBItemViewController ()

@property(nonatomic, strong) NSMutableDictionary *indexPathToFieldItem;
@property(nonatomic, assign) NSInteger numberOfSections;
@property(nonatomic, strong) NSMutableArray *numberOfRowsForSection;

@end

@implementation TSDBItemViewController

@synthesize indexPathToFieldItem, numberOfRowsForSection, numberOfSections;

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
	NSNumber *number = [self.numberOfRowsForSection objectAtIndex:section];
	if ([number intValue] == 1) {
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
		TSDBItemField *field = [self.indexPathToFieldItem objectForKey:indexPath];
		return field.name;
	}
	return nil;
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
				textView.text = @"Text hidden, visible only when editing.";
			}else {
				textView.text = field.value;
			}
		}
			break;
			
		case TSDBFieldType_URL: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"OpenUrlCell" forIndexPath:indexPath];
			UILabel *label = (UILabel *)[cell viewWithTag:1];
			label.text = field.name;
			label = (UILabel *)[cell viewWithTag:2];
			if (field.encrypted) {
				label.text = @"URL hidden, tap icon to open.";
			}else {
				label.text = field.value;
			}
		}
			break;
			
		default: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"QuickCopyCell" forIndexPath:indexPath];
			UILabel *label = (UILabel *)[cell viewWithTag:1];
			label.text = field.name;
			label = (UILabel *)[cell viewWithTag:2];
			if (field.encrypted) {
				label.text = @"Value hidden, tap icon to copy.";
			}else {
				label.text = field.value;
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
}

@end
