//
//  TORoundedButton.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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

#define TOROUNDEDBUTTON_OBJC_DIRECT __attribute__((objc_direct))

#import "TORoundedButton.h"

@interface TORoundedButton ()

/** Hold on to a global state for whether we are tapped or not because the state can change before blocks complete */
@property (nonatomic, assign) BOOL isTapped;

/** A container view that holds all of the content view and performs the clipping */
@property (nonatomic, strong) UIView *containerView;

/** The title label displaying the text in the center of the button */
@property (nonatomic, strong) UILabel *titleLabel;

/** An image view that displays the rounded box behind the button text */
@property (nonatomic, strong) UIView *backgroundView;

/** Checks whether the button is tapped, or the BG is transparent to return the correct label background*/
@property (nonatomic, direct, readonly) UIColor *labelBackgroundColor;

@end

// --------------------------------------------------------------------

static inline BOOL TO_ROUNDED_BUTTON_FLOAT_IS_ZERO(CGFloat value) {
    return (value > -FLT_EPSILON) && (value < FLT_EPSILON);
}

static inline BOOL TO_ROUNDED_BUTTON_FLOATS_MATCH(CGFloat firstValue, CGFloat secondValue) {
    return fabs(firstValue - secondValue) > FLT_EPSILON;
}

// --------------------------------------------------------------------

@implementation TORoundedButton

#pragma mark - View Creation -

- (instancetype)initWithText:(NSString *)text {
    if (self = [super initWithFrame:(CGRect){0,0, 288.0f, 50.0f}]) {
        [self _roundedButtonCommonInit];
        _titleLabel.text = text;
        [_titleLabel sizeToFit];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _roundedButtonCommonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _roundedButtonCommonInit];
    }

    return self;
}

