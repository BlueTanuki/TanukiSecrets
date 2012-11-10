//
//  TSSelectiveTapCallbackTableViewController
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 Layer on top of a table view controller that detects taps and notifies subclasses 
 about which view was hit. This is meant as the equivalent of a keyboard dismissing
 view controller, but when text fields are inside tables, the test about which 
 one was hit is completely unreliable, so keyboard management is left to subclasses.
 */
@interface TSSelectiveTapCallbackTableViewController : UITableViewController<UIGestureRecognizerDelegate>

//Subclasses should return all the UIViews that are interested in a tap callback.
- (NSArray *)viewsThatNeedTapCallback;

//callback for subclasses, one of the views was tapped
- (void)viewWasTapped:(UIView *)view;

//callback for subclasses, a tap that did not fall inside any of the returned views
- (void)outsideTapped;

@end
