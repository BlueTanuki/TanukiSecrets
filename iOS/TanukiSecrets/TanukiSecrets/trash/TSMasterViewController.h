//
//  TSMasterViewController.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 7/20/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TSDetailViewController;

@interface TSMasterViewController : UITableViewController

@property (strong, nonatomic) TSDetailViewController *detailViewController;

@end
