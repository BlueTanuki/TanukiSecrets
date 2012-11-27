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

#pragma mark - view lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.editingItem = [[TSSharedState sharedState].currentItem editingCopy];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([TSStringUtils isBlank:self.editingItem.name]) {
		[self.nameTextField becomeFirstResponder];
	}
	[self.tableView reloadData];
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
			cell.textLabel.text = field.name != nil ? field.name : @"[name missing]";
			if (field.encrypted) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@], encrypted", [TSDBItemField interfaceStringForType:field.type]];
			}else {
				switch (field.type) {
					case TSDBFieldType_SECRET:
					case TSDBFieldType_TEXT:
						cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@]", [TSDBItemField interfaceStringForType:field.type]];
						break;
						
					default:
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", field.value != nil ? field.value : @"[value missing]"];
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
//		[self.tableView reloadData];
    }else if (editingStyle == UITableViewCellEditingStyleInsert) {
		TSDBItemField *newField = [[TSDBItemField alloc] init];
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
			[self.tableView reloadData];
		});
	}
}

- (IBAction)texteditingEnded:(id)sender {
	[self outsideTapped];
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
}

- (BOOL)tapGestureRecognizerConsumesEvent
{
	return NO;//this will allow the event to reach the other cells
}

@end
