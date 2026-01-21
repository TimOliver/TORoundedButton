//
//  TORoundedButton.m
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

// Objective-C direct methods - https://nshipster.com/direct/
#define TOROUNDEDBUTTON_OBJC_DIRECT __attribute__((objc_direct))

#import "TORoundedButton.h"

// --------------------------------------------------------------------

static inline BOOL TORoundedButtonFloatIsZero(CGFloat value) {
    return (value > -FLT_EPSILON) && (value < FLT_EPSILON);
}

static inline BOOL TORoundedButtonFloatsMatch(CGFloat firstValue, CGFloat secondValue) {
    return fabs(firstValue - secondValue) > FLT_EPSILON;
}

static inline BOOL TORoundedButtonIsDynamicBackground(TORoundedButtonBackgroundStyle backgroundStyle) {
    return backgroundStyle != TORoundedButtonBackgroundStyleSolid;
}

// --------------------------------------------------------------------

@implementation TORoundedButton {
    /** Hold on to a global state for whether we are tapped
     or not because the state can change before blocks complete. */
    BOOL _isTapped;

    /** A hosting container holding all of the view content that tap animations are applied to. */
    UIView *_containerView;

    /** If `text` is set, the internally managed title label to show it. */
    UILabel *_titleLabel;

    /** A background view that displays the rounded box behind the button text. */
    UIView *_backgroundView;

#ifdef __IPHONE_26_0
    /** Maintain a reference to the corner configuration in case we swap out the background view */
    UICornerConfiguration *_cornerConfiguration API_AVAILABLE(ios(26.0));
#endif
}

#pragma mark - View Creation -

- (instancetype)init {
    if (self = [self initWithFrame:(CGRect){0,0, 288.0f, 52.0f}]) { }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _contentView = [UIView new];
        [self _roundedButtonCommonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _contentView = [UIView new];
        [self _roundedButtonCommonInit];
    }

    return self;
}

