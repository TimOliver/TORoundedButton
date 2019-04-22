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

/** The text that is displayed in center of the button (Default is "Button") */
@property (nonatomic, copy) IBInspectable NSString *text;

/** The color of the text in this button (Default is white) */
@property (nonatomic, strong) IBInspectable UIColor *textColor;

/** The font of the text in the button (Default is size 21 Bold) */
@property (nonatomic, strong) UIFont *textFont;

/** The radius of the corners of this button (Default is 10.0f) */
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

/** A callback handler triggered each time the button. */
@property (nonatomic, copy) void (^tappedHandler)(void);

@end

NS_ASSUME_NONNULL_END
