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
#import "TSDatabaseWrapper.h"
#import "TSDeviceUtils.h"
#import "TSiCloudWrapper.h"

@interface TSUnlockViewController () <UITextFieldDelegate, TSDatabaseWrapperDelegate>

@property(nonatomic, strong) TSDatabaseWrapper *dropboxWrapper;
@property(nonatomic, strong) TSDatabaseWrapper *iCloudWrapper;
@property(nonatomic, strong) TSiCloudWrapper *directCloudAccess;

@property(nonatomic, strong) TSDatabase *reusedDatabase;
@property(nonatomic, strong) TSDatabaseMetadata *reusedDatabaseMetadata;

@property(nonatomic, strong) NSArray *toBeCleanedUp;
@property(nonatomic, assign) NSInteger toBeCleanedUpIndex;


@property (weak, nonatomic) IBOutlet UITextField *unlockCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *unlockCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;

@end

@implementation TSUnlockViewController

@synthesize dropboxWrapper = _dropboxWrapper, iCloudWrapper = _iCloudWrapper, 
reusedDatabase = _reusedDatabase, reusedDatabaseMetadata = _reusedDatabaseMetadata,
toBeCleanedUp = _toBeCleanedUp, toBeCleanedUpIndex = _toBeCleanedUpIndex,
directCloudAccess = _directCloudAccess;

@synthesize unlockCodeTextField;
@synthesize unlockCodeLabel;
@synthesize onOffSwitch;

BOOL firstTimeSegueTriggered = NO;

#pragma mark - override getters/setters

- (TSDatabaseWrapper *)dropboxWrapper
{
	if (_dropboxWrapper == nil) {
		_dropboxWrapper = [TSSharedState dropboxWrapperForDelegate:self];
	}
	return _dropboxWrapper;
}

- (TSDatabaseWrapper *)iCloudWrapper
{
	if (_iCloudWrapper == nil) {
		_iCloudWrapper = [TSSharedState iCloudWrapperForDelegate:self];
	}
	return _iCloudWrapper;
}

- (TSiCloudWrapper *)directCloudAccess
{
	if (_directCloudAccess == nil) {
		_directCloudAccess = [[TSiCloudWrapper alloc] init];
		[_directCloudAccess refreshUbiquityContainerURL];
	}
	return _directCloudAccess;
}

- (TSDatabaseMetadata *)reusedDatabaseMetadata
{
	if (_reusedDatabaseMetadata == nil) {
		_reusedDatabaseMetadata = [[TSDatabaseMetadata alloc] init];
		_reusedDatabaseMetadata.uid = @"fixed-uid-for-cross-device-testing";
		_reusedDatabaseMetadata.name = @"reusedDatabase";
		_reusedDatabaseMetadata.version = [TSVersion newVersion];
		_reusedDatabaseMetadata.createdBy = [TSAuthor authorFromCurrentDevice];
	}
	return _reusedDatabaseMetadata;
}

- (TSDatabase *)reusedDatabase
{
	if (_reusedDatabase == nil) {
		_reusedDatabase = [TSDatabase emptyDatabase];
	}
	return _reusedDatabase;
}

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
	ret.hashUsedMemory = 7;
	return ret;
}

#pragma mark - test updates and backups

