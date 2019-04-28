//
//  TORoundedButton.m
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TORoundedButton.h"

@interface TORoundedButton ()

/** Marked whenever the graphical components of the button need to be recalculated */
@property (nonatomic, assign) BOOL isDirty;

/** A container view that holds all of the content view and performs the clipping */
@property (nonatomic, strong) UIView *containerView;

/** The title label displaying the text in the center of the button */
@property (nonatomic, strong) UILabel *titleLabel;

/** An image view that displays the rounded box behind the button text */
@property (nonatomic, strong) UIImageView *backgroundImageView;

/** The dynamically generated rounded box image that is applied to the image view */
@property (nonatomic, strong, nullable) UIImage *backgroundImage;

/** A resizable image that optionally shows when the button is tapped */
@property (nonatomic, strong, nullable) UIImage *tappedBackgroundImage;

/** Because this view is always clear, intercept and store the intended background color */
@property (nonatomic, strong, nullable) UIColor *buttonBackgroundColor;

@end

@implementation TORoundedButton

#pragma mark - View Creation -

- (instancetype)initWithText:(NSString *)text
{
    if (self = [super initWithFrame:(CGRect){0,0, 288.0f, 50.0f}]) {
        [self roundedButtonCommonInit];
        _titleLabel.text = text;
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self roundedButtonCommonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self roundedButtonCommonInit];
    }

    return self;
}

