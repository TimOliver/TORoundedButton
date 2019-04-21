//
//  TORoundedButton.m
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TORoundedButton.h"

@interface TORoundedButton ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation TORoundedButton

#pragma mark - View Creation -

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
    // Default properties
    _cornerRadius = 10.0f;
    self.opaque = YES;

    // Create sub views
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView.opaque = YES;
    self.backgroundImageView.clipsToBounds = YES;
    [self addSubview:self.backgroundImageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:21.0f weight:UIFontWeightBold];
    self.titleLabel.backgroundColor = self.tintColor;
    [self addSubview:self.titleLabel];

    self.titleLabel.text = @"Hello Twitch!";

    UIImage *image = [[self class] buttonImageWithBackgroundColor:self.backgroundColor foregroundColor:self.tintColor cornerRadius:self.cornerRadius];
    self.backgroundImageView.image = image;

    [self addTarget:self action:@selector(didTouchDownInside) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(didTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(didDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [self addTarget:self action:@selector(didDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

#pragma mark - View Layout -

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.titleLabel sizeToFit];
    self.titleLabel.center = self.backgroundImageView.center;
    self.titleLabel.frame = CGRectIntegral(self.titleLabel.frame);
}

#pragma mark - Interaction -

- (void)didTouchDownInside
{
    [self setLabelAlpha:0.5f animated:NO];
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
    [self setLabelAlpha:0.5f animated:YES];
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

    [UIView animateWithDuration:0.4f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock completion:nil];
}

#pragma mark - Graphics Rendering -
+ (UIImage *)buttonImageWithBackgroundColor:(UIColor *)backgroundColor
                            foregroundColor:(UIColor *)foregroundColor
                               cornerRadius:(CGFloat)cornerRadius
{

    CGFloat dimensionSize = (cornerRadius * 2.0f) + 2.0f;
    CGSize size = (CGSize){dimensionSize, dimensionSize};

    UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
    format.opaque = !([backgroundColor isEqual:[UIColor clearColor]]);

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
