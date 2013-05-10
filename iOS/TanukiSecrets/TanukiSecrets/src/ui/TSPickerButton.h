//
//  TSButtonWithPickerKeyboard.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 5/10/13.
//  Copyright (c) 2013 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TSPickerButton;

@protocol TSPickerButtonDelegate <NSObject>
@optional
- (void)pickerButton:(TSPickerButton *)button choseValue:(NSString *)value;
@end

@interface TSPickerButton : UIButton <UIKeyInput, UIPopoverControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	// For iPad
	UIPopoverController *popoverController;
	UIToolbar *inputAccessoryView;
}

@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, assign) BOOL doNotShowInputAccessoryView;

//values
@property (nonatomic, strong) NSArray *possibleValues;
//labels for values (must be the same size as values, if missing the values are shown)
@property (nonatomic, strong) NSArray *possibleValueLabels;

@property (weak) IBOutlet id <TSPickerButtonDelegate> delegate;

- (void)setValue:(NSString *)value;

@end
