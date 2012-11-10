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
#import "TSStringUtils.h"
#import "TSNotifierUtils.h"

@interface TSUnlockDatabaseViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *passwordCell;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *unlockCell;
@property (weak, nonatomic) IBOutlet UILabel *unlockCellLabel;

@property (nonatomic, copy) NSString *statusText;

@end

@implementation TSUnlockDatabaseViewController

@synthesize passwordCell, passwordTextField, unlockCell, unlockCellLabel;
@synthesize statusText;

#pragma mark - view lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.statusText = [NSString stringWithFormat:@"Enter the passphrase for database %@", [TSSharedState sharedState].openDatabaseMetadata.name];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.passwordTextField becomeFirstResponder];
}

-(void) viewWillDisappear:(BOOL)animated {
	[self.passwordTextField resignFirstResponder];
    [super viewWillDisappear:animated];
}

#pragma mark - events

- (IBAction)cancel:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)passwordEntered:(id)sender {
//	NSLog (@"password entered, sender is :: %@", [sender debugDescription]);
	NSString *secret = self.passwordTextField.text;
	if ([TSStringUtils isBlank:secret]) {
		return;
	}
	self.unlockCellLabel.text = @"Attempting to unlock database...";
	if ([self.passwordTextField isFirstResponder]) {
		[self.passwordTextField resignFirstResponder];
	}
	self.unlockCellLabel.enabled = NO;
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
				self.statusText = [NSString stringWithFormat:@"Unlock failed! Please enter the correct passphrase for database %@", metadata.name];
				//it would be nice if this worked, but for some reson it does not, so we need an extra way to communicate the failure
				[TSNotifierUtils errorAtTopOfScreen:@"Unlock failed, wrong passphrase!"];
				self.passwordTextField.text = nil;
				[self.passwordTextField becomeFirstResponder];
				self.unlockCellLabel.enabled = YES;
				self.unlockCellLabel.text = @"Unlock";
				[self.tableView setNeedsDisplay];
			}
		}];
	}];
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	//NOTE : text fields are responders, but have fucked up coordinates, so detect tap on cell!!!
	return [NSArray arrayWithObjects:self.passwordCell, self.unlockCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
 	if ((view == self.unlockCell) && (self.unlockCellLabel.enabled == YES)){
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
		[[self tableView] selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
		[self passwordEntered:nil];
		[[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
	}
	if ((view == self.passwordCell) && ([self.passwordTextField isFirstResponder] == NO)) {
		[self.passwordTextField becomeFirstResponder];
	}
	if (view != self.passwordCell) {
		[self.passwordTextField resignFirstResponder];
	}
}

- (void)outsideTapped
{
	[self.passwordTextField resignFirstResponder];
}

#pragma mark - override specific table properties

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) {
		return self.statusText;
		//warning : for some reason, this method is not called in a very natural manner
		//thererfore it is not suitable to communicate the failure 
	}
	return nil;
}

@end
