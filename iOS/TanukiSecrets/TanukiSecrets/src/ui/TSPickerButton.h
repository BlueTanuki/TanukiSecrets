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
- (void)choiceWasCancelledForPickerButton:(TSPickerButton *)button;
@end

@interface TSPickerButton : UIButton <UIKeyInput, UIPopoverControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	// For iPad
	UIPopoverController *popoverController;
	UIToolbar *inputAccessoryView;
}

@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, assign) BOOL doNotShowInputAccessoryView;
@property (nonatomic, assign) BOOL reactImmediatelyOnValueChange;

//values
@property (nonatomic, strong) NSArray *possibleValues;
//labels for values (must be the same size as values, if missing the values are shown)
@property (nonatomic, strong) NSArray *possibleValueLabels;

@property (weak) IBOutlet id <TSPickerButtonDelegate> delegate;

- (void)setValue:(NSString *)value;

@end
