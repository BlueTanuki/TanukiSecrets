//
//  TSTabBarController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/29/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSTabBarController.h"

#import "TSSharedState.h"

@interface TSTabBarController ()

@end

@implementation TSTabBarController

#pragma mark - events

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	if (item.tag == 0) {
		[[TSSharedState sharedState] reset];
		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			NSNotification *notificaton = [NSNotification notificationWithName:TS_NOTIFICATION_DATABASE_WAS_LOCKED_SUCCESSFULLY object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notificaton];
		}];
	}
}

@end
