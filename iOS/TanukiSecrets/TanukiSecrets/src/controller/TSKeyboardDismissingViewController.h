//
//  TSKeyboardDismissingViewController.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/26/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Reusable view controller that provides the code to dismiss the keyboard
 when a tap is detected outside the editable views.
 */
@interface TSKeyboardDismissingViewController : UIViewController<UIGestureRecognizerDelegate>

//Subclasses should return all the UIViews that need to keep the keyboard on screen.
- (NSArray *)viewsThatNeedKeyboard;

//callback for subclasses, one of the views that still need the keyboard was tapped
- (void)viewWasTapped:(UIView *)view;

/*callback for subclasses, a tap that did not fall inside any of the views with keyboard 
 was detected, the parameter tells which of the views was first responder and resigned the 
 status following this outside tap (and is nil if none of the views was the first responder) */
- (void)outsideTapped:(UIView *)viewThatLostTheKeyboard;

@end
