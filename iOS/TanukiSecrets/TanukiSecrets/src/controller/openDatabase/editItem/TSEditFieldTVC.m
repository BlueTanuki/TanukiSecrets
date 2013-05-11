//
//  TSEditFieldTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/27/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSEditFieldTVC.h"

#import "TSCryptoUtils.h"
#import "TSSharedState.h"
#import "TSStringUtils.h"
#import "TSDBItemField.h"
#import "TSUtils.h"
#import "TSPickerButton.h"

@interface TSEditFieldTVC ()

@property (nonatomic, weak) UITableViewCell *nameCell;
@property (nonatomic, weak) UITextField *nameTextField;
@property (nonatomic, weak) UITableViewCell *typeCell;
@property (nonatomic, weak) UITableViewCell *encryptedCell;
@property (nonatomic, weak) UISwitch *encryptedSwitch;
@property (nonatomic, weak) UITableViewCell *valueCell;
@property (nonatomic, weak) UITextField *valueTextField;
@property (nonatomic, weak) UITextView *valueTextView;
@property (nonatomic, weak) UIButton *randomizePasswordButton;
@property (nonatomic, weak) TSPickerButton *autofillButton;

@property (nonatomic, assign) BOOL hasAutofill;
@property (nonatomic, strong) NSArray *autofillOptions;

@end

@implementation TSEditFieldTVC

@synthesize editingField;
@synthesize nameCell, nameTextField, typeCell, encryptedCell, encryptedSwitch, valueCell, valueTextField, valueTextView;
@synthesize randomizePasswordButton, autofillButton, hasAutofill, autofillOptions;

#pragma mark - worker methods

- (void)transferValuesToEditingField
{
	self.editingField.name = [TSStringUtils trim:self.nameTextField.text];
	if (self.editingField.type == TSDBFieldType_TEXT) {
		self.editingField.value= self.valueTextView.text;
	}else {
		self.editingField.value = self.valueTextField.text;
	}
}

- (void)prepareAutofillInfo
{
	self.hasAutofill = NO;
	TSSharedState *sharedState = [TSSharedState sharedState];
	NSString *name = self.editingField.name;
	if (self.nameTextField.text != nil) {
		name = self.nameTextField.text;
	}
	NSArray *aux = [[sharedState.openDatabase root] mostUsedValuesForFieldNamed:name ofType:self.editingField.type];
	if ([aux count] > 0) {
		self.hasAutofill = YES;
		self.autofillOptions = aux;
	}
	[self.tableView reloadData];
}

#pragma mark - view lifecycle

