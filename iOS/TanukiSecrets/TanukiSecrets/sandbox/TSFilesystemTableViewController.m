//
//  TSFilesystemTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 7/20/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSFilesystemTableViewController.h"

#import <DropboxSDK/DropboxSDK.h>

#import "TSItem.h"
#import "TSListOfItems.h"

#import "XMLWriter.h"

#import "TSIOUtils.h"
#import "TSCryptoUtils.h"
#import "TSStringUtils.h"
#import "TSVersion.h"
#import "TSNotifierUtils.h"
#import "TSDeviceUtils.h"
#import "TSDateUtils.h"

@interface TSFilesystemTableViewController () <DBRestClientDelegate> {
	NSMetadataQuery *iCloudQuery;
	
	NSArray *tableContent;
	NSArray *dropboxItems;//DBMetadata
	NSArray *iCloudDocuments;// of NSURLs
	
	DBRestClient *dropboxRestClient;
	
	TSListOfItems *xmlParserItemsList;
	TSItem *xmlParserItem;
}
@end

@implementation TSFilesystemTableViewController

#pragma mark - XML

- (TSItem *)demoItem
{
	TSItem *ret = [[TSItem alloc] init];
	ret.string = @"this is a string";
	ret.date = [[NSDate alloc] init];
	ret.integer = 13;
	return ret;
}

- (NSData *)demoFileContentUsingXMLWriter
{
	TSListOfItems *listOfItems = [[TSListOfItems alloc] init];
	[listOfItems addItem:[self demoItem]];
	[listOfItems addItem:[self demoItem]];
	
	XMLWriter *xmlWriter = [[XMLWriter alloc] init];
	[xmlWriter writeStartElement:@"demoFileContent"];
	TSVersion *version = [TSVersion versionWithNumber:13 andChecksum:@"666"];
	[version writeTo:xmlWriter];
	[listOfItems writeTo:xmlWriter];
	[xmlWriter writeEndElement];
	return [xmlWriter toData];
}

- (NSData *)demoFileContentUsingPropertyListSerialization
{
	NSData *dataRep;
	NSString *errorStr = nil;
	NSDictionary *propertyList;
	
	propertyList = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"Javier", @"FirstNameKey",
                    @"Alegria", @"LastNameKey", nil];
	dataRep = [NSPropertyListSerialization dataFromPropertyList: propertyList
														 format: NSPropertyListXMLFormat_v1_0
											   errorDescription: &errorStr];
	return dataRep;
}

- (NSData *)demoFileContent
{
	return [self demoFileContentUsingXMLWriter];
}

- (void)readListOfItems:(NSData *)data
{
	NSError *error;
	SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
	if (error == nil) {
		NSLog(@"root name : %@", document.root.name);
		TSListOfItems *listOfItems = [TSListOfItems readFrom:document.root];
		if (listOfItems != nil) {
			NSLog(@"Successfully read list of %d items", [listOfItems.items count]);
			for (TSItem *item in listOfItems.items) {
				NSLog(@"Item with string %@ date %@ and int %d", item.string, item.date, item.integer);
			}
		}else {
			NSLog(@"Failed to read list of items.");
		}
	}else {
		NSLog(@"XML read error : %@", [error debugDescription]);
	}
}

#pragma mark - iCloud

- (NSURL *) iCloudURL
{
	return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (NSURL *) iCloudDocumentsURL
{
	return [[self iCloudURL] URLByAppendingPathComponent:@"Documents"];
}

- (NSURL *) filePackageUrlForCloudURL:(NSURL *)url
{
	if ([[url path] hasPrefix:[[self iCloudDocumentsURL] path]]) {
		NSArray *iCloudDocumentsURLComponents = [[self iCloudDocumentsURL] pathComponents];
		NSArray *urlComponents = [url pathComponents];
		if ([iCloudDocumentsURLComponents count] < [urlComponents count]) {
			urlComponents = [urlComponents subarrayWithRange:NSMakeRange(0, [iCloudDocumentsURLComponents count] + 1)];
			url = [NSURL fileURLWithPathComponents:urlComponents];
		}
	}
	return url;
}

- (void) createCloudDocumentNamed:(NSString *)name withData:(NSData *)data
{
	NSString *folderName = [name substringToIndex:6];
	NSURL *folderUrl = [[self iCloudDocumentsURL] URLByAppendingPathComponent:folderName];
	[[NSFileManager defaultManager] createDirectoryAtURL:folderUrl withIntermediateDirectories:YES attributes:nil error:nil];
	NSURL *url = [folderUrl URLByAppendingPathComponent:name];
	NSError *error;
	BOOL ok = [data writeToURL:url options:NSDataWritingAtomic error:&error];
	if (!ok) {
		NSLog(@"iWrite fail : %@", [error debugDescription]);
	}
}

- (void) removeCloudURL:(NSURL *)url
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
		NSError *coordinationError;
		[coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:&coordinationError byAccessor:^(NSURL *usedURL) {
			NSError *deleteError;
			[[[NSFileManager alloc] init] removeItemAtURL:usedURL error:&deleteError];
			if (deleteError) {
				NSLog(@"Error while deleting :: %@", [deleteError debugDescription]);
			}
		}];
		if (coordinationError) {
			NSLog(@"Synchronization error while deleting :: %@", [coordinationError debugDescription]);
		}
	});
}

