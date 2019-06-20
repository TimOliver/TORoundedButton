//
//  ViewController.h
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 29/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TORoundedButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet TORoundedButton *button;
@property (weak, nonatomic) IBOutlet UILabel *tappedLabel;

@end

NS_ASSUME_NONNULL_END