- (void)viewWillDisappear:(BOOL)animated
{
	self.editingField.name = self.nameTextField.text;
	self.editingField.encrypted = self.encryptedSwitch.on;
	NSString *value;
	if (self.editingField.type == TSDBFieldType_TEXT) {
		value = self.valueTextView.text;
	}else {
		value = self.valueTextField.text;
	}
	self.editingField.value = value;
	[self.nameTextField resignFirstResponder];
	[self.valueTextField resignFirstResponder];
	[self.valueTextView resignFirstResponder];
	
	[super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if ([TSStringUtils isBlank:self.editingField.name]) {
		self.title = @"New item";
	}else {
		self.title = self.editingField.name;
	}
	[self.navigationController setToolbarHidden:YES animated:YES];
	[self prepareAutofillInfo];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([TSStringUtils isBlank:self.editingField.name]) {
		[self.nameTextField becomeFirstResponder];
	}
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSLog (@"footer called");
//	return @"This is a footer. This is present just so you can see how nicely the table scrolls itself for no reason whatsoever.";
	if (self.editingField.type == TSDBFieldType_SECRET) {
		NSLog (@"randomhint");
		return @"Tap the die to generate a random password.";
	}else if (self.hasAutofill) {
		NSLog (@"autofill hint");
		return @"Tap the autofill icon to choose from a list of values previously used for similar fields.";
	}
	NSLog (@"empty");
	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.row == 3) && (self.editingField.type == TSDBFieldType_TEXT)) {
		return 140;
	}
	return self.tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	
	switch (indexPath.row) {
		case 0: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell" forIndexPath:indexPath];
			self.nameCell = cell;
			self.nameTextField = (UITextField *)[cell viewWithTag:1];
			self.nameTextField.text = self.editingField.name;
		}
			break;
			
		case 1: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell" forIndexPath:indexPath];
			self.typeCell = cell;
			SimplePickerInputTableViewCell *pickerCell = (SimplePickerInputTableViewCell *)cell;
			pickerCell.possibleValues = [NSArray arrayWithObjects:
											  [TSDBItemField stringForType:TSDBFieldType_DEFAULT],
											  [TSDBItemField stringForType:TSDBFieldType_SECRET],
											  [TSDBItemField stringForType:TSDBFieldType_URL],
											  [TSDBItemField stringForType:TSDBFieldType_NUMERIC],
											  [TSDBItemField stringForType:TSDBFieldType_TEXT],
											  nil];
			pickerCell.possibleValueLabels = [NSArray arrayWithObjects:
										 [TSDBItemField interfaceStringForType:TSDBFieldType_DEFAULT],
										 [TSDBItemField interfaceStringForType:TSDBFieldType_SECRET],
										 [TSDBItemField interfaceStringForType:TSDBFieldType_URL],
										 [TSDBItemField interfaceStringForType:TSDBFieldType_NUMERIC],
										 [TSDBItemField interfaceStringForType:TSDBFieldType_TEXT],
										 nil];
			pickerCell.textLabel.text = @"Type:";
			[pickerCell setValue:[TSDBItemField stringForType:self.editingField.type]];
			pickerCell.delegate = self;
			pickerCell.doNotShowInputAccessoryView = YES;
		}
			break;
			
		case 2: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"EncryptedCell" forIndexPath:indexPath];
			self.encryptedCell = cell;
			self.encryptedSwitch = (UISwitch *)[cell viewWithTag:1];
			self.encryptedSwitch.on = self.editingField.encrypted;
		}
			break;
			
		case 3: {
			if (self.editingField.type == TSDBFieldType_TEXT) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"LongValueCell" forIndexPath:indexPath];
				self.valueCell = cell;
				self.valueTextView = (UITextView *)[cell viewWithTag:1];
				self.valueTextView.text = self.editingField.value;
			}else if (self.editingField.type == TSDBFieldType_SECRET) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"SecretValueCell" forIndexPath:indexPath];
				self.valueCell = cell;
				self.valueTextField = (UITextField *)[cell viewWithTag:1];
				self.valueTextField.text = self.editingField.value;
				self.randomizePasswordButton = (UIButton *)[cell viewWithTag:2];
			}else {
				switch (self.editingField.type) {
					case TSDBFieldType_URL:
						cell = [tableView dequeueReusableCellWithIdentifier:@"UrlValueCell" forIndexPath:indexPath];
						break;
						
					case TSDBFieldType_NUMERIC:
						cell = [tableView dequeueReusableCellWithIdentifier:@"NumericValueCell" forIndexPath:indexPath];
						break;
						
					default: {
						if (self.hasAutofill) {
							cell = [tableView dequeueReusableCellWithIdentifier:@"TextWithAutofillCell" forIndexPath:indexPath];
						}else {
							cell = [tableView dequeueReusableCellWithIdentifier:@"TextValueCell" forIndexPath:indexPath];
						}
					}
						break;
				}
				self.valueCell = cell;
				self.valueTextField = (UITextField *)[cell viewWithTag:1];
				self.valueTextField.text = self.editingField.value;
				if (self.hasAutofill) {
					self.autofillButton = (TSPickerButton *)[cell viewWithTag:2];
					NSMutableArray *values = [NSMutableArray arrayWithObject:@""];
					[values addObjectsFromArray:self.autofillOptions];
					self.autofillButton.possibleValues = [values copy];
					NSMutableArray *labels = [NSMutableArray arrayWithObject:@"[Keep current value]"];
					[labels addObjectsFromArray:self.autofillOptions];
					self.autofillButton.possibleValueLabels = [labels copy];
					[self.autofillButton setValue:@""];
					self.autofillButton.delegate = self;
				}
			}
		}
			break;
			
		default:
			@throw @"internal error : table only has 4 rows";
			break;
	}
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.row == 1;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row != 1) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark - events

- (IBAction)texteditingEnded:(id)sender {
	[self outsideTapped];
}

