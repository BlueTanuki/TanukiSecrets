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

- (void)sessionWasLinked
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	int64_t delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
			NSNotification *notificatopn = [NSNotification notificationWithName:TS_NOTIFICATION_DROPBOX_WAS_LINKED object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notificatopn];
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

- (IBAction)link:(id)sender {
	if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (IBAction)cancel:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