- (NSString *)createLocalDatabaseAndUpdateItManyTimes:(NSInteger)noUpdates usingSecret:(NSString *)secret
{
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

#pragma mark - TSDatabaseWrapperDelegate

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listDatabaseUidsFailedWithError:(NSString *)error
{
	[TSNotifierUtils error:@"List database UIDs failed"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListDatabaseUids:(NSArray *)databaseUids
{
	self.toBeCleanedUp = databaseUids;
	self.toBeCleanedUpIndex = 0;
	[TSNotifierUtils info:[NSString stringWithFormat:@"Beginning cleanup of %d databases", [self.toBeCleanedUp count]]];
	[NSThread sleepForTimeInterval:0.5];
	NSString *databaseuid = [self.toBeCleanedUp objectAtIndex:self.toBeCleanedUpIndex];
	[databaseWrapper cleanupDatabase:databaseuid];
	NSLog (@"Invoked cleanup of %@", databaseuid);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper attemptingToLockDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Attempting to lock %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyLockedDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"LOCKED %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper createdBackup:(NSString *)backupId forDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Created backup %@", backupId]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMetadataFileForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:@"Uploaded metadata file"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadedMainFileForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:@"Uploaded database file"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper successfullyUnlockedDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"UNLOCKED %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupDeletedFile:(NSString *)path
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Cleanup DELETED %@", [path lastPathComponent]]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:[NSString stringWithFormat:@"Failed to upload %@ :: %@", databaseUid, error]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *errorText = [NSString stringWithFormat:@"The database with id %@ was locked for writing by %@ (%@) at %@ [comment: %@]",
							   databaseUid, databaseLock.writeLock.name, databaseLock.writeLock.uid, databaseLock.writeLock.date, databaseLock.writeLock.comment];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Database locked!"
														message:errorText
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	});
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper uploadForDatabase:(NSString *)databaseUid isStalledBecauseOfOptimisticLock:(TSDatabaseLock *)databaseLock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *warning = [NSString stringWithFormat:@"The database with id %@ has an optimistic lock written by %@ (%@) at %@ [comment: %@]. The optimistic lock is advisory and can be overriden. Proceed with upload and overwrite this optimistic lock?",
							   databaseUid, databaseLock.optimisticLock.name, databaseLock.optimisticLock.uid, databaseLock.optimisticLock.date, databaseLock.optimisticLock.comment];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Proceed with writing?"
														message:warning
													   delegate:self
											  cancelButtonTitle:@"NO"
											  otherButtonTitles:@"YES", nil];
		[alert show];
	});
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedUploadingDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:[NSString stringWithFormat:@"Successfully uploaded %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedAddingOptimisticLockForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:@"Optimistic lock was set."];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:@"Optimistic lock adding FAILED"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper addingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (databaseLock.writeLock == nil) {
			NSString *errorText = [NSString stringWithFormat:@"The database with id %@ already has an optimistic lock set by %@ (%@) at %@ [comment: %@]",
								   databaseUid, databaseLock.optimisticLock.name, databaseLock.optimisticLock.uid, databaseLock.optimisticLock.date, databaseLock.optimisticLock.comment];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Optimistic lock already exists."
															message:errorText
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}else {
			NSString *errorText = [NSString stringWithFormat:@"The database with id %@ was locked for writing by %@ (%@) at %@ [comment: %@]",
								   databaseUid, databaseLock.writeLock.name, databaseLock.writeLock.uid, databaseLock.writeLock.date, databaseLock.writeLock.comment];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locked for writing!!!"
															message:errorText
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	});
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedRemovingOptimisticLockForDatabase:(NSString *)databaseUid
{
	[TSNotifierUtils info:@"Optimistic lock was removed."];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:@"Optimistic lock removing FAILED"];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper removingOptimisticLockForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (databaseLock.writeLock == nil) {
			NSString *errorText = [NSString stringWithFormat:@"The database with id %@ already has an optimistic lock set by %@ (%@) at %@ [comment: %@]",
								   databaseUid, databaseLock.optimisticLock.name, databaseLock.optimisticLock.uid, databaseLock.optimisticLock.date, databaseLock.optimisticLock.comment];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Optimistic lock held by another."
															message:errorText
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}else {
			NSString *errorText = [NSString stringWithFormat:@"The database with id %@ was locked for writing by %@ (%@) at %@ [comment: %@]",
								   databaseUid, databaseLock.writeLock.name, databaseLock.writeLock.uid, databaseLock.writeLock.date, databaseLock.writeLock.comment];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locked for writing!!!"
															message:errorText
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	});
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedCleanupForDatabase:(NSString *)databaseUid
{
	self.toBeCleanedUpIndex = self.toBeCleanedUpIndex + 1;
	[TSNotifierUtils info:[NSString stringWithFormat:@"Cleanup progress %d of %d", self.toBeCleanedUpIndex, [self.toBeCleanedUp count]]];
	if (self.toBeCleanedUpIndex < [self.toBeCleanedUp count]) {
		[NSThread sleepForTimeInterval:0.5];
		NSString *databaseuid = [self.toBeCleanedUp objectAtIndex:self.toBeCleanedUpIndex];
		[databaseWrapper cleanupDatabase:databaseuid];
		NSLog (@"Invoked cleanup of %@", databaseuid);
	}
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid failedDueToDatabaseLock:(TSDatabaseLock *)databaseLock
{
	[TSNotifierUtils error:[NSString stringWithFormat:@"Could not lock %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper cleanupForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	[TSNotifierUtils error:[NSString stringWithFormat:@"Cleanup FAILED for %@", databaseUid]];
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedListBackupIds:(NSArray *)backupIds forDatabase:(NSString *)databaseUid
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper listBackupIdsForDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);	
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper finishedDownloadingBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid andSavedMetadataFileAs:(NSString *)metadataFilePath andDatabaseFileAs:(NSString *)databaseFilePath
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
}

- (void)databaseWrapper:(TSDatabaseWrapper *)databaseWrapper downloadBackup:(NSString *)backupId ofDatabase:(NSString *)databaseUid failedWithError:(NSString *)error
{
	NSLog(@"TSDatabaseWrapperDelegate callback :: %s", __PRETTY_FUNCTION__);
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
		[self.dropboxWrapper uploadDatabaseWithUid:metadata.uid];
		[TSNotifierUtils info:@"Uploading database to iCloud"];
		[self.iCloudWrapper uploadDatabaseWithUid:metadata.uid];
	}else {
		[TSNotifierUtils error:@"Local database writing failed"];
	}
}

- (IBAction)manyUpdatesWithBackups:(UIButton *)sender {
	[TSNotifierUtils info:@"Doing many updates with backups..."];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		BOOL ok = YES;
		NSLog (@"**************** CREATE");
		NSString *secret = @"TheTanukiSais...NI-PAH~!";
		NSString *databaseUid = [self createLocalDatabaseAndUpdateItManyTimes:5 usingSecret:secret];
		if (databaseUid != nil) {
			NSLog (@"**************** PRINT");
			ok = [self logStatusOfBackups:databaseUid] && ok;
			NSLog (@"**************** CORRUPT");
			ok = [self simulateCorruptionOfBackups:databaseUid] && ok;
			NSLog (@"**************** PRINT");
			[self logStatusOfBackups:databaseUid];
			NSLog (@"**************** CLEANUP");
			ok = [TSIOUtils deleteOldBackupsFor:databaseUid] && ok;
			ok = [TSIOUtils deleteCorruptBackupsFor:databaseUid usingSecret:secret] && ok;
			NSLog (@"**************** PRINT");
			[self logStatusOfBackups:databaseUid];
		}else {
			ok = NO;
		}
		if (ok) {
			[TSNotifierUtils info:@"Finished doing many things."];
		}else {
			[TSNotifierUtils error:@"ERROR while doing many things..."];
		}
	});
}

