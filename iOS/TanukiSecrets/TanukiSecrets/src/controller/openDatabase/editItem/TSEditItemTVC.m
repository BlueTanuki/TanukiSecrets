//
//  TSEditItemTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/21/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSEditItemTVC.h"

#import "TSDBItem.h"
#import "TSSharedState.h"
#import "TSDBItemField.h"
#import "TSStringUtils.h"
#import "TSUtils.h"
#import "TSEditFieldTVC.h"
#import "TSCryptoUtils.h"
#import "TSIOUtils.h"
#import "TSNotifierUtils.h"

@interface TSEditItemTVC ()

@property (nonatomic, strong) TSDBItem* editingItem;
@property (nonatomic, strong) TSDBItemField *editingField;

@property (nonatomic, weak) UITableViewCell *nameCell;
@property (nonatomic, weak) UITextField *nameTextField;
@property (nonatomic, weak) UITableViewCell *quickActionCell;
@property (nonatomic, weak) UITableViewCell *subtitleCell;

@end

@implementation TSEditItemTVC

@synthesize editingItem, editingField;
@synthesize nameCell, nameTextField, quickActionCell, subtitleCell;

#pragma mark - validation

- (void)decryptAllFields
{
	//all fields must be decrypted while editing and re-encrypted on save
	//this is because the name of the item may change
	for (TSDBItemField *field in self.editingItem.fields) {
		if (field.encrypted) {
			field.value = [TSCryptoUtils tanukiDecryptField:field.value
											belongingToItem:self.editingItem.name
												usingSecret:[TSSharedState sharedState].openDatabasePassword];
		}
	}
}

- (NSString *)itemName
{
	return [TSStringUtils trim:self.nameTextField.text];
}

- (void)encryptAllFields
{
	//set the name back to the editing item and encrypt all needed fields
	self.editingItem.name = [self itemName];
	for (TSDBItemField *field in self.editingItem.fields) {
		if (field.encrypted) {
			field.value = [TSCryptoUtils tanukiEncryptField:field.value
											belongingToItem:self.editingItem.name
												usingSecret:[TSSharedState sharedState].openDatabasePassword];
		}
	}
}

- (NSString *)editedItemError
{
	NSString *name = [self itemName];
	if ([TSStringUtils isBlank:name]) {
		return @"The item must have a name.";
	}
	TSSharedState *sharedState = [TSSharedState sharedState];
//	NSLog (@"%@ %@ %d", name, sharedState.currentItem.name, [name caseInsensitiveCompare:sharedState.currentItem.name]);
	if ([name caseInsensitiveCompare:sharedState.currentItem.name] != NSOrderedSame) {
//		NSLog (@"%d", [sharedState.currentItem.parent.items count]);
		for (TSDBItem *item in sharedState.currentItem.parent.items) {
//			NSLog (@"%@ %d", item.name, [name caseInsensitiveCompare:item.name]);
			if ([name caseInsensitiveCompare:item.name] == NSOrderedSame) {
				return @"The current group already has an item with the given name. "
				"You are not allowed to have two items with the same name in the same group.";
			}
		}
	}
	NSMutableArray *fieldNames = [NSMutableArray arrayWithCapacity:[self.editingItem.fields count]];
	for (TSDBItemField *field in self.editingItem.fields) {
		if ([TSStringUtils isBlank:field.name]) {
			return @"You have at least one field without a name. Fields without names are not allowed.";
		}
		if ([fieldNames containsObject:[field.name lowercaseString]]) {
			return [NSString stringWithFormat:@"You have two fields named %@. Having two fields with the same name is not allowed.", [field.name lowercaseString]];
		}
		[fieldNames addObject:[field.name lowercaseString]];
	}
	return nil;
}