- (void)roundedButtonCommonInit
{
    // Default properties (Make sure they're not overriding IB)
    _cornerRadius = (_cornerRadius > FLT_EPSILON) ?: 10.0f;
    _tappedTextAlpha = (_tappedTextAlpha > FLT_EPSILON) ?: 0.5f;
    _tapAnimationDuration = (_tapAnimationDuration > FLT_EPSILON) ?: 0.4f;
    _isDirty = YES;
    self.opaque = YES;

    if (!_buttonBackgroundColor) { _buttonBackgroundColor = [UIColor whiteColor]; }
    super.backgroundColor = [UIColor clearColor];

    // Create sub views
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.containerView.userInteractionEnabled = NO;
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];

    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView.clipsToBounds = YES;
    [self.containerView addSubview:self.backgroundImageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
    self.titleLabel.backgroundColor = self.tintColor;
    self.titleLabel.text = @"Button";
    [self.containerView addSubview:self.titleLabel];

    [self addTarget:self action:@selector(didTouchDownInside) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(didTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(didDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [self addTarget:self action:@selector(didDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

#pragma mark - View Displaying -

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.isDirty) {
        [self prepareViewsForDisplay];
        self.isDirty = NO;
    }

    [self.titleLabel sizeToFit];
    self.titleLabel.center = self.containerView.center;
    self.titleLabel.frame = CGRectIntegral(self.titleLabel.frame);
}

- (void)prepareViewsForDisplay
{
    if (self.opaque) {
        [self prepareForOpaqueDisplay];
    }
    else {
        [self prepareForTransparentDisplay];
    }
}

- (void)prepareForOpaqueDisplay
{
    // Generate any images we need
    self.backgroundImage = [[self class] buttonImageWithBackgroundColor:self.buttonBackgroundColor
                                                        foregroundColor:self.tintColor
                                                           cornerRadius:self.cornerRadius];

    if (self.tappedTintColor) {
        self.tappedBackgroundImage = [[self class] buttonImageWithBackgroundColor:self.buttonBackgroundColor
                                                                  foregroundColor:self.tappedTintColor
                                                                     cornerRadius:self.cornerRadius];
    }

    // Configure the background image view for opaque drawing
    self.backgroundImageView.image = self.backgroundImage;
    self.backgroundImageView.backgroundColor = nil;

    // Reset ourselves from potential clipping
    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.cornerRadius = 0.0f;
}

- (void)prepareForTransparentDisplay
{
    // Clear out any opaque graphics
    self.backgroundImage = nil;
    self.tappedBackgroundImage = nil;

    // Configure the background image view for transparent drawing
    self.backgroundImageView.backgroundColor = self.tintColor;

    // Configure ourselves for clipping the views
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.cornerRadius = self.cornerRadius;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.isDirty = YES;
    [self setNeedsLayout];
}

#pragma mark - Interaction -

- (void)didTouchDownInside
{
    [self setLabelAlphaTapped:YES animated:NO];
    [self setBackgroundColorTapped:YES animated:NO];
    [self setButtonScaledTapped:YES animated:NO];
}

- (void)didTouchUpInside
{
    [self setLabelAlphaTapped:NO animated:YES];
    [self setBackgroundColorTapped:NO animated:YES];
    [self setButtonScaledTapped:NO animated:YES];

    if (self.tappedHandler) { self.tappedHandler(); }
}

- (void)didDragOutside
{
    [self setLabelAlphaTapped:NO animated:YES];
    [self setBackgroundColorTapped:NO animated:YES];
    [self setButtonScaledTapped:NO animated:YES];
}

- (void)didDragInside
{
    [self setLabelAlphaTapped:YES animated:YES];
    [self setBackgroundColorTapped:YES animated:YES];
    [self setButtonScaledTapped:YES animated:YES];
}

#pragma mark - Animation -

- (void)setBackgroundColorTapped:(BOOL)tapped animated:(BOOL)animated
{
    if (!self.tappedTintColor) { return; }

    // For transparent buttons, just animate the tint color
    if (!self.opaque) {
        void (^animationBlock)(void) = ^{
            self.backgroundImageView.backgroundColor = tapped ? self.tappedTintColor : self.tintColor;
        };

        if (!animated) {
            animationBlock();
        }
        else {
            [UIView animateWithDuration:self.tapAnimationDuration
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:animationBlock
                             completion:nil];
        }

        return;
    }

    if (!animated) {
        self.backgroundImageView.image = tapped ? self.tappedBackgroundImage : self.backgroundImage;
        return;
    }

    // For opaque buttons, perform a Core Animation cross fade animation
    UIImage *fromImage = tapped ? self.backgroundImage : self.tappedBackgroundImage;
    UIImage *toImage = tapped ? self.tappedBackgroundImage : self.backgroundImage;

    // If we quickly move between states before the animation completes, capture the progress
    // we were at, so we can apply it as the new starting point
    id presentationContents = nil;
    CABasicAnimation *previousAnimation = [self.backgroundImageView.layer animationForKey:@"animateContents"];
    if (previousAnimation) {
        presentationContents = self.backgroundImageView.layer.presentationLayer.contents;
        [self.backgroundImageView.layer removeAnimationForKey:@"animateContents"];
    }

    // Perform the crossfade animation
    CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
    crossFade.duration = self.tapAnimationDuration;
    crossFade.fromValue = presentationContents ?: (id)fromImage.CGImage;
    crossFade.toValue = (id)toImage.CGImage;
    [self.backgroundImageView.layer addAnimation:crossFade forKey:@"animateContents"];
    self.backgroundImageView.image = toImage;
}

- (void)setLabelAlphaTapped:(BOOL)tapped animated:(BOOL)animated
{
    if (self.tappedTextAlpha > 1.0f - FLT_EPSILON) { return; }

    CGFloat alpha = tapped ? self.tappedTextAlpha : 1.0f;

    // Animate the alpha value of the label
    void (^animationBlock)(void) = ^{
        self.titleLabel.alpha = alpha;
    };

    // Whenever the button is tapped, make the background color of the
    // label clear so we can potentially animate the background color
    void (^completionBlock)(BOOL) = ^(BOOL completed) {
        if (completed == NO) { return; }
        UIColor *backgroundColor = tapped ? [UIColor clearColor] : self.tintColor;
        self.titleLabel.backgroundColor = backgroundColor;
    };

    // If we're not animating, just call the blocks manually
    if (!animated) {
        animationBlock();
        completionBlock(YES);
        return;
    }

    // Set the title label to clear beforehand
    self.titleLabel.backgroundColor = [UIColor clearColor];

    // Animate the button alpha
    [UIView animateWithDuration:self.tapAnimationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:completionBlock];
}

- (void)setButtonScaledTapped:(BOOL)tapped animated:(BOOL)animated
{
    if (self.tappedButtonScale < FLT_EPSILON) { return; }

    CGFloat scale = tapped ? self.tappedButtonScale : 1.0f;

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

/** Map the text property directly to the label */
- (void)setText:(NSString *)text { self.titleLabel.text = text; }
- (NSString *)text { return self.titleLabel.text; }

/** Map the font property directly to the label */
- (void)setTextFont:(UIFont *)textFont
{
    self.titleLabel.font = textFont;
    self.textPointSize = 0.0f; // Reset the IB text point size back to disabled
}
- (UIFont *)textFont { return self.titleLabel.font; }

- (void)setTextPointSize:(CGFloat)textPointSize
{
    if (_textPointSize == textPointSize) { return; }
    _textPointSize = textPointSize;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:textPointSize];
    [self setNeedsLayout];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (backgroundColor == _buttonBackgroundColor) { return; }
    _buttonBackgroundColor = backgroundColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    self.isDirty = YES;
    [self setNeedsLayout];
}

- (BOOL)isOpaque
{
    return [[self class] isOpaqueColor:self.buttonBackgroundColor];
}

- (void)setOpaque:(BOOL)opaque
{
    [super setOpaque:[[self class] isOpaqueColor:self.buttonBackgroundColor]];
}

#pragma mark - Graphics Handling -
+ (BOOL)isOpaqueColor:(UIColor *)color
{
    // If the background color's _alpha_ is anything other than 1.0, it's not opaque. ;)
    CGFloat a = 0;
    [color getRed:NULL green:NULL blue:NULL alpha:&a];
    return a >= (1.0f - FLT_EPSILON);
}

+ (UIImage *)buttonImageWithBackgroundColor:(UIColor *)backgroundColor
                            foregroundColor:(UIColor *)foregroundColor
                               cornerRadius:(CGFloat)cornerRadius
{

    CGFloat dimensionSize = (cornerRadius * 2.0f) + 2.0f;
    CGSize size = (CGSize){dimensionSize, dimensionSize};

    UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
    format.opaque = [[self class] isOpaqueColor:backgroundColor];

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        if (format.opaque) {
            UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRect:(CGRect){CGPointZero, size}];
            [backgroundColor setFill];
            [backgroundPath fill];
        }

        //// Rectangle Drawing
        UIBezierPath *foregroundPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, size} cornerRadius:cornerRadius];
        [foregroundColor setFill];
        [foregroundPath fill];
    }];

    UIEdgeInsets insets = UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
    return [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

@end
