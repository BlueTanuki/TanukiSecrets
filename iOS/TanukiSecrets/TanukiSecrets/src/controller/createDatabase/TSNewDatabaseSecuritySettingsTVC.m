//
//  TSNewDatabaseSecuritySettingsTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/8/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewDatabaseSecuritySettingsTVC.h"

#import "TSStringUtils.h"
#import "TSSharedState.h"
#import "TSUtils.h"
#import "TSCryptoUtils.h"
#import "TSIOUtils.h"
#import "TSNotifierUtils.h"

@interface TSNewDatabaseSecuritySettingsTVC ()

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *passwordCell;
@property (weak, nonatomic) IBOutlet UITextField *verifyPasswordTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *verifyPasswordCell;
@property (weak, nonatomic) IBOutlet UISlider *hashUsedMemorySlider;
@property (weak, nonatomic) IBOutlet UITableViewCell *createDatabaseCell;
@property (weak, nonatomic) IBOutlet UILabel *createDatabaseCellLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *testEncryptionCell;
@property (weak, nonatomic) IBOutlet UILabel *testEncryptionCellLabel;

@end

@implementation TSNewDatabaseSecuritySettingsTVC

@synthesize passwordTextField, passwordCell, verifyPasswordTextField, verifyPasswordCell, hashUsedMemorySlider;
@synthesize createDatabaseCell, createDatabaseCellLabel, testEncryptionCell, testEncryptionCellLabel;

#pragma mark - view lifecycle

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.passwordTextField becomeFirstResponder];
}

-(void) viewWillDisappear:(BOOL)animated {
	[self.passwordTextField resignFirstResponder];
	[self.verifyPasswordTextField resignFirstResponder];
    [super viewWillDisappear:animated];
}

#pragma mark - worker methods

- (void)changeCreateDatabaseCellLabelIfNeeded
{
	if (([TSStringUtils isNotBlank:self.passwordTextField.text]) && ([TSStringUtils isNotBlank:self.verifyPasswordTextField.text])) {
		if ([self.passwordTextField.text isEqualToString:self.verifyPasswordTextField.text]) {
			self.createDatabaseCellLabel.enabled = YES;
			self.createDatabaseCellLabel.text = @"Create database";
			self.createDatabaseCellLabel.textColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1];
		}else {
			self.createDatabaseCellLabel.enabled = NO;
			self.createDatabaseCellLabel.text = @"Passphrase missmatch";
		}
	}else {
		self.createDatabaseCellLabel.enabled = NO;
		self.createDatabaseCellLabel.text = @"Please set the passphrase";
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
	self.createDatabaseCellLabel.enabled = NO;
	self.createDatabaseCellLabel.text = [NSString stringWithFormat:@"Creating database %@", sharedState.openDatabaseMetadata.name];
	[TSUtils background:^{
		NSString *secret = self.passwordTextField.text;
		if ([secret isEqualToString:self.verifyPasswordTextField.text] == NO) {
			@throw @"Internal logic fail. Passwords do not match.";
		}
		sharedState.openDatabaseMetadata.hashUsedMemory = (int)self.hashUsedMemorySlider.value;
		sharedState.openDatabasePassword = secret;
		NSData *encryptKey = [TSCryptoUtils tanukiDecryptKey:sharedState.openDatabaseMetadata usingSecret:sharedState.openDatabasePassword];
		NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
														 havingMetadata:sharedState.openDatabaseMetadata
															   usingKey:encryptKey];
		if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
			sharedState.openDatabasePassword = secret;
			[TSUtils foreground:^{
				[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
					NSNotification *notificatopn = [NSNotification notificationWithName:TS_NOTIFICATION_LOCAL_DATABASE_LIST_CHANGED object:nil];
					[[NSNotificationCenter defaultCenter] postNotification:notificatopn];
				}];
			}];
		}else {
			[TSNotifierUtils error:@"Local database writing failed"];
		}
	}];
}