- (NSString *)editedItemWarning
{
	if ([TSStringUtils isBlank:self.editingItem.quickActionFieldName]) {
		return @"Consider choosing a field for this item's quick action.";
	}
	if ([TSStringUtils isBlank:self.editingItem.subtitleFieldName]) {
		return @"Consider choosing a subtitle field for this item.";
	}
	for (TSDBItemField *field in self.editingItem.fields) {
		if ([TSStringUtils isBlank:field.value]) {
			return [NSString stringWithFormat:@"You din not set a value for the field %@.", field.name];
		}
		if ((field.type == TSDBFieldType_SECRET) && (field.encrypted == NO)) {
			return [NSString stringWithFormat:@"The field named %@ is a secret. Consider marking it as encrypted.", field.name];
		}
		if (field.type == TSDBFieldType_URL) {
			NSURL *url = [NSURL URLWithString:field.value];
			if (url == nil) {
				return [NSString stringWithFormat:@"The URL for field %@ is malformed.", field.name];
			}else if ([[UIApplication sharedApplication] canOpenURL:url] == NO) {
				return [NSString stringWithFormat:@"The URL for field %@ cannot be opened from this app.", field.name];
			}
		}
	}
	return nil;
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.editingItem = [[TSSharedState sharedState].currentItem editingCopy];
	[self decryptAllFields];
	self.title = [TSSharedState sharedState].currentItem.name;
//	NSLog (@"viewDidLoad");
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	NSMutableArray *existingFieldNames = [[NSMutableArray alloc] initWithCapacity:[self.editingItem.fields count]];
	for (TSDBItemField *field in self.editingItem.fields) {
		if ([TSStringUtils isNotBlank:field.name]) {
			[existingFieldNames addObject:field.name];
		}
	}
	if ([existingFieldNames containsObject:self.editingItem.quickActionFieldName] == NO) {
		self.editingItem.quickActionFieldName = nil;
	}
	if ([existingFieldNames containsObject:self.editingItem.subtitleFieldName] == NO) {
		self.editingItem.subtitleFieldName = nil;
	}
	[self.navigationController setToolbarHidden:NO animated:YES];
//	NSLog (@"viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([TSStringUtils isBlank:self.editingItem.name]) {
		[self.nameTextField becomeFirstResponder];
	}
	[self.tableView reloadData];
//	NSLog (@"viewDidAppear");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Item properties";
			
		case 1:
			return @"Fields";
			
		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 1) {
		if (self.tableView.editing) {
			return @"Drag rows to change the order of the fields. Tap and hold to exit editing mode.";
		}
		return @"Tap and hold to enter editing mode.";
	}
	NSString *error = [self editedItemError];
	if ([TSStringUtils isNotBlank:error]) {
//		NSLog (@"Footer is an error : %@", error);
		return [NSString stringWithFormat:@"WARNING: %@", error];
	}
	NSString *warning = [self editedItemWarning];
	if ([TSStringUtils isNotBlank:warning]) {
//		NSLog (@"Footer is a warning : %@", warning);
		return [NSString stringWithFormat:@"HINT: %@", warning];
	}
