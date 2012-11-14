//
//  TSModalDialogDismissingTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/13/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSModalDialogDismissingTableViewController.h"

@interface TSModalDialogDismissingTableViewController ()

@end

@implementation TSModalDialogDismissingTableViewController

- (IBAction)cancel:(id)sender {
	if (self.presentingViewController == nil) {
		NSLog (@"WARNING : internal consistency failure : the TSModalDialogDismissingTableViewController "
			   "should only be used from views that are presented by other view controllers!");
	}else {
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
