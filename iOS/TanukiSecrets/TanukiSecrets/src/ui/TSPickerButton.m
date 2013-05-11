//
//  TSButtonWithPickerKeyboard.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 5/10/13.
//  Copyright (c) 2013 BlueTanuki. All rights reserved.
//

#import "TSPickerButton.h"

@interface TSPickerButton()

@property (nonatomic, strong) NSString *selectedValue;

@end

@implementation TSPickerButton

@synthesize picker, doNotShowInputAccessoryView, reactImmediatelyOnValueChange;

@synthesize possibleValues, possibleValueLabels, delegate;
@synthesize selectedValue;

- (void)initalizeInputView {
	self.picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
	self.picker.showsSelectionIndicator = YES;
	self.picker.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIViewController *popoverContent = [[UIViewController alloc] init];
		popoverContent.view = self.picker;
		popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
		popoverController.delegate = self;
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
		[self initalizeInputView];
		self.picker.delegate = self;
		self.picker.dataSource = self;
    }
    return self;
}

- (UIView *)inputView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return nil;
	} else {
		return self.picker;
	}
}

- (UIView *)inputAccessoryView {
	if (self.doNotShowInputAccessoryView) {
		return nil;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return nil;
	}
	if (!inputAccessoryView) {
		inputAccessoryView = [[UIToolbar alloc] init];
		inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
		inputAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[inputAccessoryView sizeToFit];
		CGRect frame = inputAccessoryView.frame;
		frame.size.height = 44.0f;
		inputAccessoryView.frame = frame;
		
		UIBarButtonItem *cancelBtn =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
		UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		UIBarButtonItem *doneBtn =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
		
		NSArray *array = [NSArray arrayWithObjects:cancelBtn, flexibleSpace, doneBtn, nil];
		[inputAccessoryView setItems:array];
	}
	return inputAccessoryView;
}

- (void)done:(id)sender {
	[self resignFirstResponder];
	if (self.reactImmediatelyOnValueChange == NO) {
		if (delegate && [delegate respondsToSelector:@selector(pickerButton:choseValue:)]) {
			[delegate pickerButton:self choseValue:self.selectedValue];
		}
	}
}

- (void)cancel:(id)sender {
	[self resignFirstResponder];
	if (delegate && [delegate respondsToSelector:@selector(choiceWasCancelledForPickerButton:)]) {
		[delegate choiceWasCancelledForPickerButton:self];
	}
}

- (BOOL)becomeFirstResponder {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGSize pickerSize = [self.picker sizeThatFits:CGSizeZero];
		CGRect frame = self.picker.frame;
		frame.size = pickerSize;
		self.picker.frame = frame;
		popoverController.popoverContentSize = pickerSize;
		[popoverController presentPopoverFromRect:self.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		// resign the current first responder
		for (UIView *subview in self.superview.subviews) {
			if ([subview isFirstResponder]) {
				[subview resignFirstResponder];
			}
		}
		return NO;
	} else {
		[self.picker setNeedsLayout];
	}
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	return [super resignFirstResponder];
}

- (void)deviceDidRotate:(NSNotification*)notification {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// we should only get this call if the popover is visible
		[popoverController presentPopoverFromRect:self.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		[self.picker setNeedsLayout];
	}
}

- (void)setValue:(NSString *)value {
	self.selectedValue = value;
	[self.picker selectRow:[self.possibleValues indexOfObject:self.selectedValue] inComponent:0 animated:YES];
}


#pragma mark -
#pragma mark Respond to touch and become first responder.

- (BOOL)canBecomeFirstResponder {
	return YES;
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)theText {
}

- (void)deleteBackward {
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate Protocol Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self resignFirstResponder];
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
	if (self.reactImmediatelyOnValueChange == YES) {
		if (delegate && [delegate respondsToSelector:@selector(pickerButton:choseValue:)]) {
			[delegate pickerButton:self choseValue:self.selectedValue];
		}
	}
}

@end
