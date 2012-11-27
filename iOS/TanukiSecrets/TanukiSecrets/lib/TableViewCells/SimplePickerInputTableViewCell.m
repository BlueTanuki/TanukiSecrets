//
//  SimplePickerInputTableViewCell.m
//  PickerCellDemo
//
//  Created by Tom Fewster on 10/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Modified by BlueTanuki

#import "SimplePickerInputTableViewCell.h"

@interface SimplePickerInputTableViewCell()

@property (nonatomic, strong) NSString *selectedValue;

@end

@implementation SimplePickerInputTableViewCell

@synthesize possibleValues, possibleValueLabels, delegate;
@synthesize selectedValue;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		self.picker.delegate = self;
		self.picker.dataSource = self;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
		self.picker.delegate = self;
		self.picker.dataSource = self;
    }
    return self;
}

- (void)setValue:(NSString *)value {
	self.selectedValue = value;
	if (self.possibleValueLabels) {
		NSUInteger index = [self.possibleValues indexOfObject:value];
		self.detailTextLabel.text = [self.possibleValueLabels objectAtIndex:index];
	}else {
		self.detailTextLabel.text = self.selectedValue;
	}
	[self.picker selectRow:[self.possibleValues indexOfObject:self.selectedValue] inComponent:0 animated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [self.possibleValues count];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	if (self.possibleValueLabels) {
		return [self.possibleValueLabels objectAtIndex:row];
	}
	return [self.possibleValues objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
	return 44.0f;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	return 300.0f; //pickerView.bounds.size.width - 20.0f;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//	NSLog (@"picker value changed to %@", [self.possibleValues objectAtIndex:row]);
	self.selectedValue = [self.possibleValues objectAtIndex:row];
	if (delegate && [delegate respondsToSelector:@selector(tableViewCell:didEndEditingWithValue:)]) {
		[delegate tableViewCell:self didEndEditingWithValue:self.selectedValue];
	}
}

@end
