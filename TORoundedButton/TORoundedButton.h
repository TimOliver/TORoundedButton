//
//  TORoundedButton.h
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface TORoundedButton : UIControl

@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@property (nonatomic, copy) void (^tappedHandler)(void);

@end

NS_ASSUME_NONNULL_END
