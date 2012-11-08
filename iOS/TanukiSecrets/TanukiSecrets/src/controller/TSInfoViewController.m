//
//  TSInfoViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/30/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSInfoViewController.h"

#import "TSNotifierUtils.h"

@interface TSInfoViewController ()

@end

@implementation TSInfoViewController

#pragma mark - events

- (IBAction)dismiss:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