- (void) startCloudQuery
{
	if ([TSDeviceUtils isRunningInSimulator]) {
		//causes DEADLOCK inside simulator version 5.1 (only, 6.0 and 5.0 do not deadlock)
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			[TSNotifierUtils error:@"iCloud query disabled inside simulator"];
		});
		return;
	}
	if (!iCloudQuery) {
		iCloudQuery = [[NSMetadataQuery alloc] init];
		iCloudQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope];
		iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(processCloudQueryResults:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:iCloudQuery];
//		[[NSNotificationCenter defaultCenter] addObserver:self
//												 selector:@selector(processCloudQueryResults:)
//													 name:NSMetadataQueryDidUpdateNotification
//												   object:iCloudQuery];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(logCloudNotification:)
													 name:NSMetadataQueryGatheringProgressNotification
												   object:iCloudQuery];
		[iCloudQuery startQuery];
		[iCloudQuery enableUpdates];
	}
}

-(void) stopCloudQuery
{
	if (iCloudQuery) {
		[iCloudQuery disableUpdates];
		if ([iCloudQuery isStarted]) {
			[iCloudQuery stopQuery];
		}
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		iCloudQuery = nil;
	}
}


#pragma mark - Dropbox 

- (DBRestClient *)dropboxRestClient {
	if (!dropboxRestClient) {
		dropboxRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		dropboxRestClient.delegate = self;
	}
	return dropboxRestClient;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
		for (DBMetadata *file in metadata.contents) {
			NSLog(@"\t%@", file.filename);
		}
		dropboxItems = metadata.contents;
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc] 
												 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												 target:self 
												 action:@selector(refreshDropbox:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self.tableView reloadData];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
	
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
			  from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
	NSError *error;
	[[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
	if (error) {
		NSLog(@"Error : %@", [error debugDescription]);
	}else {
		NSLog(@"Successfully deleted temporary file %@", srcPath);
	}
	[self refreshDropbox:nil];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
    if (![[DBSession sharedSession] isLinked]) {
		NSLog(@"Session is not linked");
		UIBarButtonItem *linkToDropboxButton = [[UIBarButtonItem alloc] 
												initWithTitle:@"Link with Dropbox" 
												style:UIBarButtonItemStyleBordered
												target:self 
												action:@selector(linkWithDropbox:)];
		NSLog(@"%@", [linkToDropboxButton debugDescription]);
		self.navigationItem.rightBarButtonItem = linkToDropboxButton;
		NSLog(@"%@", [self.navigationItem.rightBarButtonItem debugDescription]);
	}else {
		NSLog(@"Session is already linked");
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc] 
												initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
												target:self 
												action:@selector(refreshDropbox:)];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
	}
	
//	NSLog (@"Unique Device IDentifier : %@", [[UIDevice currentDevice] uniqueIdentifier]);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *uid = [defaults stringForKey:@"TS_SIMPLE_PASWORD_SALT"];
	if (uid) {
		NSLog(@"UID retrieved from NSUserDefaults : %@", uid);
	}else {
		uid = [TSStringUtils generateUid];
		NSLog(@"UID generated via CFUUIDCreate : %@", uid);
		[defaults setObject:uid forKey:@"TS_SIMPLE_PASWORD_SALT"];
		[defaults synchronize];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(notificationCenterCallback:) 
												 name:@"TScopy" 
											   object:nil];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Listeners

- (void)notificationCenterCallback:(NSNotification *)notification
{
	NSLog(@"Received notification :: %@", [notification debugDescription]);
}

- (void)linkWithDropbox:(id)sender
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self.navigationController];
    }
}

- (void)unlinkDropbox:(id)sender
{
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
    }
}

- (void)refreshDropbox:(id)sender
{
	if ([[DBSession sharedSession] isLinked]) {
		[[self dropboxRestClient] loadMetadata:@"/"];
		UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc]
										 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[busy startAnimating];
		UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc]
												 initWithCustomView:busy];
		self.navigationItem.rightBarButtonItem = refreshDropboxButton;
		[self startCloudQuery];
	}
}