- (void)updateTest:(TSDatabaseWrapper *)databaseWrapper
{
	NSString *secret = @"TheTanukiSais...NI-PAH~!";
	self.reusedDatabaseMetadata.lastModifiedBy = [TSAuthor authorFromCurrentDevice];
	[self.reusedDatabase.root addItem:[TSDBItem itemNamed:@"deja-vu"]];
	if ([TSIOUtils saveDatabase:self.reusedDatabase	havingMetadata:self.reusedDatabaseMetadata usingSecret:secret] == YES) {
		if (databaseWrapper.busy == NO) {
			[databaseWrapper uploadDatabaseWithUid:self.reusedDatabaseMetadata.uid];
			[TSNotifierUtils info:@"upload starting..."];
		}else {
			[TSNotifierUtils error:@"Database wraper is busy, cannot upload at the moment..."];
		}
	}else {
		[TSNotifierUtils error:@"Local database writing failed"];
	}
}

- (IBAction)dropboxUpdateTest:(UIButton *)sender {
	[self updateTest:self.dropboxWrapper];
}

- (void)optiLock:(TSDatabaseWrapper *)databaseWrapper
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[NSThread sleepForTimeInterval:2.5];
		[TSNotifierUtils info:@"Before potential deadlock"];
		[databaseWrapper addOptimisticLockForDatabase:self.reusedDatabaseMetadata.uid comment:@"The glass is half full!"];
		[NSThread sleepForTimeInterval:2.5];
		[TSNotifierUtils info:@"After potential deadlock"];
	});
	[TSNotifierUtils info:@"Potential deadlocking code scheduled"];
}

- (IBAction)addOptimisticLock:(UIButton *)sender {
	[self optiLock:self.dropboxWrapper];
}

- (IBAction)removeOptimisticLock:(UIButton *)sender {
	[self.dropboxWrapper removeOptimisticLockForDatabase:self.reusedDatabaseMetadata.uid];
}

- (IBAction)cleanup:(id)sender {
	[self.dropboxWrapper listDatabaseUids];
}

- (IBAction)iUpdate:(id)sender {
	if ([TSDeviceUtils isRunningInSimulator]) {
		[TSNotifierUtils error:@"iCloud is disabled in simulator"];
		return;
	}
	[self updateTest:self.iCloudWrapper];
}

- (IBAction)iLock:(id)sender {
	if ([TSDeviceUtils isRunningInSimulator]) {
		[TSNotifierUtils error:@"iCloud is disabled in simulator"];
		return;
	}
	[self optiLock:self.iCloudWrapper];
}

- (IBAction)iUnlock:(id)sender {
	if ([TSDeviceUtils isRunningInSimulator]) {
		[TSNotifierUtils error:@"iCloud is disabled in simulator"];
		return;
	}
	[self.iCloudWrapper removeOptimisticLockForDatabase:self.reusedDatabaseMetadata.uid];
}

- (IBAction)iClean:(id)sender {
	if ([TSDeviceUtils isRunningInSimulator]) {
		[TSNotifierUtils error:@"iCloud is disabled in simulator"];
		return;
	}
	[self.iCloudWrapper listDatabaseUids];
}

- (IBAction)iCheckForConflicts:(id)sender {
	NSLog (@"iCheckForConflicts");
	[self.directCloudAccess checkConflicts];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
	if ([self.dropboxWrapper uploadStalledOptimisticLock]) {
		if ([@"YES" isEqualToString:buttonText]) {
			[self.dropboxWrapper continueUploadAndOverwriteOptimisticLock];
		}else {
			[self.dropboxWrapper cancelUpload];
		}
	}else {
		NSLog (@"Strange... Received alert view click on button %@ but dropboxWrapper is not stalled", buttonText);
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

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
