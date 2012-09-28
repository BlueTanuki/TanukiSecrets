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
	item.tags = [NSMutableArray arrayWithObjects:@"nabla", @"delta", nil];
	
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
	item.tags = [NSMutableArray arrayWithObjects:@"himitsu", nil];
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

#pragma mark - test updates and backups

- (NSString *)createLocalDatabaseAndUpdateItManyTimes:(NSInteger)noUpdates
{
	NSString *secret = @"TheTanukiSais...NI-PAH~!";
	TSDatabase *database = [TSDatabase databaseWithRoot:[TSDBGroup groupNamed:@"rootGroup"]];
	TSDatabaseMetadata *metadata = [TSDatabaseMetadata newDatabaseNamed:@"testUpdatesDatabase"];
	metadata.createdBy = [TSAuthor authorFromCurrentDevice];
	NSLog (@"Writing initial (empty) version of database %@ (%@)", metadata.name, metadata.uid);
	if ([TSIOUtils saveDatabase:database havingMetadata:metadata usingSecret:secret] == NO) {
		NSLog (@"Failed at creation.");
		return nil;
	}
	
	for (int i=1; i<=noUpdates; i++) {
		NSLog (@"Performing update %d of %d", i, noUpdates);
		[database.root addItem:[TSDBItem itemNamed:[NSString stringWithFormat:@"item_%d", i]]];
		metadata.lastModifiedBy = [TSAuthor authorFromCurrentDevice];
		if ([TSIOUtils saveDatabase:database havingMetadata:metadata usingSecret:secret] == NO) {
			NSLog (@"Failed.");
			return nil;
		}
		[NSThread sleepForTimeInterval:1.5];
	}
	
	return metadata.uid;
}

- (BOOL)logStatusOfBackups:(NSString *)databaseUid
{
	BOOL allOK = YES;
	NSString *secret = @"TheTanukiSais...NI-PAH~!";
	NSArray *backupIds = [TSIOUtils backupIdsForDatabase:databaseUid];
	NSLog (@"Found %d backups for database %@", [backupIds count], databaseUid);
	for (NSString *backupId in backupIds) {
		NSString *metadataPath = [TSIOUtils metadataFilePath:databaseUid forBackup:backupId];
		NSString *databasePath = [TSIOUtils databaseFilePath:databaseUid forBackup:backupId];
		NSLog (@"Backup with id %@ has metadata file %@ and database file %@",
			   backupId, metadataPath, databasePath);
		TSDatabaseMetadata *metadata = [TSIOUtils loadDatabaseMetadataFromFile:metadataPath];
		if (metadata != nil) {
			NSLog (@"metadata read successfully, last update date is %@",
			   metadata.lastModifiedBy.date);
			TSDatabase *database = [TSIOUtils loadDatabaseFromFile:databasePath havingMetadata:metadata usingSecret:secret];
			if (database != nil) {
				NSLog (@"database read successfully, last root group has %d items",
					   [database.root.items count]);
			}else {
				NSLog (@"Could not read database from file");
				allOK = NO;
			}
		}else {
			NSLog (@"Could not read metadata from file");
			allOK = NO;
		}
	}
	return allOK;
}

- (BOOL)simulateCorruptionOfBackups:(NSString *)databaseUid
{
	BOOL allOK = YES;
	int corruptionType = 0;
	NSArray *backupIds = [TSIOUtils backupIdsForDatabase:databaseUid];
	NSString *filePath;
	NSData *garbage;
	for (NSString *backupId in backupIds) {
		switch (corruptionType) {
			case 1:
				NSLog (@"Corrupting backup %@ by deleting the metadata file.", backupId);
				filePath = [TSIOUtils metadataFilePath:databaseUid forBackup:backupId];
				if ([TSIOUtils deleteLocalFile:filePath] == NO) {
					allOK = NO;
				}
				break;
				
			case 2:
				NSLog (@"Corrupting backup %@ by deleting the database file.", backupId);
				filePath = [TSIOUtils databaseFilePath:databaseUid forBackup:backupId];
				if ([TSIOUtils deleteLocalFile:filePath] == NO) {
					allOK = NO;
				}
				break;
				
			case 3:
				NSLog (@"Corrupting backup %@ by overwriting metadata file with garbage.", backupId);
				filePath = [TSIOUtils metadataFilePath:databaseUid forBackup:backupId];
				garbage = [TSCryptoUtils randomDataOfVariableLengthMinimum:1024 maximum:102400];
				if ([garbage writeToFile:filePath atomically:YES] == NO) {
					NSLog (@"Failed to overwrite metadata file with garbage");
					allOK = NO;
				}
				break;
			
			case 4:
				NSLog (@"Corrupting backup %@ by overwriting database file with garbage.", backupId);
				filePath = [TSIOUtils databaseFilePath:databaseUid forBackup:backupId];
				garbage = [TSCryptoUtils randomDataOfVariableLengthMinimum:1024 maximum:102400];
				if ([garbage writeToFile:filePath atomically:YES] == NO) {
					NSLog (@"Failed to overwrite database file with garbage");
					allOK = NO;
				}
				break;
				
			default:
				NSLog (@"Backup %@ will not be corrupted.", backupId);
				break;
		}
		corruptionType = (corruptionType + 1) % 5;
	}
	return allOK;
}

#pragma mark - TSDropboxUploadDelegate

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper finishedUploadingDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Successfully uploaded %@", databaseUid]];
}

- (void)dropboxWrapper:(TSDropboxWrapper *)dropboxWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:[NSString stringWithFormat:@"Failed to upload %@ :: %@", databaseUid, error]];
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

- (IBAction)manyUpdatesWithBackups:(UIButton *)sender {
	[TSNotifierUtils info:@"Doing many updates with backups..."];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		BOOL ok = YES;
		NSLog (@"**************** CREATE");
		NSString *databaseUid = [self createLocalDatabaseAndUpdateItManyTimes:50];
		if (databaseUid != nil) {
			NSLog (@"**************** PRINT");
			ok = [self logStatusOfBackups:databaseUid] && ok;
			NSLog (@"**************** CORRUPT");
			ok = [self simulateCorruptionOfBackups:databaseUid] && ok;
			NSLog (@"**************** PRINT");
			[self logStatusOfBackups:databaseUid];
			NSLog (@"**************** CLEANUP");
			ok = [TSIOUtils deleteOldBackupsFor:databaseUid] && ok;
			NSLog (@"**************** PRINT");
			[self logStatusOfBackups:databaseUid];
		}else {
			ok = NO;
		}
		if (ok) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[TSNotifierUtils info:@"Finished doing many things."];
			});
		}else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[TSNotifierUtils error:@"ERROR while doing many things..."];
			});
		}
	});
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
	[self.unlockCodeTextField resignFirstResponder];
//	[self.unlockCodeTextField becomeFirstResponder];
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
