//
//  TSUnlockDatabaseViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/29/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUnlockDatabaseViewController.h"

#import "TSSharedState.h"
#import "TSIOUtils.h"
#import "TSUtils.h"

@interface TSUnlockDatabaseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *unlockButton;

@end

@implementation TSUnlockDatabaseViewController

@synthesize label, password, unlockButton;

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.password becomeFirstResponder];
	self.label.text = [NSString stringWithFormat:@"Enter the passphrase for database %@", [TSSharedState sharedState].openDatabaseMetadata.name];
}

#pragma mark - worker methods

#pragma mark - events

- (IBAction)cancel:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)passwordEntered:(id)sender {
//	NSLog (@"password entered, sender is :: %@", [sender debugDescription]);
	self.label.textColor = [UIColor darkGrayColor];
	self.label.text = @"Attempting to unlock database...";
	NSString *secret = self.password.text;
	if ([self.password isFirstResponder]) {
		[self.password resignFirstResponder];
	}
	self.unlockButton.enabled = NO;
	[TSUtils background:^{
		TSSharedState *sharedState = [TSSharedState sharedState];
		TSDatabaseMetadata *metadata = sharedState.openDatabaseMetadata;
		TSDatabase *database = [TSIOUtils loadDatabase:metadata.uid havingMetadata:metadata usingSecret:secret];
		[TSUtils foreground:^{
			if (database != nil) {
				sharedState.openDatabase = database;
				sharedState.openDatabasePassword = secret;
				[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
					NSNotification *notificatopn = [NSNotification notificationWithName:TS_NOTIFICATION_DATABASE_WAS_UNLOCKED_SUCCESSFULLY object:nil];
					[[NSNotificationCenter defaultCenter] postNotification:notificatopn];
				}];
			}else {
				self.label.textColor = [UIColor redColor];
				self.label.text = [NSString stringWithFormat:@"Unlock failed! Please enter the correct passphrase for database %@", metadata.name];
				self.password.text = nil;
				[self.password becomeFirstResponder];
				self.unlockButton.enabled = YES;
			}
		}];
	}];
}

@end
