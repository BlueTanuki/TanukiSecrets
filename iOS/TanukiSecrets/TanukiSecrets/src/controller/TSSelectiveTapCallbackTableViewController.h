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

//replacement for viewWasTapped callback, this callback also tells the location of the tap
//subclasses should implement only one of the two, both will be called for taps inside views
- (void)tap:(CGPoint)tapLocation wasDetectedForView:(UIView *)view;

//callback for subclasses, a tap that did not fall inside any of the returned views
- (void)outsideTapped;

//subclasses should return NO if the tap event should not be exclusively consumed by this component
//default implementation returns YES (meaning that the tap event will not reach any cells)
- (BOOL)tapGestureRecognizerConsumesEvent;

@end
