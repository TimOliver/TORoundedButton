//
//  TORoundedButton.h
//
//  Copyright 2019-2023 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RoundedButton)
IB_DESIGNABLE @interface TORoundedButton : UIControl

/// The text that is displayed in center of the button (Default is "Button").
@property (nonatomic, copy) IBInspectable NSString *text;

/// The attributed string used in the label of this button. See `UILabel.attributedText` documentation for full details (Default is nil).
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;

/// The radius of the corners of this button (Default is 12.0f).
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

/// The color of the text in this button (Default is white).
@property (nonatomic, strong) IBInspectable UIColor *textColor;

/// When tapped, the level of transparency that the text label animates to. (Defaults to off with 1.0f).
@property (nonatomic, assign) IBInspectable CGFloat tappedTextAlpha;

/// The font of the text in the button (Default is size UIFontTextStyleBody with bold).
@property (nonatomic, strong) UIFont *textFont;

/// Because IB cannot handle fonts, this can alternatively be used to set the font size. (Default is off with 0.0).
@property (nonatomic, assign) IBInspectable CGFloat textPointSize;

/// Taking the default button background color apply a brightness offset for the tapped color (Default is -0.1f. Set 0.0 for off).
@property (nonatomic, assign) IBInspectable CGFloat tappedTintColorBrightnessOffset;

/// If desired, explicity set the background color of the button when tapped (Default is nil).
@property (nonatomic, strong, nullable) IBInspectable UIColor *tappedTintColor;

/// When tapped, the scale by which the button shrinks during the animation (Default is 0.97f).
@property (nonatomic, assign) IBInspectable CGFloat tappedButtonScale;

/// The duration of the tapping cross-fade animation (Default is 0.4f).
@property (nonatomic, assign) CGFloat tapAnimationDuration;

/// Given the current size of the text label, the smallest horizontal width in which this button can scale.
@property (nonatomic, readonly) CGFloat minimumWidth;

/// A callback handler triggered each time the button is tapped.
@property (nonatomic, copy) void (^tappedHandler)(void);

/// Create a new instance of a button with the provided text shown in the center. The size will be 288 points wide, and 50 tall.
- (instancetype)initWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END

FOUNDATION_EXPORT double TORoundedButtonVersionNumber;
FOUNDATION_EXPORT const unsigned char TORoundedButtonVersionString[];
