//
//  TSNewItemChooseNameTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/15/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewItemChooseNameTVC.h"

#import "TSDBGroup.h"
#import "TSDBItem.h"
#import "TSSharedState.h"
#import "TSStringUtils.h"

@interface TSNewItemChooseNameTVC ()

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (weak, nonatomic) IBOutlet UILabel *nextCellLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *nextCell;

@end

@implementation TSNewItemChooseNameTVC

@synthesize nameTextField, nameCell, nextCellLabel, nextCell;

#pragma mark - worker methods

- (BOOL)itemNameIsValid
{
	NSString *wantedName = [TSStringUtils trim:self.nameTextField.text];
	TSDBGroup *currentGroup = [TSSharedState sharedState].currentGroup;
	for (TSDBItem *item in currentGroup.items) {
		if ([wantedName isEqualToString:item.name]) {
			return NO;
		}
	}
	return YES;
}

- (void)changeNextCellLabelIfNeeded
{
	if ([TSStringUtils isNotBlank:self.nameTextField.text]) {
		if ([self itemNameIsValid]) {
			self.nextCellLabel.enabled = YES;
			self.nextCellLabel.text = @"Next";
		}else {
			self.nextCellLabel.enabled = NO;
			self.nextCellLabel.text = @"Name already used";
		}
	}else {
		self.nextCellLabel.enabled = NO;
		self.nextCellLabel.text = @"Please choose a name";
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

- (IBAction)next:(id)sender {
	[self changeNextCellLabelIfNeeded];
	if (self.nextCellLabel.enabled) {
		TSSharedState *sharedState = [TSSharedState sharedState];
		NSString *itemName = [TSStringUtils trim:self.nameTextField.text];
		sharedState.currentItem = [TSDBItem itemNamed:itemName];
		if (TS_DEV_DEBUG_ALL) {
			NSLog (@"textfield name %@, item name %@", self.nameTextField.text, sharedState.currentItem.name);
		}
		[self performSegueWithIdentifier:@"next" sender:sender];
	}
}

- (IBAction)nameEditingEnded:(id)sender {
	[self.nameTextField resignFirstResponder];
	[self changeNextCellLabelIfNeeded];
	if (self.nextCellLabel.enabled == YES) {
		[self next:nil];
	}
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	//NOTE : text fields are responders, but have fucked up coordinates, so detect tap on cell!!!
	return [NSArray arrayWithObjects:self.nameCell, self.nextCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
 	if ((view == self.nextCell) && (self.nextCellLabel.enabled == YES)){
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self next:nil];
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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
