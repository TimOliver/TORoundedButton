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

    self.clearButton.attributedText = [NSAttributedString exampleString];

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

@implementation NSAttributedString (TORoundedButton)

+ (NSAttributedString*)exampleString
{
    NSMutableAttributedString *mutString = [NSMutableAttributedString new];
    NSAttributedString *string1 = [[NSAttributedString alloc] initWithString:@"A" attributes:
                                   @{
                                     NSFontAttributeName : [UIFont fontWithName:@"Zapfino" size:22],
                                     NSForegroundColorAttributeName : [UIColor whiteColor]
                                     }];
    [mutString appendAttributedString:string1];
    NSAttributedString *string2 = [[NSAttributedString alloc] initWithString:@"tt" attributes:
                                   @{
                                     NSFontAttributeName : [UIFont fontWithName:@"Zapfino" size:17],
                                     NSForegroundColorAttributeName : [UIColor orangeColor]
                                     }];
    [mutString appendAttributedString:string2];
    NSAttributedString *string3 = [[NSAttributedString alloc] initWithString:@"ribu" attributes:
                                   @{
                                     NSFontAttributeName : [UIFont fontWithName:@"ChalkboardSE-Regular" size:16],
                                     NSForegroundColorAttributeName : [UIColor yellowColor]
                                     }];
    [mutString appendAttributedString:string3];
    NSAttributedString *string4 = [[NSAttributedString alloc] initWithString:@"ted" attributes:
                                   @{
                                     NSFontAttributeName : [UIFont fontWithName:@"Courier" size:22],
                                     NSForegroundColorAttributeName : [UIColor greenColor]
                                     }];
    [mutString appendAttributedString:string4];

    return [mutString copy];
}

@end