- (IBAction)addDropboxItem:(UIButton *)sender {
//	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//	[dateFormat setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
//	NSString *filename = [dateFormat stringFromDate:[NSDate date]];
	
	NSData *salt = [TSCryptoUtils randomDataOfVariableLengthMinimum:32 maximum:96];
	NSString *filename = [TSStringUtils hexStringFromData:salt];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	NSData *fileContent = [self demoFileContent];
	
	NSLog(@"Encrypting...");
	NSData *encryptedData = [TSCryptoUtils tanukiEncrypt:fileContent 
									 usingSecret:@"TheTanukiSais...NI-PAH~!" andSalt:salt];
	NSLog(@"Encrypt finished.");
	
//	NSLog(@"Encrypt-decrypt test for |%@|", fileContent);
//	NSData *decryptedData = [self decryptData:encryptedData usingKey:key];
//	NSLog(@"Result of encrypt-decrypt : |%@|", 
//		  [[NSString alloc] initWithBytes:[decryptedData bytes] 
//								   length:[decryptedData length] 
//								 encoding:NSUTF8StringEncoding]);
//	[self readListOfItems:decryptedData];
	
	[fileManager createFileAtPath: filePath
						 contents:encryptedData 
					   attributes:nil];
	tableContent = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask];
	[[self dropboxRestClient] uploadFile:filename toPath:@"/" withParentRev:nil fromPath:filePath];
	
	[self createCloudDocumentNamed:filename withData:encryptedData];
}

- (void) logCloudNotification: (NSNotification *)notification
{
	NSLog(@"iCloud notification received :: %@", [notification debugDescription]);
}