- (IBAction)randomizeFieldValue:(id)sender {
	self.valueTextField.text = [TSCryptoUtils randomPassword];
//	[self.valueTextField resignFirstResponder];
}

- (IBAction)autofillFieldValue:(id)sender {
}

#pragma mark - SimplePickerInputTableViewCellDelegate

- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingWithValue:(NSString *)value
{
	if (cell == self.typeCell) {
		[self.typeCell resignFirstResponder];
		BOOL changed = NO;
		TSDBFieldType newFieldType = [TSDBItemField typeForString:value];
		if (newFieldType != self.editingField.type) {
			self.editingField.type = newFieldType;
			changed = YES;
		}
		if (changed) {
			self.editingField.value = nil;
			[self.tableView reloadData];
		}
		if (TS_DEV_DEBUG_ALL) {
			NSLog (@"picker callback ended, things changed: %d", changed);
		}
	}
	[self prepareAutofillInfo];
}

#pragma mark - TSPickerButtonDelegate

- (void)pickerButton:(TSPickerButton *)button choseValue:(NSString *)value
{
	if (button == self.autofillButton) {
		[self.autofillButton resignFirstResponder];
		if ([TSStringUtils isNotBlank:value]) {
			self.editingField.value = value;
			[self.tableView reloadData];
		}
	}
}

- (void)choiceWasCancelledForPickerButton:(TSPickerButton *)button
{
	if (button == self.autofillButton) {
		[self.autofillButton resignFirstResponder];
	}
}


#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	return [NSArray arrayWithObjects:self.nameCell, self.typeCell, self.encryptedCell, self.valueCell, nil];
}

- (void)tap:(CGPoint)tapLocation wasDetectedForView:(UIView *)view
{
//	NSLog (@"Tap %f %f", tapLocation.x, tapLocation.y);
	if ((view == self.nameCell) && ([self.nameTextField isFirstResponder] == NO)) {
		[self.nameTextField becomeFirstResponder];
	}
	if (view != self.nameCell) {
		[self.nameTextField resignFirstResponder];
	}
	if (view == self.valueCell) {
		if (self.editingField.type == TSDBFieldType_TEXT) {
			[self.valueTextView becomeFirstResponder];
		}else if (self.editingField.type == TSDBFieldType_SECRET) {
//			NSLog (@"Tap %f %f", tapLocation.x, tapLocation.y);
			CGRect rect = [self.randomizePasswordButton frame];
			//rect is in view's coordinate system, tapLocation in self.view's coordinate system
//			NSLog (@"Test for frame %f %f - %f %f",
//				   rect.origin.x, rect.origin.y,
//				   rect.origin.x + rect.size.height,
//				   rect.origin.y + rect.size.width);
			rect = [view convertRect:rect toView:self.view];
			//both rect and tapLocation now in self.view's coordinate system
//			NSLog (@"Test for frame %f %f - %f %f",
//				   rect.origin.x, rect.origin.y,
//				   rect.origin.x + rect.size.height,
//				   rect.origin.y + rect.size.width);
			if (CGRectContainsPoint(rect, tapLocation) == NO) {
				[self.valueTextField becomeFirstResponder];
			}
		}else {
			CGRect rect = [self.autofillButton frame];
			rect = [view convertRect:rect toView:self.view];
			if (CGRectContainsPoint(rect, tapLocation) == NO) {
				[self.valueTextField becomeFirstResponder];
			}else {
				[self.autofillButton becomeFirstResponder];
			}
		}
	}else {
		[self.valueTextField resignFirstResponder];
		[self.valueTextView resignFirstResponder];
		[self.autofillButton resignFirstResponder];
	}
	if (view != self.typeCell) {
		[self.typeCell resignFirstResponder];
	}
	[self transferValuesToEditingField];
}

- (void)outsideTapped
{
	[self.nameTextField resignFirstResponder];
	[self.typeCell resignFirstResponder];
	[self.autofillButton resignFirstResponder];
	[self.valueTextField resignFirstResponder];
	[self.valueTextView resignFirstResponder];
	[self transferValuesToEditingField];
	[self prepareAutofillInfo];
}

- (BOOL)tapGestureRecognizerConsumesEvent
{
	return NO;//this will allow the event to reach the other cells
}

@end
