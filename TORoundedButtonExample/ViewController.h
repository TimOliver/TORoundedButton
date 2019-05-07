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

@property (weak, nonatomic) IBOutlet TORoundedButton *opaqueButton;
@property (weak, nonatomic) IBOutlet TORoundedButton *clearButton;

@property (weak, nonatomic) IBOutlet UILabel *opaqueTappedLabel;
@property (weak, nonatomic) IBOutlet UILabel *transparentTappedLabel;

@end

NS_ASSUME_NONNULL_END