//	NSLog (@"Footer is empty");
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return 3;
			
		case 1:
			return 1 + [self.editingItem.fields count];
			
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	
	if (indexPath.section == 0) {
		//item-level metadata
		if (indexPath.row == 0) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell" forIndexPath:indexPath];
			self.nameCell = cell;
			self.nameTextField = (UITextField *)[cell viewWithTag:1];
			self.nameTextField.text = self.editingItem.name;
		}else {
			cell = [tableView dequeueReusableCellWithIdentifier:@"SimplePickerCell" forIndexPath:indexPath];
			SimplePickerInputTableViewCell *pickerCell = (SimplePickerInputTableViewCell *)cell;
			NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:1 + [self.editingItem.fields count]];
			[values addObject:@"None"];
			for (TSDBItemField *field in self.editingItem.fields) {
				if ([TSStringUtils isNotBlank:field.name]) {
					[values addObject:field.name];
				}
			}
			pickerCell.possibleValues = [values copy];
			if (indexPath.row == 1) {
				pickerCell.textLabel.text = @"Quick action:";
				if ([TSStringUtils isBlank:self.editingItem.quickActionFieldName]) {
					[pickerCell setValue:@"None"];
				}else {
					[pickerCell setValue:self.editingItem.quickActionFieldName];
				}
				self.quickActionCell = pickerCell;
			}else {
				pickerCell.textLabel.text = @"Subtitle:";
				if ([TSStringUtils isBlank:self.editingItem.subtitleFieldName]) {
					[pickerCell setValue:@"None"];
				}else {
					[pickerCell setValue:self.editingItem.subtitleFieldName];
				}
				self.subtitleCell = pickerCell;
			}
			pickerCell.delegate = self;
			pickerCell.doNotShowInputAccessoryView = YES;
		}
	}else {
		//fields
		if (indexPath.row == [self.editingItem.fields count]) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"AddFieldCell" forIndexPath:indexPath];
		}else {
			TSDBItemField *field = [self.editingItem.fields objectAtIndex:indexPath.row];
			cell = [tableView dequeueReusableCellWithIdentifier:@"ExistingFieldCell" forIndexPath:indexPath];
			if ([TSStringUtils isBlank:field.name]) {
				cell.textLabel.text = @"[name missing]";
			}else {
				cell.textLabel.text = field.name;
			}
			if (field.encrypted) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@], encrypted", [TSDBItemField interfaceStringForType:field.type]];
			}else {
				switch (field.type) {
					case TSDBFieldType_SECRET:
					case TSDBFieldType_TEXT:
						cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@]", [TSDBItemField interfaceStringForType:field.type]];
						break;
						
					case TSDBFieldType_URL: {
						if ([TSStringUtils isBlank:field.value]) {
							cell.detailTextLabel.text = @"[value missing]";
						}else {
							if ([field.value hasPrefix:@"www."]) {
								field.value = [NSString stringWithFormat:@"http://%@", field.value];
							}
							cell.detailTextLabel.text = field.value;
						}
					}
						break;
						
					default: {
						if ([TSStringUtils isBlank:field.value]) {
							cell.detailTextLabel.text = @"[value missing]";
						}else {
							cell.detailTextLabel.text = field.value;
						}
					}
						break;
				}
			}
		}
	}
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.editingItem.fields count]) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
//	NSLog (@"commit editing with style %d for %@", editingStyle, [indexPath debugDescription]);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		TSDBItemField *deletedField = [self.editingItem.fields objectAtIndex:indexPath.row];
		if ([self.editingItem.quickActionFieldName isEqualToString:deletedField.name]) {
			self.editingItem.quickActionFieldName = nil;
		}
		if ([self.editingItem.subtitleFieldName isEqualToString:deletedField.name]) {
			self.editingItem.subtitleFieldName = nil;
		}
        [self.editingItem.fields removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		if (TS_DEV_DEBUG_ALL) {
			NSLog(@"calling reloadData after row was deleted");
		}
		[self.tableView reloadData];
    }else if (editingStyle == UITableViewCellEditingStyleInsert) {
		TSDBItemField *newField = [[TSDBItemField alloc] init];
		if (self.editingItem.fields == nil) {
			self.editingItem.fields = [NSMutableArray array];
		}
		[self.editingItem.fields addObject:newField];
		self.editingField = newField;
		[self performSegueWithIdentifier:@"editField" sender:nil];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		return indexPath.row < [self.editingItem.fields count];
	}
	return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
	   toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
