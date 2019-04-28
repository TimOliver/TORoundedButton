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
    _cornerRadius = 10.0f;
    _tappedTextAlpha = 0.5f;
    _tapAnimationDuration = 0.4f;
    _isDirty = YES;
    self.opaque = YES;

    if (!_buttonBackgroundColor) { _buttonBackgroundColor = [UIColor whiteColor]; }
    super.backgroundColor = [UIColor clearColor];

    // Create sub views
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView.opaque = self.opaque;
    self.backgroundImageView.clipsToBounds = YES;
    [self addSubview:self.backgroundImageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:21.0f weight:UIFontWeightBold];
    self.titleLabel.backgroundColor = self.tintColor;
    [self addSubview:self.titleLabel];

    self.titleLabel.text = @"Button";

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
    self.titleLabel.center = self.backgroundImageView.center;
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

    // Configure the background image view for opaque drawing
    self.backgroundImageView.image = self.backgroundImage;
    self.backgroundImageView.backgroundColor = nil;

    // Reset ourselves from potential clipping
    self.layer.masksToBounds = NO;
    self.layer.cornerRadius = 0.0f;
}

- (void)prepareForTransparentDisplay
{
    // Clear out any opaque graphics
    self.backgroundImage = nil;
    self.tappedBackgroundImage = nil;

    // Configure the background image view for transparent drawing
    self.backgroundImageView.backgroundColor = self.tintColor;

    // Configure ourselves for clipping the views
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.cornerRadius;
}

#pragma mark - Interaction -

- (void)didTouchDownInside
{
    [self setLabelAlpha:self.tappedTextAlpha animated:NO];
}

- (void)didTouchUpInside
{
    [self setLabelAlpha:1.0f animated:YES];

    if (self.tappedHandler) { self.tappedHandler(); }
}

- (void)didDragOutside
{
    [self setLabelAlpha:1.0f animated:YES];
}

- (void)didDragInside
{
    [self setLabelAlpha:self.tappedTextAlpha animated:YES];
}

- (void)setLabelAlpha:(CGFloat)labelAlpha animated:(BOOL)animated
{
    if (!animated) {
        self.titleLabel.alpha = labelAlpha;
        return;
    }

    id animationBlock = ^{
        self.titleLabel.alpha = labelAlpha;
    };

    [UIView animateWithDuration:self.tapAnimationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock completion:nil];
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
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (backgroundColor == _buttonBackgroundColor) { return; }
    _buttonBackgroundColor = backgroundColor;
    _isDirty = YES;
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
