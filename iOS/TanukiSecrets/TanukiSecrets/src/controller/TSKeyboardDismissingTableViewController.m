//
//  TSKeyboardDismissingTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSKeyboardDismissingTableViewController.h"

@interface TSKeyboardDismissingTableViewController ()

@end

@implementation TSKeyboardDismissingTableViewController

#pragma mark - dummy implementations for "abstract" methods

- (NSArray *)viewsThatNeedKeyboard
{
	return nil;
}

- (NSArray *)viewsThatNeedTapCallback
{
	return nil;
}

- (void)viewWasTapped:(UIView *)view
{
}

- (void)outsideTapped:(UIView *)viewThatLostTheKeyboard
{
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

#pragma mark - setting up and responding to taps

- (void)tap:(UITapGestureRecognizer *)gestureRecognizer {
	CGPoint tapLocation = [gestureRecognizer locationInView:self.view];
//	NSLog (@"Tap %f %f", tapLocation.x, tapLocation.y);
	BOOL tappedInView = NO;
	NSArray *viewsWithKeyboard = [self viewsThatNeedKeyboard];
	for (UIView *viewWithKeyboard in viewsWithKeyboard) {
		if (CGRectContainsPoint([viewWithKeyboard frame], tapLocation)) {
			[self viewWasTapped:viewWithKeyboard];
			tappedInView = YES;
		}
	}
	if (tappedInView == NO) {
		NSArray *viewsThatNeedTapCallback = [self viewsThatNeedTapCallback];
		for (UIView *view in viewsThatNeedTapCallback) {
			if (CGRectContainsPoint([view frame], tapLocation)) {
				[self viewWasTapped:view];
				//tappedInView = YES; --leave it to NO so the keyboard will be dismissed
			}
		}
	}
	if (tappedInView == NO) {
		BOOL resignedFirstResponder = NO;
		for (UIView *viewWithKeyboard in viewsWithKeyboard) {
			if ([viewWithKeyboard isFirstResponder]) {
				[viewWithKeyboard resignFirstResponder];
				[self outsideTapped:viewWithKeyboard];
				resignedFirstResponder = YES;
			}
		}
		if (resignedFirstResponder == NO) {
			[self outsideTapped:nil];
		}
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	tapRecognizer.delegate = self;
	//	NSLog (@"self.view is %@", [self.view debugDescription]);
	//	NSLog (@"%d gesture recognizers on the view", [[self.view gestureRecognizers] count]);
	//	[self.view addGestureRecognizer:tapRecognizer];
	//	NSLog (@"%d gesture recognizers on the view", [[self.view gestureRecognizers] count]);
	//if added here, something resets it ????
	NSArray *additionalViews = [self viewsThatNeedKeyboard];
	for (UIView *additionalView in additionalViews) {
		[additionalView addGestureRecognizer:tapRecognizer];
		//		NSLog (@"%d gesture recognizers on the subview", [[additionalView gestureRecognizers] count]);
	}
	//	NSLog (@"%d gesture recognizers on the view", [[self.view gestureRecognizers] count]);
	[self.view addGestureRecognizer:tapRecognizer];
	//if added here, it stays... apple works in mysterious ways
	//	NSLog (@"%d gesture recognizers on the view", [[self.view gestureRecognizers] count]);
}

@end
