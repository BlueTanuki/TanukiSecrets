//
//  SimplePickerInputTableViewCell.h
//  PickerCellDemo
//
//  Created by Tom Fewster on 10/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Modified by BlueTanuki

#import "PickerInputTableViewCell.h"

@class SimplePickerInputTableViewCell;

@protocol SimplePickerInputTableViewCellDelegate <NSObject>
@optional
- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingWithValue:(NSString *)value;
@end

@interface SimplePickerInputTableViewCell : PickerInputTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) NSArray *possibleValues;
@property (weak) IBOutlet id <SimplePickerInputTableViewCellDelegate> delegate;

- (void)setValue:(NSString *)value;

@end
