//
//  TSLinkWithDropboxViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/22/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSLinkWithDropboxViewController.h"

#import <DropboxSDK/DropboxSDK.h>

@interface TSLinkWithDropboxViewController ()

@end

@implementation TSLinkWithDropboxViewController

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([[DBSession sharedSession] isLinked]) {
		[[self presentingViewController] dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)link:(id)sender {
	if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (IBAction)cancel:(id)sender {
	[[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

@end
