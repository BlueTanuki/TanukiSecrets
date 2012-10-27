//
//  TSNewDatabaseChooseNameVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/25/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewDatabaseChooseNameVC.h"

#import "TSDatabaseMetadata.h"
#import "TSStringUtils.h"
#import "TSNotifierUtils.h"
#import "TSIOUtils.h"
#import "TSSharedState.h"

#define DESCRIPTION_PLACEHOLDER_TEXT @"(optional) Enter a short description for this database."

@interface TSNewDatabaseChooseNameVC ()

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextView *description;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property(nonatomic, strong) TSDatabaseMetadata *databaseMetadata;
@property(nonatomic, strong) NSArray *localDatabaseNames;

@end

@implementation TSNewDatabaseChooseNameVC

@synthesize name, description, nextButton;
@synthesize databaseMetadata = _databaseMetadata;
@synthesize localDatabaseNames = _localDatabaseNames;

#pragma mark - override getters/setters

- (TSDatabaseMetadata *)databaseMetadata
{
	if (_databaseMetadata == nil) {
		_databaseMetadata = [[TSDatabaseMetadata alloc] init];
	}
	return _databaseMetadata;
}

- (NSArray *)localDatabaseNames
{
	if (_localDatabaseNames == nil) {
		NSArray *databaseUids = [TSIOUtils listDatabaseUids];
		NSMutableArray *aux = [NSMutableArray arrayWithCapacity:[databaseUids count]];
		for (NSString *databaseuid in databaseUids) {
			TSDatabaseMetadata *databaseMetadata = [TSIOUtils loadDatabaseMetadata:databaseuid];
			[aux addObject:databaseMetadata.name];
		}
		_localDatabaseNames = [aux copy];
	}
	return _localDatabaseNames;
}

#pragma mark - worker methods

- (BOOL)databaseNameIsValid
{
	NSString *wantedName = [TSStringUtils trim:self.name.text];
	if ([self.localDatabaseNames containsObject:wantedName]) {
		return NO;
	}
	return YES;
}

- (void)changeNextButtonStateIfNeeded
{
	if ([TSStringUtils isNotBlank:self.name.text]) {
		if ([self databaseNameIsValid]) {
			self.nextButton.enabled = YES;
			[self.nextButton addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
		}else {
			self.nextButton.enabled = NO;
			self.nextButton.titleLabel.text = @"Name already used";
			self.nextButton.titleLabel.textAlignment = NSTextAlignmentCenter;
		}
	}else {
		self.nextButton.enabled = NO;
	}
}

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.name becomeFirstResponder];
	if ([TSStringUtils isBlank:self.description.text]) {
		self.description.text = DESCRIPTION_PLACEHOLDER_TEXT;
		self.description.textColor = [UIColor lightGrayColor];
	}
}

#pragma mark - TSKeyboardDismissingViewController callbacks

- (NSArray *)viewsThatNeedKeyboard
{
	return [NSArray arrayWithObjects:self.name, self.description, nil];
}

- (void)viewWasTapped:(UIView *)view
{
//	if (view == self.name) {
//		NSLog (@"name was tapped");
//	}else if (view == self.description) {
//		NSLog (@"description was tapped");
//	}else {
//		NSLog (@"phantom view was tapped :: %@", [view debugDescription]);
//	}
	if (view == self.description) {
		if ([self.description.text isEqualToString:DESCRIPTION_PLACEHOLDER_TEXT]) {
			self.description.text = @"";
			self.description.textColor = [UIColor blackColor];
		}
	}else if ([TSStringUtils isBlank:self.description.text]) {
		self.description.text = DESCRIPTION_PLACEHOLDER_TEXT;
		self.description.textColor = [UIColor lightGrayColor];
	}
	[self changeNextButtonStateIfNeeded];
}

- (void)outsideTapped:(UIView *)viewThatLostTheKeyboard
{
//	if (viewThatLostTheKeyboard == self.name) {
//		NSLog (@"outside tapped, name lost keyboard");
//	}else if (viewThatLostTheKeyboard == self.description) {
//		NSLog (@"outside tapped, description lost keyboard");
//	}else if (viewThatLostTheKeyboard != nil) {
//		NSLog (@"outside tapped, phantom view lost keyboard :: %@", [viewThatLostTheKeyboard debugDescription]);
//	}else {
//		NSLog (@"outside tapped, keyboard was not lost");
//	}
	if ([TSStringUtils isBlank:self.description.text]) {
		self.description.text = DESCRIPTION_PLACEHOLDER_TEXT;
		self.description.textColor = [UIColor lightGrayColor];
	}
	[self changeNextButtonStateIfNeeded];
}

#pragma mark - events

- (IBAction)nameEditingEnded:(id)sender {
	[self.name resignFirstResponder];
	[self changeNextButtonStateIfNeeded];
}

- (IBAction)next:(id)sender {
	TSSharedState *sharedState = [TSSharedState sharedState];
	sharedState.openDatabaseMetadata = [TSDatabaseMetadata newDatabaseNamed:[TSStringUtils trim:self.name.text]];
	if ([TSStringUtils isNotBlank:self.description.text]) {
		sharedState.openDatabaseMetadata.description = [TSStringUtils trim:self.description.text];
	}
	[self performSegueWithIdentifier:@"next" sender:nil];
}

@end
