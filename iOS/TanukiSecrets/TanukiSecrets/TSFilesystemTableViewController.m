//
//  TSFilesystemTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 7/20/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSFilesystemTableViewController.h"
#import "TSItem.h"
#import "TSListOfItems.h"
#import "TSXMLSerializable.h"

#import "JSNotifier.h"
#import "XMLWriter.h"

#import <DropboxSDK/DropboxSDK.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/Security.h>

@interface TSFilesystemTableViewController () <DBRestClientDelegate> {

	NSArray *tableContent;
	NSArray *dropboxItems;//DBMetadata
	
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

- (NSString *)demoFileContent
{
	XMLWriter *xmlWriter = [[XMLWriter alloc] init];
	TSListOfItems *listOfItems = [[TSListOfItems alloc] init];
	[listOfItems addItem:[self demoItem]];
	[listOfItems addItem:[self demoItem]];
	[listOfItems writeTo:xmlWriter];
	
	return [xmlWriter toString];
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

#pragma mark - Encryption

- (NSData *) sha512:(NSString *) string
{
	NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char hash[CC_SHA512_DIGEST_LENGTH];
	CC_SHA512([bytes bytes], [bytes length], hash);
	return [NSData dataWithBytes:hash length:CC_SHA512_DIGEST_LENGTH];
}

- (NSData *) md5:(NSString *) string
{
	NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5([bytes bytes], [bytes length], hash);
	return [NSData dataWithBytes:hash length:CC_MD5_DIGEST_LENGTH];
}

- (NSData *) randomDataOfLength:(NSInteger)length
{
	uint8_t *buf = malloc( length * sizeof(uint8_t) );
	OSStatus sanityCheck = SecRandomCopyBytes(kSecRandomDefault, length, buf);
	NSData *ret = nil;
	if (sanityCheck == noErr) {
		ret = [[NSData alloc] initWithBytes:buf length:length];
	}else {
		NSLog(@"Random data generation failed");
	}
	free(buf);
	buf = NULL;
	return ret;
}

- (NSString *) hexStringFor:(NSData *) data
{
	NSString *ret = [data description];
	ret = [ret stringByReplacingOccurrencesOfString:@" " withString:@""];
	ret = [ret stringByReplacingOccurrencesOfString:@"<" withString:@""];
	ret = [ret stringByReplacingOccurrencesOfString:@">" withString:@""];
	return ret;
}

- (NSData *) tanukiHash:(NSString *) secret usingSalt:(NSData *)salt
{
	NSLog(@"TanukiHash called, using secret %@ and salt %@", secret, [salt description]);
	unsigned long bufSize = 1024l * 1024 * 13;
	uint8_t *buf = malloc(bufSize * sizeof(uint8_t));
	NSData *secretBytes = [secret dataUsingEncoding:NSUTF8StringEncoding];
	CC_SHA512([secretBytes bytes], [secretBytes length], buf);
	CC_SHA512([salt bytes], [salt length], buf + CC_SHA512_DIGEST_LENGTH);
	unsigned long n = bufSize / CC_SHA512_DIGEST_LENGTH;
	for (unsigned long i=2; i<n; i++) {
		CC_SHA512(buf + (i - 2) * CC_SHA512_DIGEST_LENGTH, CC_SHA512_DIGEST_LENGTH,
				  buf + i * CC_SHA512_DIGEST_LENGTH);
	}
	
	NSData *bytes = [NSData dataWithBytes:buf length:bufSize];
	free(buf);
	unsigned char hash2[CC_MD5_DIGEST_LENGTH];
	CC_MD5([bytes bytes], [bytes length], hash2);
	NSData *ret = [NSData dataWithBytes:hash2 length:CC_MD5_DIGEST_LENGTH];
	NSLog(@"TanukiHash returning %@", [ret description]);
	return ret;
}

- (NSData *)encryptData:(NSData *) data usingKey:(NSData *)key
{
	NSLog(@"encryptData start...");
	
	NSData *initializationVector = [self tanukiHash:@"TanukiSecrets" usingSalt:key];
	NSLog(@"iv : %@", [initializationVector description]);
	
	NSMutableData *encryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	size_t outLength;
	CCCryptorStatus cryptStatus = 
	CCCrypt(
			kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
			[key bytes], [key length], [initializationVector bytes],
			[data bytes], [data length],
			[encryptedData mutableBytes], [encryptedData length],
			&outLength);
	if (cryptStatus == kCCSuccess) {
		[encryptedData setLength:outLength];
	}else {
		NSLog(@"Something went wrong...");
		encryptedData = nil;
	}

	NSLog(@"encrypted :: %@", [encryptedData description]);
	return encryptedData;
}

- (NSData *)decryptData:(NSData *) data usingKey:(NSData *)key
{
	NSLog(@"decryptData start...");
	
	NSData *initializationVector = [self tanukiHash:@"TanukiSecrets" usingSalt:key];
	NSLog(@"iv : %@", [initializationVector description]);
	
	NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	size_t outLength;
	CCCryptorStatus cryptStatus = 
	CCCrypt(
			kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
			[key bytes], [key length], [initializationVector bytes],
			[data bytes], [data length],
			[decryptedData mutableBytes], [decryptedData length],
			&outLength);
	if (cryptStatus == kCCSuccess) {
		[decryptedData setLength:outLength];
	}else {
		NSLog(@"Something went wrong...");
		decryptedData = nil;
	}
	
	NSLog(@"decrypted :: %@", [decryptedData description]);
	return decryptedData;
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
	[[self dropboxRestClient] loadMetadata:@"/"];
	UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc] 
									 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[busy startAnimating];
	UIBarButtonItem *refreshDropboxButton = [[UIBarButtonItem alloc] 
											 initWithCustomView:busy];	
	self.navigationItem.rightBarButtonItem = refreshDropboxButton;
}

- (IBAction)addDropboxItem:(UIButton *)sender {
//	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//	[dateFormat setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
//	NSString *filename = [dateFormat stringFromDate:[NSDate date]];
	
	NSData *salt = [self randomDataOfLength:(32 + arc4random() % 64)];
	NSData *key = [self tanukiHash:@"TheTanukiSais...NI-PAH~!" usingSalt:salt];
	NSString *filename = [self hexStringFor:salt];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

	NSString *fileContent = [self demoFileContent];
	NSLog(@"Encrypt-decrypt test for |%@|", fileContent);
	NSData *encryptedData = [self encryptData:[fileContent dataUsingEncoding:NSUTF8StringEncoding] usingKey:key];
	NSData *decryptedData = [self decryptData:encryptedData usingKey:key];
	NSLog(@"Result of encrypt-decrypt : |%@|", 
		  [[NSString alloc] initWithBytes:[decryptedData bytes] 
								   length:[decryptedData length] 
								 encoding:NSUTF8StringEncoding]);
	[self readListOfItems:decryptedData];
	[fileManager createFileAtPath: filePath
						 contents:encryptedData 
					   attributes:nil];
	tableContent = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask];
	[[self dropboxRestClient] uploadFile:filename toPath:@"/" withParentRev:nil fromPath:filePath];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Dropbox";
	}else if (section == 1) {
		return @"Local";
	}else {
		return @"???";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (!tableContent) {
			tableContent = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask];
			//		tableContent = [fileManager URLsForDirectory:NSAllApplicationsDirectory inDomains:NSAllDomainsMask];
		}
		if (tableContent) {
			for (int i=0; i<[tableContent count]; i++) {
				NSLog(@"Contents of folder : %@", [tableContent objectAtIndex:i]);
				NSError *error;
				NSArray *dirList = [fileManager contentsOfDirectoryAtPath:[[tableContent objectAtIndex:i] path] error:&error];
				if (error) {
					NSLog(@"ERROR :: %@", [error debugDescription]);
				}else {
					for (int j=0; j<[dirList count]; j++) {
						NSLog(@"Child : %@", [dirList objectAtIndex:j]);
					}
				}
			}
		}
		
		return [tableContent count];
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
		
		NSURL *url = [tableContent objectAtIndex:indexPath.row];
		cell.textLabel.text = [url lastPathComponent];
		
		cell.detailTextLabel.text = [url path];
		
		return cell;
	}else {
		static NSString *CellIdentifier = @"FSCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if (dropboxItems) {
			DBMetadata *dropboxFileMetadata = [dropboxItems objectAtIndex:indexPath.row];
			cell.textLabel.text = dropboxFileMetadata.filename;
			
			cell.detailTextLabel.text = dropboxFileMetadata.description;
		}else {
			cell.textLabel.text = @"Dropbox listing not loaded yet";
		}
		
		return cell;
	}
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
		NSURL *url = [tableContent objectAtIndex:indexPath.row];
		UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
		pasteboard.string = [url path];
		
		//	[[NSNotificationCenter defaultCenter] postNotificationName:@"TScopy" 
		//				object:[NSString stringWithFormat:@"%@ copied to clipboard", [url lastPathComponent]]];
		//	[[NSNotificationCenter defaultCenter] postNotificationName:@"TScopy" object:self];
		
		
		//	UILocalNotification *notif = [[UILocalNotification alloc] init];
		//	notif.alertBody = [NSString stringWithFormat:@"%@ copied to clipboard", [url lastPathComponent]];
		//    notif.alertAction = @"View Details";
		//	notif.soundName = UILocalNotificationDefaultSoundName;
		//	notif.applicationIconBadgeNumber = 666;
		//    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
		
		NSString *notificationMessage = [NSString stringWithFormat:@"%@ copied to clipboard", [url lastPathComponent]];
		JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:notificationMessage];
		jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck.png"]];
		[jsn showFor:2.0];
	}else {
		if (dropboxItems) {
			DBMetadata *dropboxFileMetadata = [dropboxItems objectAtIndex:indexPath.row];
			NSString *text = dropboxFileMetadata.filename;
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = text;
			
			NSString *notificationMessage = [NSString stringWithFormat:@"%@ copied to clipboard", text];
			JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:notificationMessage];
			jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyCheck.png"]];
			[jsn showFor:2.0];
		}else {
			NSString *notificationMessage = @"Not loaded yet...";
			JSNotifier *jsn = [[JSNotifier alloc] initWithTitle:notificationMessage];
			jsn.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotifyX.png"]];
			[jsn showFor:2.0];
		}
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
