//
//  TSTabBarController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/29/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSTabBarController.h"

@interface TSTabBarController ()

@end

@implementation TSTabBarController

#pragma mark - events

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	if (item.tag == 0) {
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
