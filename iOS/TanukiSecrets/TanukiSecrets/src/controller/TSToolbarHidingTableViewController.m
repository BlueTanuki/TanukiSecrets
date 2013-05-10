//
//  TSToolbarHidingTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 5/1/13.
//  Copyright (c) 2013 BlueTanuki. All rights reserved.
//

#import "TSToolbarHidingTableViewController.h"

@interface TSToolbarHidingTableViewController ()

@end

@implementation TSToolbarHidingTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:YES];
}

@end