//	NSLog (@"Proposed relocation from %@ to %@", [sourceIndexPath debugDescription], [proposedDestinationIndexPath debugDescription]);
	if (proposedDestinationIndexPath.section != 1) {
		return [NSIndexPath indexPathForRow:0 inSection:1];
	}
	if (proposedDestinationIndexPath.row >= [self.editingItem.fields count]) {
		return [NSIndexPath indexPathForRow:[self.editingItem.fields count]-1 inSection:1];
	}
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
//	NSLog (@"Moving row from %@ to %@", [sourceIndexPath debugDescription], [destinationIndexPath debugDescription]);
	TSDBItemField *movedField = [self.editingItem.fields objectAtIndex:sourceIndexPath.row];
	[self.editingItem.fields removeObjectAtIndex:sourceIndexPath.row];
	[self.editingItem.fields insertObject:movedField atIndex:destinationIndexPath.row];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		if (indexPath.row == [self.editingItem.fields count]) {
			TSDBItemField *newField = [[TSDBItemField alloc] init];
			if (self.editingItem.fields == nil) {
				self.editingItem.fields = [NSMutableArray array];
			}
			[self.editingItem.fields addObject:newField];
			self.editingField = newField;
		}else {
			self.editingField = [self.editingItem.fields objectAtIndex:indexPath.row];
		}
		[self performSegueWithIdentifier:@"editField" sender:nil];
	}else {
		if (indexPath.row == 0) {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

#pragma mark - events

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([@"editField" isEqualToString:segue.identifier]) {
		self.editingItem.name = [self itemName];
		TSEditFieldTVC *destinationController = (TSEditFieldTVC *)[segue destinationViewController];
		destinationController.editingField = self.editingField;
	}
}

- (IBAction)cancel:(id)sender {
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)longTap:(UILongPressGestureRecognizer *)sender {
//	NSLog (@"long tap received, sender is %@", [sender debugDescription]);
	if (sender.state == UIGestureRecognizerStateBegan) {
		if (self.tableView.editing) {
			[self.tableView setEditing:NO animated:YES];
		}else {
			[self.tableView setEditing:YES animated:YES];
		}
		int64_t delayInMilliseconds = 200;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMilliseconds * NSEC_PER_MSEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if (TS_DEV_DEBUG_ALL) {
				NSLog(@"calling reloadData after long tap detected");
			}
			[self.tableView reloadData];
		});
	}
}

- (IBAction)texteditingEnded:(id)sender {
	[self outsideTapped];
	if (TS_DEV_DEBUG_ALL) {
		NSLog(@"calling reloadData after text editing ended");
	}
	[self.tableView reloadData];
}

- (IBAction)save:(id)sender {
	NSString *error = [self editedItemError];
	TSSharedState *sharedState = [TSSharedState sharedState];
	if ([TSStringUtils isNotBlank:error]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation error, cannot save item."
														message:error
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}else if ([sharedState encryptKeyReady] == NO) {
		[TSUtils notifyEncryptionKeyIsNotReady];
	}else {
		[self encryptAllFields];
		[sharedState.currentItem commitEditingChanges:self.editingItem];
		TSAuthor *author = [TSAuthor authorFromCurrentDevice];
		author.comment = [NSString stringWithFormat:@"saved item %@", [sharedState.currentItem uniqueGlobalId]];
		sharedState.openDatabaseMetadata.lastModifiedBy = author;
		
		if ([TSIOUtils createBackupFor:sharedState.openDatabaseMetadata.uid]) {
			NSData *encryptKey = [sharedState encryptKey];
			NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
															 havingMetadata:sharedState.openDatabaseMetadata
																   usingKey:encryptKey];
			if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
				[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
//				[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
//					NSNotification *notificaton = [NSNotification notificationWithName:TS_NOTIFICATION_ITEM_CONTENT_CHANGED object:nil];
//					[[NSNotificationCenter defaultCenter] postNotification:notificaton];
//				}];
			}else {
				[TSNotifierUtils error:@"Local database writing failed."];
				[self decryptAllFields];
			}
		}else {
			[TSNotifierUtils error:@"Could not create backup of database."];
			[self decryptAllFields];
		}
	}
}

