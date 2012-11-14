//
//  TSLinkWithDropboxViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/22/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSLinkWithDropboxViewController.h"

#import <DropboxSDK/DropboxSDK.h>

#import "TSConstants.h"

@interface TSLinkWithDropboxViewController ()

@end

@implementation TSLinkWithDropboxViewController

//- (void)willResignActive:(NSNotification*)notification
//{
//	NSLog (@"will enter background");
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Allow access to your account?";
	}
	return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Before using any Dropbox features, you must grant TanukiSecrets access to your Dropbox account. "
		"This application does not access any of your existing files, you only need to grant permission "
		"to a separate folder where all the necessary files will be kept. You will have full access to these files, "
		"but you should only edit them through this application. Please press the 'Link With Dropbox' button "
		"to begin this one-time process that will link TanukiSecrets with your Dropbox account.";
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1) {
		return 1;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
	cell.textLabel.text = @"Link With Dropbox";
	cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

#pragma mark - events

- (void)sessionWasLinked
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	int64_t delayInSeconds = 2;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
			NSNotification *notification = [NSNotification notificationWithName:TS_NOTIFICATION_DROPBOX_WAS_LINKED object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}];
	});
}

- (void)didBecomeActive:(NSNotification*)notification
{
//	NSLog (@"again in foreground");
	if ([[DBSession sharedSession] isLinked]) {
		[self sessionWasLinked];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([[DBSession sharedSession] isLinked]) {
		[self sessionWasLinked];
	}else {
		[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didBecomeActive:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	}
}

- (IBAction)cancel:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
