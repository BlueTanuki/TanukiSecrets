//
//  TSNavigationController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/25/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSNavigationController.h"

@implementation TSNavigationController

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

@end
