//
//  ViewController.m
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 29/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.opaqueTappedLabel.alpha = 0.0f;
    self.transparentTappedLabel.alpha = 0.0f;

    __weak typeof(self) weakSelf = self;
    self.opaqueButton.tappedHandler = ^{
        [weakSelf playFadeAnimationOnView:weakSelf.opaqueTappedLabel];
    };

    self.clearButton.tappedHandler = ^{
        [weakSelf playFadeAnimationOnView:weakSelf.transparentTappedLabel];
    };
}

- (void)playFadeAnimationOnView:(UIView *)view
{
    [view.layer removeAllAnimations];
    view.alpha = 1.0f;

    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95f, 0.95f);
    [UIView animateWithDuration:0.3f delay:0.0f usingSpringWithDamping:0.1f initialSpringVelocity:0.5f options:0 animations:^{
        view.transform = CGAffineTransformIdentity;
    } completion:nil];

    [UIView animateWithDuration:1.0f delay:0.3f options:0 animations:^{
        view.alpha = 0.0f;
    } completion:nil];
}

@end
