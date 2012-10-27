//
//  TSNewDatabaseSecuritySettingsVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/26/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewDatabaseSecuritySettingsVC.h"
#import <math.h>

#import "TSSharedState.h"
#import "TSStringUtils.h"
#import "TSCryptoUtils.h"
#import "TSNotifierUtils.h"
#import "TSIOUtils.h"
#import "TSUtils.h"

@interface TSNewDatabaseSecuritySettingsVC ()

@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *password2;
@property (weak, nonatomic) IBOutlet UISlider *hashUsedMemory;
@property (weak, nonatomic) IBOutlet UIButton *createDatabase;
@property (weak, nonatomic) IBOutlet UIButton *testEncryptionButton;

@end

@implementation TSNewDatabaseSecuritySettingsVC

@synthesize password, password2, hashUsedMemory, createDatabase, testEncryptionButton;

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.password becomeFirstResponder];
}

#pragma mark - worker methods

- (void)changeNextButtonStateIfNeeded
{
	if (([TSStringUtils isNotBlank:self.password.text]) && ([TSStringUtils isNotBlank:self.password2.text])) {
		if ([self.password.text isEqualToString:self.password2.text]) {
			self.createDatabase.enabled = YES;
		}else {
			self.createDatabase.enabled = NO;
			self.createDatabase.titleLabel.text = @"Passphrase missmatch";
			self.createDatabase.titleLabel.textAlignment = NSTextAlignmentCenter;
		}
	}else {
		self.createDatabase.enabled = NO;
	}
}

- (BOOL)passwordIsWeak:(NSString *)pass
{
	if ([pass length] < 8) {
		return YES;
	}
	if ([pass length] > 19) {
		return NO;
	}
	NSRange aux;
	aux = [pass rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]];
	if (!aux.length) {
		return YES;
	}
	aux = [pass rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
	if (!aux.length) {
		return YES;
	}
	aux = [pass rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
	if (!aux.length) {
		return YES;
	}
	aux = [pass rangeOfCharacterFromSet:[NSCharacterSet symbolCharacterSet]];
	if (!aux.length) {
		return YES;
	}
	return NO;
}

- (void)doCreateDatabase
{
	TSSharedState *sharedState = [TSSharedState sharedState];
//	self.createDatabase.titleLabel.text = [NSString stringWithFormat:@"Creating database %@", sharedState.openDatabaseMetadata.name];
	self.createDatabase.enabled = NO;
	self.createDatabase.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.createDatabase.titleLabel.text = [NSString stringWithFormat:@"Creating database %@", sharedState.openDatabaseMetadata.name];
	[TSUtils background:^{
		NSString *secret = self.password.text;
		if ([secret isEqualToString:self.password2.text] == NO) {
			@throw @"Internal logic fail. Passwords do not match.";
		}
		sharedState.openDatabaseMetadata.hashUsedMemory = (int)self.hashUsedMemory.value;
		NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
														 havingMetadata:sharedState.openDatabaseMetadata
															usingSecret:secret];
		if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
			[TSUtils foreground:^{
				NSNotification *notificatopn = [NSNotification notificationWithName:TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED object:nil];
				[[NSNotificationCenter defaultCenter] postNotification:notificatopn];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
			}];
		}else {
			[TSNotifierUtils error:@"Local database writing failed"];
		}
	}];
}

#pragma mark - TSKeyboardDismissingViewController callbacks

- (NSArray *)viewsThatNeedKeyboard
{
	return [NSArray arrayWithObjects:self.password, self.password2, nil];
}

- (void)viewWasTapped:(UIView *)view
{
	[self changeNextButtonStateIfNeeded];
}

- (void)outsideTapped:(UIView *)viewThatLostTheKeyboard
{
	[self changeNextButtonStateIfNeeded];
}

#pragma mark - events

- (IBAction)passwordEditingEnded:(id)sender {
	[self.password resignFirstResponder];
	[self changeNextButtonStateIfNeeded];
}

- (IBAction)verifyPasswordEditingEnded:(id)sender {
	[self.password2 resignFirstResponder];
	[self changeNextButtonStateIfNeeded];
}

- (IBAction)testHashStrength:(id)sender {
	NSDate *startTime = [NSDate date];
	TSDatabaseMetadata *meta = [TSDatabaseMetadata newDatabaseNamed:@"test"];
	meta.hashUsedMemory = self.hashUsedMemory.value;
	TSDatabase *db = [[TSDatabase alloc] init];
	[TSCryptoUtils tanukiEncryptDatabase:db havingMetadata:meta usingSecret:@"~NI-PAH!~"];
	NSDate *endTime = [NSDate date];
	NSTimeInterval encryptionTime = [endTime timeIntervalSinceDate:startTime];
	[TSNotifierUtils info:[NSString stringWithFormat:@"Ecryption took about %d seconds.", (int)ceil(encryptionTime)]];
}

- (IBAction)sliderValueChanged:(id)sender {
//	NSLog (@"slider changed : %f", self.hashUsedMemory.value);
	self.hashUsedMemory.value = floorf(self.hashUsedMemory.value + 0.0001);
//	NSLog (@"rounded to int : %f", self.hashUsedMemory.value);
}

- (IBAction)createDatabase:(id)sender {
	NSString *pass = self.password.text;
	if ([pass isEqualToString:self.password2.text] == NO) {
		@throw @"Internal logic fail. Passwords do not match.";
	}
	if ([self passwordIsWeak:pass]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue with weak password?"
														message:@"It is highly recommended that you choose a stronger password, weak passwords are easily compromised regardless of the extra precautions this application takes. Do not worry about setting a password difficult to enter on your device, you can set a device-specific passcode for this database later. Do you really want to use such a weak password?"
													   delegate:self
											  cancelButtonTitle:@"NO"
											  otherButtonTitles:@"YES", nil];
		[alert show];
	}else {
		[self doCreateDatabase];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
	if ([@"YES" isEqualToString:buttonText]) {
		[self doCreateDatabase];
	}
}

@end
