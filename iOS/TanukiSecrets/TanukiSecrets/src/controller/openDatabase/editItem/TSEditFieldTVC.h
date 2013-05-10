//
//  TSEditFieldTVC.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/27/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSSelectiveTapCallbackTableViewController.h"

#import "SimplePickerInputTableViewCell.h"
#import "TSDBItemField.h"
#import "TSPickerButton.h"

@interface TSEditFieldTVC : TSSelectiveTapCallbackTableViewController<SimplePickerInputTableViewCellDelegate, TSPickerButtonDelegate>

@property (nonatomic, strong) TSDBItemField *editingField;

@end
