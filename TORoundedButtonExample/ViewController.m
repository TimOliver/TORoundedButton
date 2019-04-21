//
//  ViewController.m
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TORoundedButton.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet TORoundedButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.button.tappedHandler = ^{
        NSLog(@"HI TWITCH");
    };
}

@end
