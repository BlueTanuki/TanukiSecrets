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

@interface TSEditFieldTVC ()

@property (nonatomic, weak) UITableViewCell *nameCell;
@property (nonatomic, weak) UITextField *nameTextField;
@property (nonatomic, weak) UITableViewCell *typeCell;
@property (nonatomic, weak) UISwitch *encryptedSwitch;
@property (nonatomic, weak) UITableViewCell *valueCell;
@property (nonatomic, weak) UITextField *valueTextField;
@property (nonatomic, weak) UITextView *valueTextView;

@end

@implementation TSEditFieldTVC

@synthesize editingField;
@synthesize nameCell, nameTextField, typeCell, encryptedSwitch, valueCell, valueTextField, valueTextView;

#pragma mark - worker methods

- (void)setCorrectKeyboardTypeForValueTextField
{
	switch (self.editingField.type) {
		case TSDBFieldType_URL:
			self.valueTextField.keyboardType = UIKeyboardTypeURL;
			break;
			
		case TSDBFieldType_NUMERIC:
			self.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
			break;
			
		default:
			self.valueTextField.keyboardType = UIKeyboardTypeDefault;
			break;
	}
	self.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.valueTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	[self.valueTextField becomeFirstResponder];
	[self.valueTextField resignFirstResponder];
	if (TS_DEV_DEBUG_ALL) {
		NSLog (@"keyboard set to type %d", self.valueTextField.keyboardType);
	}
}

- (void)transferValuesToEditingField
{
	self.editingField.name = [TSStringUtils trim:self.nameTextField.text];
	if (self.editingField.type == TSDBFieldType_TEXT) {
		self.editingField.value= self.valueTextView.text;
	}else {
		self.editingField.value = self.valueTextField.text;
	}
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
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (self.editingField.type != TSDBFieldType_TEXT) {
		[self setCorrectKeyboardTypeForValueTextField];
	}
	if ([TSStringUtils isBlank:self.editingField.name]) {
		[self.nameTextField becomeFirstResponder];
	}
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
			}else {
				if (self.editingField.type == TSDBFieldType_SECRET) {
					cell = [tableView dequeueReusableCellWithIdentifier:@"SecretValueCell" forIndexPath:indexPath];
				}else {
					cell = [tableView dequeueReusableCellWithIdentifier:@"ValueCell" forIndexPath:indexPath];
				}
				self.valueCell = cell;
				self.valueTextField = (UITextField *)[cell viewWithTag:1];
				self.valueTextField.text = self.editingField.value;
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
	[self.valueTextField resignFirstResponder];
}

#pragma mark - SimplePickerInputTableViewCellDelegate

- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingWithValue:(NSString *)value
{
	BOOL changed = NO;
	TSDBFieldType newFieldType = [TSDBItemField typeForString:value];
	if (newFieldType != self.editingField.type) {
		self.editingField.type = newFieldType;
		changed = YES;
	}
	if (changed) {
		self.editingField.value = nil;
		[self setCorrectKeyboardTypeForValueTextField];
		[self.tableView reloadData];
	}
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	return [NSArray arrayWithObjects:self.nameCell, self.valueCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
	if ((view == self.nameCell) && ([self.nameTextField isFirstResponder] == NO)) {
		[self.nameTextField becomeFirstResponder];
	}
	if (view != self.nameCell) {
		[self.nameTextField resignFirstResponder];
	}
	if (view == self.valueCell) {
		if (self.editingField.type == TSDBFieldType_TEXT) {
			[self.valueTextView becomeFirstResponder];
		}else {
			[self setCorrectKeyboardTypeForValueTextField];
			[self.valueTextField becomeFirstResponder];
		}
	}else {
		[self.valueTextField resignFirstResponder];
		[self.valueTextView resignFirstResponder];
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
	[self.valueTextField resignFirstResponder];
	[self.valueTextView resignFirstResponder];
	[self transferValuesToEditingField];
}

- (BOOL)tapGestureRecognizerConsumesEvent
{
	return NO;//this will allow the event to reach the other cells
}

@end