- (instancetype)initWithContentView:(__kindof UIView *)contentView {
    if (self = [super initWithFrame:contentView.bounds]) {
        _contentView = contentView;
        [self _roundedButtonCommonInit];
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text {
    if (self = [super initWithFrame:(CGRect){0,0, 288.0f, 52.0f}]) {
        _contentView = [UIView new];
        [self _roundedButtonCommonInit];
        [self _makeTitleLabelIfNeeded];
        _titleLabel.text = text;
        [_titleLabel sizeToFit];
    }

    return self;
}

- (void)_roundedButtonCommonInit TOROUNDEDBUTTON_OBJC_DIRECT {
    // Default properties (Make sure they're not overriding IB)
    _tappedTextAlpha = (_tappedTextAlpha > FLT_EPSILON) ?: 1.0f;
    _tapAnimationDuration = (_tapAnimationDuration > FLT_EPSILON) ?: 0.4f;
    _tappedButtonScale = (_tappedButtonScale > FLT_EPSILON) ?: 0.97f;
    _tappedTintColorBrightnessOffset = !TORoundedButtonFloatIsZero(_tappedTintColorBrightnessOffset) ?: -0.15f;
    _contentInset = (UIEdgeInsets){15.0, 15.0, 15.0, 15.0};
    _blurStyle = UIBlurEffectStyleDark;

    // Set the corner radius depending on system version
#ifdef __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        _cornerConfiguration = [UICornerConfiguration capsuleConfiguration];
    } else {
        _cornerRadius = (_cornerRadius > FLT_EPSILON) ?: 12.0f;
    }
#else
    _cornerRadius = (_cornerRadius > FLT_EPSILON) ?: 12.0f;
#endif

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) { _blurStyle = UIBlurEffectStyleSystemThinMaterialDark; }
#endif

    // Set the corner radius depending on system version
    if (@available(iOS 26.0, *)) {
        _cornerConfiguration = [UICornerConfiguration capsuleConfiguration];
    } else {
        _cornerRadius = (_cornerRadius > FLT_EPSILON) ?: 12.0f;
    }

    // Set the tapped tint color if we've set to dynamically calculate it
    [self _updateTappedTintColorForTintColor];

    // Create the container view that holds all of the views for animations.
    _containerView = [[UIView alloc] initWithFrame:self.bounds];
    _containerView.backgroundColor = [UIColor clearColor];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _containerView.userInteractionEnabled = NO;
    [self addSubview:_containerView];

    // Create the image view which will show the button background
    _backgroundView = [self _makeBackgroundViewWithStyle:_backgroundStyle];
    [_containerView addSubview:_backgroundView];

    // The foreground content view
    [_containerView addSubview:_contentView];

    // Create action events for all possible interactions with this control
    [self addTarget:self action:@selector(_didTouchDownInside) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDownRepeat];
    [self addTarget:self action:@selector(_didTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(_didDragOutside) forControlEvents:UIControlEventTouchDragExit|UIControlEventTouchCancel];
    [self addTarget:self action:@selector(_didDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

- (void)_makeTitleLabelIfNeeded TOROUNDEDBUTTON_OBJC_DIRECT {
    if (_titleLabel) { return; }

    // Make the font bold, and opt it into Dynamic Type sizing
    UIFontMetrics *const metrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody];
    UIFont *const buttonFont = [metrics scaledFontForFont:[UIFont systemFontOfSize:17.0f weight:UIFontWeightBold]];

    // Configure the title label
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = buttonFont;
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.backgroundColor = [self _labelBackgroundColor];
    _titleLabel.text = @"Button";
    _titleLabel.numberOfLines = 0;
    [_contentView addSubview:_titleLabel];
}

- (UIView *)_makeBackgroundViewWithStyle:(TORoundedButtonBackgroundStyle)style TOROUNDEDBUTTON_OBJC_DIRECT {
    UIView *backgroundView = nil;
    if (TORoundedButtonIsDynamicBackground(style)) {
        // Create a glass or blur style based on the associated style
        UIVisualEffect *effect = nil;
        if (@available(iOS 26.0, *)) {
            if (style == TORoundedButtonBackgroundStyleGlass) {
                UIGlassEffect *const glassEffect = [UIGlassEffect effectWithStyle:_glassStyle];
                glassEffect.interactive = YES;
                glassEffect.tintColor = self.tintColor;
                effect = glassEffect;
            }
        }
        if (effect == nil) {
            UIBlurEffect *const blurEffect = [UIBlurEffect effectWithStyle:_blurStyle];
            effect = blurEffect;
        }
        backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    } else {
        backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.backgroundColor = self.tintColor;
    }
    backgroundView.frame = self.bounds;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    if (@available(iOS 26.0, *)) {
        backgroundView.cornerConfiguration = _cornerConfiguration;
    } else {
        backgroundView.clipsToBounds = TORoundedButtonIsDynamicBackground(style);
        backgroundView.layer.cornerRadius = _cornerRadius;
    }

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) { backgroundView.layer.cornerCurve = kCACornerCurveContinuous; }
#endif
    return backgroundView;
}

#pragma mark - View Layout -

- (void)layoutSubviews {
    [super layoutSubviews];

    // Determine the content view's available maximum size accounting for the insetting
    const CGSize boundsSize = self.bounds.size;
    const CGRect contentBounds = (CGRect){
        .origin.x = _contentInset.left,
        .origin.y = _contentInset.top,
        .size.width = boundsSize.width - (_contentInset.left + _contentInset.right),
        .size.height = boundsSize.height - (_contentInset.top + _contentInset.bottom),
    };

    // Let the content view shrink itself to wrap its content if needed,
    // and position it in the middle of the view.
    UIView *const contentView = _overrideContentView ?: _contentView;
    contentView.frame = ({
        CGRect frame = contentBounds;
        frame.size = [contentView sizeThatFits:contentBounds.size];
        frame.origin.x = (boundsSize.width - frame.size.width) * 0.5f;
        frame.origin.y = (boundsSize.height - frame.size.height) * 0.5f;
        CGRectIntegral(frame);
    });

    // Lay out the title label
    if (!_titleLabel) { return; }
    [_titleLabel sizeToFit];
    _titleLabel.center = (CGPoint){
        .x = CGRectGetMidX(_contentView.bounds),
        .y = CGRectGetMidY(_contentView.bounds)
    };
    _titleLabel.frame = CGRectIntegral(_titleLabel.frame);
}

- (void)sizeToFit { [super sizeToFit]; }

- (CGSize)sizeThatFits:(CGSize)size {
    const CGFloat horizontalPadding = (_contentInset.left + _contentInset.right);
    const CGFloat verticalPadding = (_contentInset.top + _contentInset.bottom);
    const CGSize contentSize = CGSizeMake(size.width - horizontalPadding, size.height - verticalPadding);
    CGSize newSize = CGSizeZero;

    // Check to see if the content view was overridden with custom class that implements its own sizing method.
    const BOOL isMethodOverridden = [_contentView methodForSelector:@selector(sizeThatFits:)] !=
                                        [UIView instanceMethodForSelector:@selector(sizeThatFits:)];
    if (isMethodOverridden) {
        newSize = [_contentView sizeThatFits:size];
    } else if (_contentView.subviews.count == 1) {
        // When there is 1 view, we can reliably scale the whole view around it.
        newSize = [_contentView.subviews.firstObject sizeThatFits:contentSize];
    } else if (_contentView.subviews.count > 1) {
        // For multiple subviews, work out the bounds of all of the views and scale the button to fit
        for (UIView *view in _contentView.subviews) {
            newSize.width = MAX(CGRectGetMaxX(view.frame), newSize.width);
            newSize.height = MAX(CGRectGetMaxY(view.frame), newSize.height);
        }
    }

    newSize.width += horizontalPadding;
    newSize.height += verticalPadding;
    return newSize;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    if (TORoundedButtonIsDynamicBackground(_backgroundStyle)) { return; }
    _titleLabel.backgroundColor = [self _labelBackgroundColor];
    _backgroundView.backgroundColor = self.tintColor;
    [self setNeedsLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsLayout];
    [self _updateTappedTintColorForTintColor];
}

- (void)_updateTappedTintColorForTintColor TOROUNDEDBUTTON_OBJC_DIRECT {
    if (TORoundedButtonFloatIsZero(_tappedTintColorBrightnessOffset)) {
        return;
    }

    UIColor *tintColor = self.tintColor;
    if (@available(iOS 13.0, *)) {
        tintColor = [tintColor resolvedColorWithTraitCollection:self.traitCollection];
    }

    _tappedTintColor = [self _brightnessAdjustedColorWithColor:tintColor
                                     amount:_tappedTintColorBrightnessOffset];
}

- (UIColor *)_labelBackgroundColor TOROUNDEDBUTTON_OBJC_DIRECT {
    // Always return clear if tapped
    if (_isTapped || TORoundedButtonIsDynamicBackground(_backgroundStyle)) { return [UIColor clearColor]; }

    // Return clear if the tint color isn't opaque
    const BOOL isClear = CGColorGetAlpha(self.tintColor.CGColor) < (1.0f - FLT_EPSILON);
    return isClear ? [UIColor clearColor] : self.tintColor;
}

#pragma mark - Interaction -

- (void)_didTouchDownInside {
    _isTapped = YES;

    // The user touched their finger down into the button bounds
    [self _setLabelAlphaTappedAnimated:NO];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

- (void)_didTouchUpInside {
    _isTapped = NO;

    // The user lifted their finger up from inside the button bounds
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];

    // Send the semantic button action for apps relying on this action
    [self sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];

    // Broadcast the tap event to all subscribed objects.
    if (_tappedHandler) { _tappedHandler(); }
    [_delegate roundedButtonDidTap:self];
}

- (void)_didDragOutside {
    _isTapped = NO;

    // After tapping down, without releasing, the user dragged their finger outside the bounds
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

- (void)_didDragInside {
    _isTapped = YES;

    // After dragging out, without releasing, they dragged back in
    [self _setLabelAlphaTappedAnimated:YES];
    [self _setBackgroundColorTappedAnimated:YES];
    [self _setButtonScaledTappedAnimated:YES];
}

#pragma mark - Animation -

- (void)_setBackgroundColorTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (!_tappedTintColor || TORoundedButtonIsDynamicBackground(_backgroundStyle)) { return; }

    // Toggle the background color of the title label
    void (^updateTitleOpacity)(void) = ^{
        self->_titleLabel.backgroundColor = [self _labelBackgroundColor];
    };
    
    // -----------------------------------------------------
    
    void (^animationBlock)(void) = ^{
        self->_backgroundView.backgroundColor = self->_isTapped ? self->_tappedTintColor : self.tintColor;
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
        _titleLabel.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:_tapAnimationDuration
                              delay:0.0f
             usingSpringWithDamping:1.0f
              initialSpringVelocity:0.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:completionBlock];
    }

}

- (void)_setLabelAlphaTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (_tappedTextAlpha > 1.0f - FLT_EPSILON) { return; }

    const CGFloat alpha = _isTapped ? _tappedTextAlpha : 1.0f;

    // Animate the alpha value of the label
    void (^animationBlock)(void) = ^{
        self->_titleLabel.alpha = alpha;
    };

    // If we're not animating, just call the blocks manually
    if (!animated) {
        // Remove any animations in progress
        [_titleLabel.layer removeAnimationForKey:@"opacity"];
        animationBlock();
        return;
    }

    // Set the title label to clear beforehand
    _titleLabel.backgroundColor = [UIColor clearColor];

    // Animate the button alpha
    [UIView animateWithDuration:_tapAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

- (void)_setButtonScaledTappedAnimated:(BOOL)animated TOROUNDEDBUTTON_OBJC_DIRECT {
    if (_tappedButtonScale < FLT_EPSILON) { return; }

    const CGFloat scale = _isTapped ? _tappedButtonScale : 1.0f;

    // Animate the alpha value of the label
    void (^animationBlock)(void) = ^{
        self->_containerView.transform = CGAffineTransformScale(CGAffineTransformIdentity,
                                                              scale,
                                                              scale);
    };

    // If we're not animating, just call the blocks manually
    if (!animated) {
        animationBlock();
        return;
    }

    // Animate the button alpha
    [UIView animateWithDuration:_tapAnimationDuration
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

#pragma mark - Public Accessors -

- (void)setContentView:(UIView *)contentView {
    if (_contentView == contentView) { return; }

    _titleLabel = nil;
    [_contentView removeFromSuperview];
    _contentView = contentView ?: [UIView new];
    [_containerView addSubview:_contentView];
    [self setNeedsLayout];
}

- (void)setOverrideContentView:(UIView *)overrideContentView {
    if (_overrideContentView == overrideContentView) { return; }
    if (_overrideContentView != nil) {
        [_overrideContentView removeFromSuperview];
    }

    _overrideContentView = overrideContentView;

    if (_overrideContentView != nil) {
        _contentView.hidden = YES;
        [_containerView addSubview:_overrideContentView];
    } else {
        _contentView.hidden = NO;
    }
    [self setNeedsLayout];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [self _makeTitleLabelIfNeeded];
    _titleLabel.attributedText = attributedText;
    [_titleLabel sizeToFit];
    [self setNeedsLayout];
}

- (NSAttributedString *)attributedText { return _titleLabel.attributedText; }

- (void)setText:(NSString *)text {
    [self _makeTitleLabelIfNeeded];
    _titleLabel.text = text;
    [_titleLabel sizeToFit];
    [self setNeedsLayout];
}

- (NSString *)text { return _titleLabel.text; }

- (void)setTextFont:(UIFont *)textFont {
    _titleLabel.font = textFont;
    self.textPointSize = 0.0f; // Reset the IB text point size back to disabled
}
- (UIFont *)textFont { return _titleLabel.font; }

- (void)setTextColor:(UIColor *)textColor {
    _titleLabel.textColor = textColor;
}
- (UIColor *)textColor { return _titleLabel.textColor; }

- (void)setTextPointSize:(CGFloat)textPointSize {
    if (_textPointSize == textPointSize) { return; }
    _textPointSize = textPointSize;
    _titleLabel.font = [UIFont boldSystemFontOfSize:textPointSize];
    [self setNeedsLayout];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    [self _updateTappedTintColorForTintColor];
    if (!TORoundedButtonIsDynamicBackground(_backgroundStyle)) {
        _backgroundView.backgroundColor = tintColor;
    }
    _titleLabel.backgroundColor = [self _labelBackgroundColor];
    [self setNeedsLayout];
}

- (void)setTappedTintColor:(UIColor *)tappedTintColor {
    if (_tappedTintColor == tappedTintColor) { return; }
    _tappedTintColor = tappedTintColor;
    _tappedTintColorBrightnessOffset = 0.0f;
    [self setNeedsLayout];
}

- (void)setTappedTintColorBrightnessOffset:(CGFloat)tappedTintColorBrightnessOffset {
    if (TORoundedButtonFloatsMatch(_tappedTintColorBrightnessOffset, 
                                       tappedTintColorBrightnessOffset)) { return; }

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

#ifdef __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        UICornerRadius *const radius = [UICornerRadius fixedRadius:_cornerRadius];
        _cornerConfiguration = [UICornerConfiguration configurationWithUniformRadius:radius];
        _backgroundView.cornerConfiguration = _cornerConfiguration;
    } else {
        _backgroundView.layer.cornerRadius = _cornerRadius;
        _backgroundView.layer.masksToBounds = TORoundedButtonIsDynamicBackground(_backgroundStyle);
    }
#else
    _backgroundView.layer.cornerRadius = _cornerRadius;
#endif
    [self setNeedsLayout];
}

#ifdef __IPHONE_26_0
- (void)setCornerConfiguration:(UICornerConfiguration *)cornerConfiguration {
    if (_cornerConfiguration == cornerConfiguration) { return; }
    _cornerConfiguration = cornerConfiguration;
    _backgroundView.cornerConfiguration = _cornerConfiguration;
}

- (UICornerConfiguration *)cornerConfiguration {
    return _cornerConfiguration;
}
#endif

- (void)setBackgroundStyle:(TORoundedButtonBackgroundStyle)backgroundStyle {
    if (_backgroundStyle == backgroundStyle) { return; }
    _backgroundStyle = backgroundStyle;
    [_backgroundView removeFromSuperview];
    _backgroundView = [self _makeBackgroundViewWithStyle:_backgroundStyle];
    _titleLabel.backgroundColor = [self _labelBackgroundColor];
    const BOOL isGlass = backgroundStyle == TORoundedButtonBackgroundStyleGlass;
    if (!isGlass) {
        _containerView.hidden = NO;
        [_containerView insertSubview:_backgroundView atIndex:0];
        [_containerView addSubview:_contentView];
    } else {
        UIVisualEffectView *glassView = (UIVisualEffectView *)_backgroundView;
        _containerView.hidden = YES;
        [self insertSubview:glassView atIndex:0];
        [glassView.contentView addSubview:_contentView];
    }
    [self setNeedsLayout];
}

- (void)setBlurStyle:(UIBlurEffectStyle)blurStyle {
    if (_blurStyle == blurStyle) {
        return;
    }

    _blurStyle = blurStyle;
    if (!TORoundedButtonIsDynamicBackground(_backgroundStyle) || ![_backgroundView isKindOfClass:[UIVisualEffectView class]]) {
        return;
    }

    UIVisualEffectView *const blurView = (UIVisualEffectView *)_backgroundView;
    [blurView setEffect:[UIBlurEffect effectWithStyle:_blurStyle]];
}

- (void)setGlassStyle:(UIGlassEffectStyle)glassStyle {
    if (_glassStyle == glassStyle) { return; }
    _glassStyle = glassStyle;

    if (!TORoundedButtonIsDynamicBackground(_backgroundStyle) || ![_backgroundView isKindOfClass:[UIVisualEffectView class]]) {
        return;
    }

    UIGlassEffect *const glassEffect = [UIGlassEffect effectWithStyle:_glassStyle];
    glassEffect.tintColor = self.tintColor;
    glassEffect.interactive = YES;

    UIVisualEffectView *const effectView = (UIVisualEffectView *)_backgroundView;
    [effectView setEffect:glassEffect];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    _containerView.alpha = enabled ? 1 : 0.4;
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
