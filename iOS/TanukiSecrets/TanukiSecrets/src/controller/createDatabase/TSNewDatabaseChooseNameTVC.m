//
//  TSNewDatabaseChooseNameTVC.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNewDatabaseChooseNameTVC.h"

#import "TSDatabaseMetadata.h"
#import "TSIOUtils.h"
#import "TSStringUtils.h"
#import "TSNotifierUtils.h"
#import "TSSharedState.h"
#import "TSDBGroup.h"
#import "TSDBItem.h"
#import "TSDBItemField.h"

@interface TSNewDatabaseChooseNameTVC ()

@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (nonatomic, strong) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *nextCell;
@property (weak, nonatomic) IBOutlet UILabel *nextCellLabel;

@property(nonatomic, strong) NSArray *localDatabaseNames;

@end

@implementation TSNewDatabaseChooseNameTVC

@synthesize nameTextField, nextCell, nextCellLabel;
@synthesize localDatabaseNames = _localDatabaseNames;

#pragma mark - override getters/setters

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
	NSString *wantedName = [TSStringUtils trim:self.nameTextField.text];
	if ([self.localDatabaseNames containsObject:wantedName]) {
		return NO;
	}
	return YES;
}

- (void)changeNextCellLabelIfNeeded
{
	if ([TSStringUtils isNotBlank:self.nameTextField.text]) {
		if ([self databaseNameIsValid]) {
			self.nextCellLabel.enabled = YES;
			self.nextCellLabel.text = @"Continue to security settings";
			self.nextCellLabel.textColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1];
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

- (IBAction)nameEditingEnded:(id)sender {
	[self.nameTextField resignFirstResponder];
	[self changeNextCellLabelIfNeeded];
}

- (IBAction)next:(id)sender {
	TSSharedState *sharedState = [TSSharedState sharedState];
	sharedState.openDatabaseMetadata = [TSDatabaseMetadata newDatabaseNamed:[TSStringUtils trim:self.nameTextField.text]];
	sharedState.openDatabase = [TSDatabase emptyDatabase];
	[self performSegueWithIdentifier:@"next" sender:nil];
}

#pragma mark - TSSelectiveTapCallbackTableViewController callbacks

- (NSArray *)viewsThatNeedTapCallback
{
	//NOTE : text fields are responders, but have fucked up coordinates, so detect tap on cell!!!
	return [NSArray arrayWithObjects:self.nameCell, self.nextCell, nil];
}

- (void)viewWasTapped:(UIView *)view
{
//	if (view == self.nameCell) {
//		NSLog (@"name was tapped");
//		NSLog (@"%d %d", [self.nameTextField isFirstResponder], [self.nameTextField isFirstResponder] == NO);
//	}else if (view == self.nextCell) {
//		NSLog (@"next was tapped");
//	}else {
//		NSLog (@"phantom view was tapped :: %@", [view debugDescription]);
//	}
 	if ((view == self.nextCell) && (self.nextCellLabel.enabled == YES)){
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
		[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self next:nil];
	}
//	NSLog (@"%d %d", [self.nameTextField isFirstResponder], [self.nameTextField isFirstResponder] == NO);
	if ((view == self.nameCell) && ([self.nameTextField isFirstResponder] == NO)) {
		[self.nameTextField becomeFirstResponder];
//		NSLog (@"%d %d", [self.nameTextField isFirstResponder], [self.nameTextField isFirstResponder] == NO);
	}
	if (view != self.nameCell) {
		[self.nameTextField resignFirstResponder];
	}
	[self changeNextCellLabelIfNeeded];
}

- (void)outsideTapped
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
	[self.nameTextField resignFirstResponder];
	[self changeNextCellLabelIfNeeded];
}

#pragma mark - events

//#pragma mark - Table view delegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	[TSNotifierUtils error:@"not implemented"];
//	[tableView deselectRowAtIndexPath:indexPath animated:YES];
//}
// -- DOES NOT work well together with TSSelectiveTapCallbackTableViewController code

@end
