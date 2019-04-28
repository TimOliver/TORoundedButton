//
//  TORoundedButton.h
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RoundedButton)
IB_DESIGNABLE @interface TORoundedButton : UIControl

/** The text that is displayed in center of the button (Default is "Button") */
@property (nonatomic, copy) IBInspectable NSString *text;

/** The radius of the corners of this button (Default is 10.0f) */
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

/** The color of the text in this button (Default is white) */
@property (nonatomic, strong) IBInspectable UIColor *textColor;

/** When tapped, the level of transparency that the text label animates to. (Defaults to 0.5f) */
@property (nonatomic, assign) IBInspectable CGFloat tappedTextAlpha;

/** The font of the text in the button (Default is size 21 Bold) */
@property (nonatomic, strong) UIFont *textFont;

/** Because IB cannot handle fonts, this can alternatively be used to set the font size. (Default is off with 0.0) */
@property (nonatomic, assign) IBInspectable CGFloat textPointSize;

/** If desired, set the background color of the button when tapped (Default is nil). */
@property (nonatomic, strong, nullable) IBInspectable UIColor *tappedTintColor;

/** When tapped, the scale by which the button shrinks during the animation (Default is off with 0.0) */
@property (nonatomic, assign) IBInspectable CGFloat tappedButtonScale;

/** The duration of the tapping cross-fade animation (Default is 0.4f) */
@property (nonatomic, assign) CGFloat tapAnimationDuration;

/** A callback handler triggered each time the button is tapped. */
@property (nonatomic, copy) void (^tappedHandler)(void);

/** Create a new instance with the supplied button text. */
- (instancetype)initWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