#pragma mark - events

- (IBAction)passwordEditingEnded:(id)sender {
	[self.passwordTextField resignFirstResponder];
	[self changeCreateDatabaseCellLabelIfNeeded];
}

- (IBAction)verifyPasswordEditingEnded:(id)sender {
	[self.verifyPasswordTextField resignFirstResponder];
	[self changeCreateDatabaseCellLabelIfNeeded];
}

- (IBAction)testHashStrength:(id)sender {
	NSDate *startTime = [NSDate date];
	TSDatabaseMetadata *meta = [TSDatabaseMetadata newDatabaseNamed:@"test"];
	meta.hashUsedMemory = self.hashUsedMemorySlider.value;
	TSDatabase *db = [[TSDatabase alloc] init];
	NSData *encryptKey = [TSCryptoUtils tanukiEncryptKey:meta usingSecret:@"~NI-PAH!~"];
	[TSCryptoUtils tanukiEncryptDatabase:db havingMetadata:meta usingKey:encryptKey];
	NSDate *endTime = [NSDate date];
	NSTimeInterval encryptionTime = [endTime timeIntervalSinceDate:startTime];
	[TSNotifierUtils info:[NSString stringWithFormat:@"Ecryption took about %d seconds.", (int)ceil(encryptionTime)]];
}

- (IBAction)sliderValueChanged:(id)sender {
	//	NSLog (@"slider changed : %f", self.hashUsedMemory.value);
	self.hashUsedMemorySlider.value = floorf(self.hashUsedMemorySlider.value + 0.0001);
	//	NSLog (@"rounded to int : %f", self.hashUsedMemory.value);
}

- (IBAction)createDatabase:(id)sender {
	NSString *pass = self.passwordTextField.text;
	if ([pass isEqualToString:self.verifyPasswordTextField.text] == NO) {
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

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	return [NSArray arrayWithObjects:self.passwordCell, self.verifyPasswordCell,
			self.testEncryptionCell, self.createDatabaseCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
//	NSLog (@"tapped in view %@", [view debugDescription]);
//	NSLog (@"%d %d", [passwordTextField isFirstResponder], [verifyPasswordCell isFirstResponder]);
	[self changeCreateDatabaseCellLabelIfNeeded];
 	if ((view == self.testEncryptionCell) && (self.testEncryptionCellLabel.enabled == YES)) {
		self.testEncryptionCellLabel.enabled = NO;
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:2];
		[[self tableView] selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
		[[self tableView] setNeedsDisplay];
		[TSUtils background:^{
			[self testHashStrength:nil];
			[TSUtils foreground:^{
				[[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
				self.testEncryptionCellLabel.enabled = YES;
			}];
		}];
	}
 	if ((view == self.createDatabaseCell) && (self.createDatabaseCellLabel.enabled == YES)){
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:3];
		[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self createDatabase:nil];
		[[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
	}
	if ((view == self.passwordCell) && ([self.passwordTextField isFirstResponder] == NO)) {
		[self.verifyPasswordTextField resignFirstResponder];
		[self.passwordTextField becomeFirstResponder];
//		NSLog (@"Password hit, and it received focus");
	}
	if ((view == self.verifyPasswordCell) && ([self.verifyPasswordTextField isFirstResponder] == NO)) {
		[self.passwordTextField resignFirstResponder];
		[self.verifyPasswordTextField becomeFirstResponder];
//		NSLog (@"Verify password hit, and it received focus");
	}
	if ((view != self.passwordCell) && (view != self.verifyPasswordCell)) {
		[self.passwordTextField resignFirstResponder];
		[self.verifyPasswordTextField resignFirstResponder];
	}
}

- (void)outsideTapped
{
	[self.passwordTextField resignFirstResponder];
	[self.verifyPasswordTextField resignFirstResponder];
	[self changeCreateDatabaseCellLabelIfNeeded];
}

@end
