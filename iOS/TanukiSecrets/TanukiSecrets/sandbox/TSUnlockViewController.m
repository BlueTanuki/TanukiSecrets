//
//  TSUnlockViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/1/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUnlockViewController.h"

#import "TSSharedState.h"

#import "TSDatabaseMetadata.h"
#import "TSVersion.h"
#import "TSAuthor.h"
#import "TSDatabase.h"
#import "TSDBGroup.h"
#import "TSDBItem.h"
#import "TSDBItemField.h"
#import "TSDatabaseLock.h"

#import "TSCryptoUtils.h"
#import "TSNotifierUtils.h"
#import "TSIOUtils.h"
#import "TSDropboxWrapper.h"

@interface TSUnlockViewController () <UITextFieldDelegate, TSDropboxUploadDelegate>

@property (weak, nonatomic) IBOutlet UITextField *unlockCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *unlockCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;

@end

@implementation TSUnlockViewController

@synthesize unlockCodeTextField;
@synthesize unlockCodeLabel;
@synthesize onOffSwitch;

BOOL firstTimeSegueTriggered = NO;

#pragma mark - test database

- (TSDatabase *)testDatabase
{
	TSDBItem *item = [TSDBItem itemNamed:@"item1"];
	TSDBItemField *field = [TSDBItemField fieldWithName:@"field1" andValue:@"value ichi"];
	[item addField:field];
	item.defaultFieldName = field.name;
	field = [TSDBItemField fieldWithName:@"field2" andValue:@"futatsu no value"];
	[item addField:field];
	
	TSDBGroup *subgroup = [TSDBGroup groupNamed:@"group1"];
	[subgroup addItem:item];
	TSDBGroup *rootGroup = [TSDBGroup groupNamed:@"rootGroup"];
	[rootGroup addSubgroup:subgroup];
	
	return [TSDatabase databaseWithRoot:rootGroup];
}

- (void)addEncryptedFieldTo:(TSDatabase *)db usingSecret:(NSString *)secret
{
	NSString *plaintextValue = @"himitsu desu~";
	NSString *itemName = @"itemWithEncryptedField";
	NSString *encryptedValue = [TSCryptoUtils tanukiEncryptField:plaintextValue
												 belongingToItem:itemName
													 usingSecret:secret];
	TSDBItemField *field = [TSDBItemField encryptedFieldWithName:@"encryptedField" andValue:encryptedValue];
	TSDBItem *item = [TSDBItem itemNamed:itemName];
	[item addField:field];
	[db.root addItem:item];
}

- (TSDatabase *)testDatabaseWithEncryptedItemUsingSecret:(NSString *)secret
{
	TSDatabase *ret = [self testDatabase];
	[self addEncryptedFieldTo:ret usingSecret:secret];
	return ret;
}

- (TSDatabaseMetadata *)testDatabaseMetadata
{
	TSDatabaseMetadata *ret = [TSDatabaseMetadata newDatabaseNamed:@"myFirstDatabase"];
	return ret;
}

#pragma mark - TSDropboxUploadDelegate

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper failedToUploadForDatabase:(NSString *)databaseUid errorString:(NSString *)error
{
	[TSNotifierUtils error:[NSString stringWithFormat:@"Failed to upload %@ :: %@", databaseUid, error]];
}

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Successfully uploaded metadata file for %@", databaseUid]];
}

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadedMainFileForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Successfully uploaded main file for %@", databaseUid]];
}

#pragma mark - Listeners

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([self.unlockCodeTextField.text isEqualToString:@"Mellon"]) {
		[self performSegueWithIdentifier:@"unlockCodeOkSegue" sender:nil];
		NSLog(@"perform segue invoked...");
		[self.unlockCodeTextField resignFirstResponder];
	}else {
		self.unlockCodeLabel.textColor = [UIColor redColor];
		self.unlockCodeTextField.text = nil;
		[self.view setNeedsDisplay];
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self.unlockCodeTextField resignFirstResponder];
	NSLog(@"Editing ended, value is :: %@", unlockCodeTextField.text);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSLog(@"Segue %@ sender %@", [segue debugDescription], [sender debugDescription]);
}

- (IBAction)go:(id)sender {
	NSLog(@"onOffSwitch :: %@", [self.onOffSwitch debugDescription]);
	if (self.onOffSwitch.on) {
		[self performSegueWithIdentifier:@"onSegue" sender:nil];
	}else {
		[self performSegueWithIdentifier:@"offSegue" sender:nil];
	}
}

- (IBAction)createTestDatabase:(UIButton *)sender {
	NSString *secret = @"TheTanukiSais...NI-PAH~!";
	TSDatabase *database = [self testDatabaseWithEncryptedItemUsingSecret:secret];
	TSDatabaseMetadata *metadata = [self testDatabaseMetadata];
	[TSNotifierUtils info:@"Writing local database"];
	NSData *encryptedContent = [TSCryptoUtils tanukiEncryptDatabase:database
													 havingMetadata:metadata
														usingSecret:secret];
	if ([TSIOUtils saveDatabaseWithMetadata:metadata andEncryptedContent:encryptedContent]) {
		[TSNotifierUtils info:@"Uploading database to Dropbox"];
		TSDropboxWrapper *dropboxWrapper = [TSSharedState sharedState].dropboxWrapper;
		[dropboxWrapper uploadDatabaseWithId:metadata.uid andReportToDelegate:self];
	}else {
		[TSNotifierUtils error:@"Local database writing failed"];
	}
}

#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.unlockCodeTextField.delegate = self;
}

- (void)viewDidUnload
{
	[self setUnlockCodeTextField:nil];
	[self setUnlockCodeLabel:nil];
	[self setOnOffSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.unlockCodeLabel.textColor = [UIColor blackColor];
	self.unlockCodeTextField.text = nil;
	[self.unlockCodeTextField becomeFirstResponder];
//	self.unlockCodeTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//	self.unlockCodeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
//	self.unlockCodeTextField.enablesReturnKeyAutomatically = YES;
//	self.unlockCodeTextField.secureTextEntry = YES;
//	self.unlockCodeTextField.keyboardType = UIKeyboardTypeNumberPad;
//	self.unlockCodeTextField.returnKeyType = UIReturnKeyDone;
}

- (void) viewDidAppear:(BOOL)animated
{
	if (!firstTimeSegueTriggered) {
		firstTimeSegueTriggered = YES;
		[self performSegueWithIdentifier:@"unlockCodeOkSegue" sender:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
