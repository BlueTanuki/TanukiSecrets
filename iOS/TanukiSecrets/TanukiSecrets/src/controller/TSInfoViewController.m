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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	switch (indexPath.section) {
		case 0:
			cell.textLabel.text = @"Help";
			break;
			
		case 1:
			cell.textLabel.text = @"FAQ";
			break;
			
		case 2:
			cell.textLabel.text = @"Credits";
			break;
			
		default:
			break;
	}
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[TSNotifierUtils error:@"NOT IMPLEMENTED"];
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - events

- (IBAction)dismiss:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
