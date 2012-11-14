//
//  TSNewGroupViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewGroupViewController.h"

#import "TSStringUtils.h"
#import "TSSharedState.h"
#import "TSDBGroup.h"
#import "TSCryptoUtils.h"
#import "TSIOUtils.h"
#import "TSNotifierUtils.h"
#import "TSUtils.h"

@interface TSNewGroupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet UILabel *createGroupCellLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *createGroupCell;

@end

@implementation TSNewGroupViewController

@synthesize nameTextField, createGroupCellLabel, createGroupCell;

#pragma mark - worker methods

- (BOOL)databaseNameIsValid
{
	NSString *wantedName = [TSStringUtils trim:self.nameTextField.text];
	TSDBGroup *currentGroup = [TSSharedState sharedState].currentGroup;
	for (TSDBGroup *subgroup in currentGroup.subgroups) {
		if ([wantedName isEqualToString:subgroup.name]) {
			return NO;
		}
	}
	return YES;
}

- (void)changeNextCellLabelIfNeeded
{
	if ([TSStringUtils isNotBlank:self.nameTextField.text]) {
		if ([self databaseNameIsValid]) {
			self.createGroupCellLabel.enabled = YES;
			self.createGroupCellLabel.text = @"Create group";
		}else {
			self.createGroupCellLabel.enabled = NO;
			self.createGroupCellLabel.text = @"Name already used";
		}
	}else {
		self.createGroupCellLabel.enabled = NO;
		self.createGroupCellLabel.text = @"Please choose a name";
	}
}

#pragma mark - view lifecycle

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.nameTextField becomeFirstResponder];
}

-(void) viewWillDisappear:(BOOL)animated {
	[self.nameTextField resignFirstResponder];
    [super viewWillDisappear:animated];
}

#pragma mark - events

- (IBAction)createGroup:(id)sender {
	TSSharedState *sharedState = [TSSharedState sharedState];
	if ([sharedState encryptKeyReady] == NO) {
		[TSUtils notifyEncryptionKeyIsNotReady];
	}else {
		NSString *subgroupName = [TSStringUtils trim:self.nameTextField.text];
		TSAuthor *author = [TSAuthor authorFromCurrentDevice];
		author.comment = [NSString stringWithFormat:@"added group %@ as child of %@", subgroupName, [sharedState.currentGroup uniqueGlobalId]];
		sharedState.openDatabaseMetadata.lastModifiedBy = author;
		TSDBGroup *subgroup = [TSDBGroup groupNamed:subgroupName];
		subgroup.parent = sharedState.currentGroup;
		[sharedState.currentGroup addSubgroup:subgroup];
		//NOTE: adding a group does not trigger a backup, the operation is too irrelevant.
		NSData *encryptKey = [sharedState encryptKey];
		NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:sharedState.openDatabase
														 havingMetadata:sharedState.openDatabaseMetadata
															   usingKey:encryptKey];
		
		if ([TSIOUtils saveDatabaseWithMetadata:sharedState.openDatabaseMetadata andEncryptedContent:encryptedContent]) {
			sharedState.currentGroup = subgroup;
			[[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
				NSNotification *notification = [NSNotification notificationWithName:TS_NOTIFICATION_OPEN_DATABASE_CONTENT_CHANGED object:nil];
				[[NSNotificationCenter defaultCenter] postNotification:notification];
			}];
		}else {
			[TSNotifierUtils error:@"Local database writing failed"];
		}
	}
	
}

- (IBAction)nameEditingEnded:(id)sender {
	[self.nameTextField resignFirstResponder];
	[self changeNextCellLabelIfNeeded];
	if (self.createGroupCellLabel.enabled == YES) {
		[self createGroup:nil];
	}
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	//NOTE : text fields are responders, but have fucked up coordinates, so detect tap on cell!!!
	return [NSArray arrayWithObjects:self.nameCell, self.createGroupCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
 	if ((view == self.createGroupCell) && (self.createGroupCellLabel.enabled == YES)){
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
		[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self createGroup:nil];
	}
	if ((view == self.nameCell) && ([self.nameTextField isFirstResponder] == NO)) {
		[self.nameTextField becomeFirstResponder];
	}
	if (view != self.nameCell) {
		[self.nameTextField resignFirstResponder];
	}
	[self changeNextCellLabelIfNeeded];
}

- (void)outsideTapped
{
	[self.nameTextField resignFirstResponder];
	[self changeNextCellLabelIfNeeded];
}

@end