- (void) processCloudQueryResults: (NSNotification *)notification
{
	[self logCloudNotification:notification];
	NSMutableArray *documents = [NSMutableArray array];
	int resultCount = [iCloudQuery resultCount];
	NSLog (@"iCloud query returned %d rows", resultCount);
	for (int i=0; i<resultCount; i++) {
		NSMetadataItem *item = [iCloudQuery resultAtIndex:i];
		NSLog (@"iItem %d :: %@", i, [item attributes]);
		NSLog (@"%@ = %@", NSMetadataItemDisplayNameKey, [item valueForAttribute:NSMetadataItemDisplayNameKey]);
		NSLog (@"%@ = %@", NSMetadataItemFSContentChangeDateKey, [item valueForAttribute:NSMetadataItemFSContentChangeDateKey]);
		NSLog (@"%@ = %@", NSMetadataItemFSCreationDateKey, [item valueForAttribute:NSMetadataItemFSCreationDateKey]);
		NSLog (@"%@ = %@", NSMetadataItemFSNameKey, [item valueForAttribute:NSMetadataItemFSNameKey]);
		NSLog (@"%@ = %@", NSMetadataItemFSSizeKey, [item valueForAttribute:NSMetadataItemFSSizeKey]);
		NSLog (@"%@ = %@", NSMetadataItemIsUbiquitousKey, [item valueForAttribute:NSMetadataItemIsUbiquitousKey]);
		NSLog (@"%@ = %@", NSMetadataItemPathKey, [item valueForAttribute:NSMetadataItemPathKey]);
		NSLog (@"%@ = %@", NSMetadataItemURLKey, [item valueForAttribute:NSMetadataItemURLKey]);
		NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
		NSString *path = [url path];
		BOOL isDirectory;
		bool exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
		NSLog (@"file at path %@ exists %d and is directory %d", path, exists, isDirectory);
		path = [[self filePackageUrlForCloudURL:url] path];
		exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
		NSLog (@"file at path %@ exists %d and is directory %d", path, exists, isDirectory);
		url = [self filePackageUrlForCloudURL:url];
		[documents addObject:url];
	}
	iCloudDocuments = [documents copy];
	[self stopCloudQuery];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Dropbox";
	}else if (section == 1) {
		return @"Local";
	}else if (section == 2) {
		return @"iCloud";
	}else {
		return @"???";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1) {
		if (!tableContent) {
			tableContent = [TSIOUtils listLocalFiles];
//			tableContent = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask];
			//		tableContent = [fileManager URLsForDirectory:NSAllApplicationsDirectory inDomains:NSAllDomainsMask];
		}
//		if (tableContent) {
//			for (int i=0; i<[tableContent count]; i++) {
//				NSLog(@"Contents of folder : %@", [tableContent objectAtIndex:i]);
//				NSError *error;
//				NSArray *dirList = [fileManager contentsOfDirectoryAtPath:[[tableContent objectAtIndex:i] path] error:&error];
//				if (error) {
//					NSLog(@"ERROR :: %@", [error debugDescription]);
//				}else {
//					for (int j=0; j<[dirList count]; j++) {
//						NSLog(@"Child : %@", [dirList objectAtIndex:j]);
//					}
//				}
//			}
//		}
		
		return [tableContent count];
	}else if (section == 2) {
		if (!iCloudDocuments) {
			[self startCloudQuery];
			return 1;
		}else {
			return [iCloudDocuments count];
		}
	}else {
		if (!dropboxItems) {
			[self refreshDropbox:nil];
			return 1;
		}else {
			return [dropboxItems count];
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 1) {
		static NSString *CellIdentifier = @"FSCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		NSString *filePath = [tableContent objectAtIndex:indexPath.row];
		cell.textLabel.text = [filePath lastPathComponent];
		cell.detailTextLabel.text = filePath;
		
		return cell;
	}else if(indexPath.section == 2) {
		static NSString *CellIdentifier = @"FSCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

		if (iCloudDocuments) {
			NSURL *url = [iCloudDocuments objectAtIndex:indexPath.row];
			cell.textLabel.text = [url lastPathComponent];
			cell.detailTextLabel.text = [url path];
		}else {
			cell.textLabel.text = @"Loading iCloud items...";
		}

		return cell;
	}else {
		static NSString *CellIdentifier = @"FSCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if (dropboxItems) {
			DBMetadata *dropboxFileMetadata = [dropboxItems objectAtIndex:indexPath.row];
			cell.textLabel.text = dropboxFileMetadata.filename;
			cell.detailTextLabel.text = dropboxFileMetadata.description;
		}else {
			cell.textLabel.text = @"Loading Dropbox items...";
		}
		
		return cell;
	}
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if (indexPath.section == 2) {
			NSURL *url = [iCloudDocuments objectAtIndex:indexPath.row];
			[self removeCloudURL:url];
			[self refreshDropbox:nil];
		}else if (indexPath.section == 0) {
			DBMetadata *dropboxFileMetadata = [dropboxItems objectAtIndex:indexPath.row];
			[[self dropboxRestClient] deletePath:[dropboxFileMetadata path]];
			[self refreshDropbox:nil];
		}else if (indexPath.section == 1) {
			NSString *filePath = [tableContent objectAtIndex:indexPath.row];
			if (![TSIOUtils deleteLocalFile:[filePath lastPathComponent]]) {
				[TSNotifierUtils error:@"Delete file failed"];
			}else {
				[TSNotifierUtils info:@"Local file deleted"];
			}
			tableContent = nil;
			[self.tableView reloadData];
		}
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		NSString *path = [tableContent objectAtIndex:indexPath.row];
		UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
		pasteboard.string = path;
		
		//	[[NSNotificationCenter defaultCenter] postNotificationName:@"TScopy" 
		//				object:[NSString stringWithFormat:@"%@ copied to clipboard", [url lastPathComponent]]];
		//	[[NSNotificationCenter defaultCenter] postNotificationName:@"TScopy" object:self];
		
		
		//	UILocalNotification *notif = [[UILocalNotification alloc] init];
		//	notif.alertBody = [NSString stringWithFormat:@"%@ copied to clipboard", [url lastPathComponent]];
		//    notif.alertAction = @"View Details";
		//	notif.soundName = UILocalNotificationDefaultSoundName;
		//	notif.applicationIconBadgeNumber = 666;
		//    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
		
		NSString *notificationMessage = [NSString stringWithFormat:@"%@ copied to clipboard", [path lastPathComponent]];
		[TSNotifierUtils info:notificationMessage];
	}else if(indexPath.section == 2) {
		if (iCloudDocuments) {
			NSURL *url = [iCloudDocuments objectAtIndex:indexPath.row];
			NSString *text = [url lastPathComponent];
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = text;
			
			NSString *notificationMessage = [NSString stringWithFormat:@"%@ copied to clipboard", text];
			[TSNotifierUtils info:notificationMessage];
		}else {
			NSString *notificationMessage = @"Not loaded yet...";
			[TSNotifierUtils error:notificationMessage];
		}
	}else {
		if (dropboxItems) {
			DBMetadata *dropboxFileMetadata = [dropboxItems objectAtIndex:indexPath.row];
			NSString *text = dropboxFileMetadata.filename;
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = text;
			
			NSString *notificationMessage = [NSString stringWithFormat:@"%@ copied to clipboard", text];
			[TSNotifierUtils info:notificationMessage];
		}else {
			NSString *notificationMessage = @"Not loaded yet...";
			[TSNotifierUtils error:notificationMessage];
		}
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
