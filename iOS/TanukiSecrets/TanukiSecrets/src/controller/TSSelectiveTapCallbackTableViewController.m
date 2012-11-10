//
//  TSSelectiveTapCallbackTableViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 11/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSSelectiveTapCallbackTableViewController.h"

@interface TSSelectiveTapCallbackTableViewController ()

@end

@implementation TSSelectiveTapCallbackTableViewController

#pragma mark - dummy implementations for "abstract" methods

- (NSArray *)viewsThatNeedTapCallback
{
	return nil;
}

- (void)viewWasTapped:(UIView *)view
{
}

- (void)outsideTapped
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
	NSArray *viewsThatNeedTapCallback = [self viewsThatNeedTapCallback];
	for (UIView *view in viewsThatNeedTapCallback) {
//		NSLog (@"Test for frame %f %f - %f %f", [view frame].origin.x, [view frame].origin.y,
//			   [view frame].origin.x + [view frame].size.height,
//			   [view frame].origin.y + [view frame].size.width);
		if (CGRectContainsPoint([view frame], tapLocation)) {
			[self viewWasTapped:view];
			tappedInView = YES;
//			NSLog (@"hit");
		}else {
//			NSLog (@"miss");
		}
	}
	if (tappedInView == NO) {
//		NSLog (@"Tap was outside of views that need callback");
		[self outsideTapped];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
}

@end
