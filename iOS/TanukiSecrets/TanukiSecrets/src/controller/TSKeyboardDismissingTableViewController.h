//
//  TSKeyboardDismissingTableViewController.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 Mirror of the keyboard dismissing view controller for table views.
 */
@interface TSKeyboardDismissingTableViewController : UITableViewController<UIGestureRecognizerDelegate>

//Subclasses should return all the UIViews that need to keep the keyboard on screen.
- (NSArray *)viewsThatNeedKeyboard;

//Subclasses should return all the UIViews that do not need a keyboard but are interested in a tap callback.
//this is to be used in when the tap event intercepted by this layer does not reach the view
//(the logic is a bit fuzzy here, buttons still receive the tap, cells do not)
- (NSArray *)viewsThatNeedTapCallback;

//callback for subclasses, one of the views that still need the keyboard was tapped
- (void)viewWasTapped:(UIView *)view;

/*callback for subclasses, a tap that did not fall inside any of the views with keyboard
 was detected, the parameter tells which of the views was first responder and resigned the
 status following this outside tap (and is nil if none of the views was the first responder) */
- (void)outsideTapped:(UIView *)viewThatLostTheKeyboard;

@end
