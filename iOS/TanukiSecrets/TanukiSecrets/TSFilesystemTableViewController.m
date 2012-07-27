//
//  TSFilesystemTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 7/20/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSFilesystemTableViewController.h"
#import "JSNotifier.h"
#import <DropboxSDK/DropboxSDK.h>

@interface TSFilesystemTableViewController () <DBRestClientDelegate> {

	NSArray *tableContent;
	NSArray *dropboxItems;//DBMetadata
	
	DBRestClient *dropboxRestClient;
}
@end

@implementation TSFilesystemTableViewController

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

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
	
    NSLog(@"Error loading metadata: %@", error);
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
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
}

@end