- (IBAction)saveAsTemplate:(id)sender {
	NSString *error = nil;
	NSString *name = [self itemName];
	if ([TSStringUtils isBlank:name]) {
		error = @"The item must have a name.";
	}
	TSSharedState *sharedState = [TSSharedState sharedState];
	for (TSDBItem *item in sharedState.templatesDatabase.root.items) {
		if ([name caseInsensitiveCompare:item.name] == NSOrderedSame) {
			error = @"You already have a template with the same name. "
			"You must choose another name for the item, then try to save it as a template again.";
		}
	}
	NSMutableArray *fieldNames = [NSMutableArray arrayWithCapacity:[self.editingItem.fields count]];
	for (TSDBItemField *field in self.editingItem.fields) {
		if ([TSStringUtils isBlank:field.name]) {
			error = @"You have at least one field without a name. Fields without names are not allowed.";
		}
		if ([fieldNames containsObject:[field.name lowercaseString]]) {
			error =  [NSString stringWithFormat:@"You have two fields named %@. Having two fields with the same name is not allowed.", [field.name lowercaseString]];
		}
		[fieldNames addObject:[field.name lowercaseString]];
	}
	
	if ([TSStringUtils isNotBlank:error]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation error, cannot save template."
														message:error
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}else  {
		TSDBItem *editingItemTemplate = [self.editingItem createTemplate];
		[sharedState.templatesDatabase.root addItem:editingItemTemplate];
		if ([TSIOUtils saveTemplatesDatabase:sharedState.templatesDatabase]) {
			[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
				[TSNotifierUtils infoAtTopOfScreen:[NSString stringWithFormat:@"Template %@ saved.", editingItemTemplate.name]];
			}];
		}else {
			[TSNotifierUtils errorAtTopOfScreen:@"Failed to save template."];
		}
	}
}

#pragma mark - SimplePickerInputTableViewCellDelegate

- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingWithValue:(NSString *)value
{
	BOOL changed = NO;
	if (cell == self.quickActionCell) {
		if ([@"None" isEqualToString:value]) {
			if (self.editingItem.quickActionFieldName != nil) {
				changed = YES;
			}
			self.editingItem.quickActionFieldName = nil;
		}else {
			if (self.editingItem.quickActionFieldName != value) {
				changed = YES;
			}
			self.editingItem.quickActionFieldName = value;
		}
	}else {
		if ([@"None" isEqualToString:value]) {
			if (self.editingItem.subtitleFieldName != nil) {
				changed = YES;
			}
			self.editingItem.subtitleFieldName = nil;
		}else {
			if (self.editingItem.subtitleFieldName != value) {
				changed = YES;
			}
			self.editingItem.subtitleFieldName = value;
		}
	}
	if (changed) {
		if (TS_DEV_DEBUG_ALL) {
			NSLog(@"calling reloadData after pickerInput was changed");
		}
		[self.tableView reloadData];
	}
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	if (self.tableView.editing) {
		return nil;
	}
	return [NSArray arrayWithObjects:self.nameCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
	if ((view == self.nameCell) && ([self.nameTextField isFirstResponder] == NO)) {
		[self.nameTextField becomeFirstResponder];
	}
	if (view != self.nameCell) {
		[self.nameTextField resignFirstResponder];
		self.editingItem.name = [self itemName];
	}
	if (view != self.quickActionCell) {
		[self.quickActionCell resignFirstResponder];
	}
	if (view != self.subtitleCell) {
		[self.subtitleCell resignFirstResponder];
	}
}

- (void)outsideTapped
{
	[self.nameTextField resignFirstResponder];
	[self.quickActionCell resignFirstResponder];
	[self.subtitleCell resignFirstResponder];
	self.editingItem.name = [self itemName];
}

- (BOOL)tapGestureRecognizerConsumesEvent
{
	return NO;//this will allow the event to reach the other cells
}

@end
