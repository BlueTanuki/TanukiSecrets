//
//  TSUnlockViewController.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 8/1/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUnlockViewController.h"

@interface TSUnlockViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *unlockCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *unlockCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;

@end

@implementation TSUnlockViewController

@synthesize unlockCodeTextField;
@synthesize unlockCodeLabel;
@synthesize onOffSwitch;

BOOL firstTimeSegueTriggered = NO;

#pragma mark - Listeners

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([self.unlockCodeTextField.text isEqualToString:@"Mellon"]) {
		[self performSegueWithIdentifier:@"unlockCodeOkSegue" sender:nil];
		NSLog(@"perform segue invoked...");
		[self.unlockCodeTextField resignFirstResponder];
	}else {
		self.unlockCodeLabel.textColor = [UIColor redColor];
		self.unlockCodeTextField.text = nil;
		[self.view setNeedsDisplay];
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self.unlockCodeTextField resignFirstResponder];
	NSLog(@"Editing ended, value is :: %@", unlockCodeTextField.text);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSLog(@"Segue %@ sender %@", [segue debugDescription], [sender debugDescription]);
}

- (IBAction)go:(id)sender {
	NSLog(@"onOffSwitch :: %@", [self.onOffSwitch debugDescription]);
	if (self.onOffSwitch.on) {
		[self performSegueWithIdentifier:@"onSegue" sender:nil];
	}else {
		[self performSegueWithIdentifier:@"offSegue" sender:nil];
	}
}

#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.unlockCodeTextField.delegate = self;
}

- (void)viewDidUnload
{
	[self setUnlockCodeTextField:nil];
	[self setUnlockCodeLabel:nil];
	[self setOnOffSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.unlockCodeLabel.textColor = [UIColor blackColor];
	self.unlockCodeTextField.text = nil;
	[self.unlockCodeTextField becomeFirstResponder];
//	self.unlockCodeTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//	self.unlockCodeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
//	self.unlockCodeTextField.enablesReturnKeyAutomatically = YES;
//	self.unlockCodeTextField.secureTextEntry = YES;
//	self.unlockCodeTextField.keyboardType = UIKeyboardTypeNumberPad;
//	self.unlockCodeTextField.returnKeyType = UIReturnKeyDone;
}

- (void) viewDidAppear:(BOOL)animated
{
	if (!firstTimeSegueTriggered) {
		firstTimeSegueTriggered = YES;
		[self performSegueWithIdentifier:@"unlockCodeOkSegue" sender:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