- (void)_roundedButtonCommonInit TOROUNDEDBUTTON_OBJC_DIRECT {
    // Default properties (Make sure they're not overriding IB)
    _cornerRadius = (_cornerRadius > FLT_EPSILON) ?: 12.0f;
    _tappedTextAlpha = (_tappedTextAlpha > FLT_EPSILON) ?: 1.0f;
    _tapAnimationDuration = (_tapAnimationDuration > FLT_EPSILON) ?: 0.4f;
    _tappedButtonScale = (_tappedButtonScale > FLT_EPSILON) ?: 0.97f;
    _tappedTintColorBrightnessOffset = !TO_ROUNDED_BUTTON_FLOAT_IS_ZERO(_tappedTintColorBrightnessOffset) ?: -0.15f;

    // Set the tapped tint color if we've set to dynamically calculate it
    [self _updateTappedTintColorForTintColor];

    // Create the container view that manages the image view and text
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.containerView.userInteractionEnabled = NO;
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];

    // Create the image view which will show the button background
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = self.tintColor;
    self.backgroundView.layer.cornerRadius = _cornerRadius;
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) { self.backgroundView.layer.cornerCurve = kCACornerCurveContinuous; }
#endif
    [self.containerView addSubview:self.backgroundView];

    // Create the title label that will display the button text
    UIFont *buttonFont = [UIFont systemFontOfSize:17.0f weight:UIFontWeightBold];
    if (@available(iOS 11.0, *)) {
        // Apply resizable button metrics to font
        UIFontMetrics *metrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody];
        buttonFont = [metrics scaledFontForFont:buttonFont];
    }
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = buttonFont;
    self.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.titleLabel.backgroundColor = self.labelBackgroundColor;
    self.titleLabel.text = @"Button";
    self.titleLabel.numberOfLines = 0;
    [self.containerView addSubview:self.titleLabel];

    // Create action events for all possible interactions with this control
    [self addTarget:self action:@selector(_didTouchDownInside) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDownRepeat];
    [self addTarget:self action:@selector(_didTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(_didDragOutside) forControlEvents:UIControlEventTouchDragExit|UIControlEventTouchCancel];
    [self addTarget:self action:@selector(_didDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

#pragma mark - View Displaying -

- (void)layoutSubviews {
    [super layoutSubviews];

    // Configure the button text
    [self.titleLabel sizeToFit];
    self.titleLabel.center = self.containerView.center;
    self.titleLabel.frame = CGRectIntegral(self.titleLabel.frame);
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    self.titleLabel.backgroundColor = self.labelBackgroundColor;
    self.backgroundView.backgroundColor = self.tintColor;
    [self setNeedsLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsLayout];
    [self _updateTappedTintColorForTintColor];
}

- (void)_updateTappedTintColorForTintColor TOROUNDEDBUTTON_OBJC_DIRECT {
    if (TO_ROUNDED_BUTTON_FLOAT_IS_ZERO(_tappedTintColorBrightnessOffset)) {
        return;
    }

    UIColor *tintColor = self.tintColor;
    if (@available(iOS 13.0, *)) {
        tintColor = [tintColor resolvedColorWithTraitCollection:self.traitCollection];
    }

    _tappedTintColor = [self _brightnessAdjustedColorWithColor:tintColor
                                     amount:_tappedTintColorBrightnessOffset];
}

- (UIColor *)labelBackgroundColor {
    // Always return clear if tapped
    if (self.isTapped) { return [UIColor clearColor]; }

    // Return clear if the tint color isn't opaque
    BOOL isClear = CGColorGetAlpha(self.tintColor.CGColor) < (1.0f - FLT_EPSILON);
    return isClear ? [UIColor clearColor] : self.tintColor;
}

#pragma mark - Interaction -

- (void)_didTouchDownInside {
    self.isTapped = YES;
    
    // The user touched their finger down into the button bounds
    [self _setLabelAlphaTappedAnimated:NO];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

- (void)_didTouchUpInside
{
    self.isTapped = NO;
    
    // The user lifted their finger up from inside the button bounds
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];

    // Send the semantic button action for apps relying on this action
    [self sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];

    // Trigger the block if it has been set
    if (self.tappedHandler) { self.tappedHandler(); }
}

- (void)_didDragOutside
{
    self.isTapped = NO;
    
    // After tapping down, without releasing, the user dragged their finger outside the bounds
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

- (void)_didDragInside
{
    self.isTapped = YES;
    
    // After dragging out, without releasing, they dragged back in
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

#pragma mark - Animation -

- (void)_setBackgroundColorTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (!self.tappedTintColor) { return; }

    // Toggle the background color of the title label
    void (^updateTitleOpacity)(void) = ^{
        self.titleLabel.backgroundColor = self.labelBackgroundColor;
    };
    
    // -----------------------------------------------------
    
    void (^animationBlock)(void) = ^{
        self.backgroundView.backgroundColor = self.isTapped ? self.tappedTintColor : self.tintColor;
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL completed){
        if (completed == NO) { return; }
        updateTitleOpacity();
    };

    if (!animated) {
        animationBlock();
        completionBlock(YES);
    }
    else {
        self.titleLabel.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:self.tapAnimationDuration
                              delay:0.0f
             usingSpringWithDamping:1.0f
              initialSpringVelocity:0.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:completionBlock];
    }

}

- (void)_setLabelAlphaTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (self.tappedTextAlpha > 1.0f - FLT_EPSILON) { return; }

    CGFloat alpha = self.isTapped ? self.tappedTextAlpha : 1.0f;

    // Animate the alpha value of the label
    void (^animationBlock)(void) = ^{
        self.titleLabel.alpha = alpha;
    };

    // If we're not animating, just call the blocks manually
    if (!animated) {
        // Remove any animations in progress
        [self.titleLabel.layer removeAnimationForKey:@"opacity"];
        animationBlock();
        return;
    }

    // Set the title label to clear beforehand
    self.titleLabel.backgroundColor = [UIColor clearColor];

    // Animate the button alpha
    [UIView animateWithDuration:self.tapAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

- (void)_setButtonScaledTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (self.tappedButtonScale < FLT_EPSILON) { return; }

    CGFloat scale = self.isTapped ? self.tappedButtonScale : 1.0f;

    // Animate the alpha value of the label
    void (^animationBlock)(void) = ^{
        self.containerView.transform = CGAffineTransformScale(CGAffineTransformIdentity,
                                                              scale,
                                                              scale);
    };

    // If we're not animating, just call the blocks manually
    if (!animated) {
        animationBlock();
        return;
    }

    // Animate the button alpha
    [UIView animateWithDuration:self.tapAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

#pragma mark - Public Accessors -

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.titleLabel.attributedText = attributedText;
    [self.titleLabel sizeToFit];
    [self setNeedsLayout];
}

- (NSAttributedString *)attributedText { return self.titleLabel.attributedText; }

- (void)setText:(NSString *)text {
    self.titleLabel.text = text;
    [self.titleLabel sizeToFit];
    [self setNeedsLayout];
}

- (NSString *)text { return self.titleLabel.text; }

- (void)setTextFont:(UIFont *)textFont
{
    self.titleLabel.font = textFont;
    self.textPointSize = 0.0f; // Reset the IB text point size back to disabled
}
- (UIFont *)textFont { return self.titleLabel.font; }

- (void)setTextColor:(UIColor *)textColor {
    self.titleLabel.textColor = textColor;
}
- (UIColor *)textColor { return self.titleLabel.textColor; }

- (void)setTextPointSize:(CGFloat)textPointSize {
    if (_textPointSize == textPointSize) { return; }
    _textPointSize = textPointSize;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:textPointSize];
    [self setNeedsLayout];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    [self _updateTappedTintColorForTintColor];
    self.backgroundView.backgroundColor = tintColor;
    self.titleLabel.backgroundColor = self.labelBackgroundColor;
    [self setNeedsLayout];
}

- (void)setTappedTintColor:(UIColor *)tappedTintColor {
    if (_tappedTintColor == tappedTintColor) { return; }
    _tappedTintColor = tappedTintColor;
    _tappedTintColorBrightnessOffset = 0.0f;
    [self setNeedsLayout];
}

- (void)setTappedTintColorBrightnessOffset:(CGFloat)tappedTintColorBrightnessOffset {
    if (TO_ROUNDED_BUTTON_FLOATS_MATCH(_tappedTintColorBrightnessOffset,
                                       tappedTintColorBrightnessOffset))
    {
        return;
    }
    
    _tappedTintColorBrightnessOffset = tappedTintColorBrightnessOffset;
    [self _updateTappedTintColorForTintColor];
    [self setNeedsLayout];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    // Make sure the corner radius doesn't match
    if (fabs(cornerRadius - _cornerRadius) < FLT_EPSILON) {
        return;
    }
    
    _cornerRadius = cornerRadius;
    self.backgroundView.layer.cornerRadius = _cornerRadius;
    [self setNeedsLayout];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.containerView.alpha = enabled ? 1 : 0.4;
}

- (CGFloat)minimumWidth {
    return self.titleLabel.frame.size.width;
}

#pragma mark - Graphics Handling -

- (UIColor *)_brightnessAdjustedColorWithColor:(UIColor *)color amount:(CGFloat)amount TOROUNDEDBUTTON_OBJC_DIRECT {
    if (!color) { return nil; }
    
    CGFloat h, s, b, a;
    if (![color getHue:&h saturation:&s brightness:&b alpha:&a]) { return nil; }
    b += amount; // Add the adjust amount
    b = MAX(b, 0.0f); b = MIN(b, 1.0f);
    return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
}

@end
