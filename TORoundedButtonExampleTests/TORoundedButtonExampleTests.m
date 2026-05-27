//
//  TORoundedButtonExampleTests.m
//  TORoundedButtonExampleTests
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TORoundedButton.h"

@interface TORoundedButtonTestDelegate : NSObject <TORoundedButtonDelegate>
@property (nonatomic, assign) NSInteger tapCount;
@property (nonatomic, weak) TORoundedButton *lastButton;
@end

@implementation TORoundedButtonTestDelegate
- (void)roundedButtonDidTap:(TORoundedButton *)button {
    self.tapCount += 1;
    self.lastButton = button;
}
@end

@interface TORoundedButtonExampleTests : XCTestCase

@end

@implementation TORoundedButtonExampleTests

- (void)testDefaultValues
{
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    XCTAssertNotNil(button);
    XCTAssertEqual(button.text, @"Test");
    XCTAssertEqual(button.textColor, [UIColor whiteColor]);
    XCTAssertEqual(button.tappedTextAlpha, 1.0f);
    XCTAssertEqual(button.tappedTintColorBrightnessOffset, 0.25f);
    XCTAssertEqual(button.tappedButtonScale, 0.97f);

#ifdef __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        XCTAssertNotNil(button.cornerConfiguration);
    } else {
        XCTAssertEqual(button.cornerRadius, 12.0f);
    }
#else
    XCTAssertEqual(button.cornerRadius, 12.0f);
#endif
}

- (void)testButtonInteraction
{
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Long Button Name"];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Button was tapped"];
    button.tappedHandler = ^{ [expectation fulfill]; };

    // Simulate button tap
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];

    [self waitForExpectations:@[expectation] timeout:0.5f];
}

#pragma mark - Sizing

- (void)testMinimumWidthIncludesContentInset {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Hello"];
    UILabel *reference = [self referenceLabelForButton:button];
    CGFloat textWidth = [reference sizeThatFits:CGSizeMake(1.0e6, 1.0e6)].width;
    CGFloat expected = textWidth + button.contentInset.left + button.contentInset.right;
    XCTAssertEqualWithAccuracy(button.minimumWidth, expected, 1.0);
}

- (void)testMinimumWidthGrowsWithLongerText {
    TORoundedButton *shortButton = [[TORoundedButton alloc] initWithText:@"Hi"];
    TORoundedButton *longButton = [[TORoundedButton alloc] initWithText:@"A much longer button title"];
    XCTAssertGreaterThan(longButton.minimumWidth, shortButton.minimumWidth);
}

- (void)testMinimumWidthGrowsWithContentInset {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Hello"];
    CGFloat before = button.minimumWidth;
    button.contentInset = UIEdgeInsetsMake(15, 40, 15, 40);
    CGFloat after = button.minimumWidth;
    // Left+right inset delta drives the change: (40-15) + (40-15) = 50pt.
    XCTAssertEqualWithAccuracy(after - before, 50.0, 1.0);
}

#pragma mark - Helpers

/// A standalone label matching the button's private title label font and text, for
/// measuring its natural *single-line* size (this label keeps the default
/// numberOfLines == 1) without coupling tests to exact pixel values.
- (UILabel *)referenceLabelForButton:(TORoundedButton *)button {
    UILabel *titleLabel = [button valueForKey:@"titleLabel"];
    UILabel *reference = [[UILabel alloc] init];
    reference.font = titleLabel.font;
    reference.text = titleLabel.text;
    return reference;
}

/// Reads the button's private `_isTapped` flag via KVC.
- (BOOL)isTappedForButton:(TORoundedButton *)button {
    return [[button valueForKey:@"isTapped"] boolValue];
}

#pragma mark - Layout Regression

- (void)testTitleLabelDoesNotWrapWhenButtonIsWideEnough {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Reasonably Long Title"];
    button.frame = CGRectMake(0, 0, 400, 52); // easily wide enough for one line

    UILabel *titleLabel = [button valueForKey:@"titleLabel"];

    // Natural single-line height (a fresh label defaults to numberOfLines == 1).
    UILabel *reference = [self referenceLabelForButton:button];
    [reference sizeToFit];
    CGFloat singleLineHeight = reference.frame.size.height;

    // Force the buggy precondition: a too-narrow label frame before layout.
    CGRect narrow = titleLabel.frame;
    narrow.size.width = 10.0; // narrower than the longest word
    titleLabel.frame = narrow;

    [button setNeedsLayout];
    [button layoutIfNeeded];

    // ±2pt slack absorbs CGRectIntegral rounding and font-metric variation.
    XCTAssertEqualWithAccuracy(titleLabel.frame.size.height, singleLineHeight, 2.0,
        @"Title label wrapped to multiple lines despite adequate button width");
}

#pragma mark - Init & Defaults

- (void)testInitUsesDefaultFrameSize {
    TORoundedButton *button = [[TORoundedButton alloc] init];
    XCTAssertEqualWithAccuracy(button.bounds.size.width, 288.0, 0.001);
    XCTAssertEqualWithAccuracy(button.bounds.size.height, 52.0, 0.001);
}

- (void)testInitWithTextSetsText {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Confirm"];
    XCTAssertEqualObjects(button.text, @"Confirm");
}

- (void)testInitWithContentViewSetsContentView {
    UIView *custom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    TORoundedButton *button = [[TORoundedButton alloc] initWithContentView:custom];
    XCTAssertEqualObjects(button.contentView, custom);
}

#pragma mark - Text & Appearance

- (void)testTextRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] init];
    button.text = @"Hello";
    XCTAssertEqualObjects(button.text, @"Hello");
}

- (void)testAttributedTextRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] init];
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:@"Styled"
        attributes:@{ NSForegroundColorAttributeName : [UIColor blueColor] }];
    button.attributedText = attributed;

    // Both the text and the attributes we set should survive the round-trip. We check a
    // specific attribute we set rather than full-object equality, since UILabel augments
    // the string with its own default attributes (so == against the original can fail).
    XCTAssertEqualObjects(button.attributedText.string, @"Styled");
    UIColor *foreground = [button.attributedText attribute:NSForegroundColorAttributeName
                                                   atIndex:0
                                            effectiveRange:NULL];
    XCTAssertEqualObjects(foreground, [UIColor blueColor]);
}

- (void)testTextColorRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.textColor = [UIColor redColor];
    // The getter returns the stored UIColor unchanged, so -isEqual: is the right check.
    XCTAssertEqualObjects(button.textColor, [UIColor redColor]);
}

- (void)testTextFontRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    UIFont *font = [UIFont systemFontOfSize:22.0];
    button.textFont = font;
    XCTAssertEqualObjects(button.textFont, font);
}

- (void)testTextPointSizeSetsFontSize {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.textPointSize = 28.0;
    XCTAssertEqualWithAccuracy(button.textFont.pointSize, 28.0, 0.001);
}

- (void)testContentInsetRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.contentInset = UIEdgeInsetsMake(10, 20, 10, 20);
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(button.contentInset, UIEdgeInsetsMake(10, 20, 10, 20)));
}

#pragma mark - Behavior

- (void)testTappedHandlerFiresOnTouchUpInside {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    __block NSInteger count = 0;
    button.tappedHandler = ^{ count += 1; };
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqual(count, 1);
}

- (void)testDelegateReceivesTap {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    TORoundedButtonTestDelegate *delegate = [TORoundedButtonTestDelegate new];
    button.delegate = delegate;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqual(delegate.tapCount, 1);
    XCTAssertEqualObjects(delegate.lastButton, button);
}

- (void)testDisabledReducesContainerAlpha {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    UIView *container = [button valueForKey:@"containerView"];
    XCTAssertEqualWithAccuracy(container.alpha, 1.0, 0.001);
    button.enabled = NO;
    // setEnabled: hard-codes the disabled alpha to 0.4; this locks that value.
    XCTAssertEqualWithAccuracy(container.alpha, 0.4, 0.001);
    button.enabled = YES;
    XCTAssertEqualWithAccuracy(container.alpha, 1.0, 0.001);
}

- (void)testOverrideContentViewHidesAndRestoresContentView {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    UIView *override = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];

    button.overrideContentView = override;
    XCTAssertEqualObjects(button.overrideContentView, override);
    XCTAssertTrue(button.contentView.hidden);
    XCTAssertEqualObjects(override.superview, [button valueForKey:@"containerView"]);

    button.overrideContentView = nil;
    XCTAssertNil(button.overrideContentView);
    XCTAssertFalse(button.contentView.hidden);
}

- (void)testBackgroundStyleBlurUsesVisualEffectView {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    // Changing backgroundStyle rebuilds the background view synchronously, so this
    // holds even without a superview (where the view would otherwise be created lazily).
    button.backgroundStyle = TORoundedButtonBackgroundStyleBlur;
    XCTAssertEqual(button.backgroundStyle, TORoundedButtonBackgroundStyleBlur);
    UIView *backgroundView = [button valueForKey:@"backgroundView"];
    XCTAssertTrue([backgroundView isKindOfClass:[UIVisualEffectView class]]);
}

- (void)testSizeToFitResizesButtonToFitContent {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.frame = CGRectMake(0, 0, 1000, 200);
    [button sizeToFit];

    // sizeToFit should shrink the over-sized button down to its content: the label's
    // single-line width plus the horizontal contentInset. The expected width is anchored
    // to an independent reference measurement (not the button's own minimumWidth, which
    // would make this circular since both route through sizeThatFits:).
    UILabel *reference = [self referenceLabelForButton:button];
    CGFloat expectedWidth = [reference sizeThatFits:CGSizeMake(1.0e6, 1.0e6)].width
        + button.contentInset.left + button.contentInset.right;
    XCTAssertEqualWithAccuracy(button.bounds.size.width, expectedWidth, 1.0);

    // And it genuinely shrank from the over-sized starting frame in both dimensions.
    XCTAssertLessThan(button.bounds.size.width, 1000.0);
    XCTAssertLessThan(button.bounds.size.height, 200.0);
}

#pragma mark - Accessors

- (void)testContentViewRoundTripAndNilResets {
    TORoundedButton *button = [[TORoundedButton alloc] init];
    UIView *custom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
    button.contentView = custom;
    XCTAssertEqualObjects(button.contentView, custom);

    // contentView is null_resettable: setting nil restores a fresh, non-nil view.
    button.contentView = nil;
    XCTAssertNotNil(button.contentView);
    XCTAssertNotEqualObjects(button.contentView, custom);
}

- (void)testTintColorRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tintColor = [UIColor purpleColor];
    // The getter returns the explicitly-set tint color unchanged.
    XCTAssertEqualObjects(button.tintColor, [UIColor purpleColor]);
}

- (void)testTappedTintColorRoundTripResetsBrightnessOffset {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tappedTintColor = [UIColor greenColor];
    XCTAssertEqualObjects(button.tappedTintColor, [UIColor greenColor]);
    // Setting an explicit tapped tint disables the brightness-derived color.
    XCTAssertEqualWithAccuracy(button.tappedTintColorBrightnessOffset, 0.0, 0.001);
}

- (void)testTappedTintColorBrightnessOffsetRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tappedTintColorBrightnessOffset = 0.5;
    XCTAssertEqualWithAccuracy(button.tappedTintColorBrightnessOffset, 0.5, 0.001);
}

- (void)testTappedTextAlphaRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tappedTextAlpha = 0.5;
    XCTAssertEqualWithAccuracy(button.tappedTextAlpha, 0.5, 0.001);
}

- (void)testTappedButtonScaleRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tappedButtonScale = 0.8;
    XCTAssertEqualWithAccuracy(button.tappedButtonScale, 0.8, 0.001);
}

- (void)testTapAnimationDurationsRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.tapDownAnimationDuration = 0.2;
    button.tapUpAnimationDuration = 0.6;
    XCTAssertEqualWithAccuracy(button.tapDownAnimationDuration, 0.2, 0.001);
    XCTAssertEqualWithAccuracy(button.tapUpAnimationDuration, 0.6, 0.001);
}

- (void)testCornerRadiusRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.cornerRadius = 20.0;
    XCTAssertEqualWithAccuracy(button.cornerRadius, 20.0, 0.001);
#ifdef __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        // On iOS 26, setting cornerRadius also rebuilds the corner configuration.
        XCTAssertNotNil(button.cornerConfiguration);
    }
#endif
}

- (void)testImpactStyleRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.impactStyle = TORoundedButtonImpactStyleHeavy;
    XCTAssertEqual(button.impactStyle, TORoundedButtonImpactStyleHeavy);
    button.impactStyle = TORoundedButtonImpactStyleNone;
    XCTAssertEqual(button.impactStyle, TORoundedButtonImpactStyleNone);
}

- (void)testBlurStyleRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    // Switch to the blur background so the style is actually applied to the effect view.
    button.backgroundStyle = TORoundedButtonBackgroundStyleBlur;
    button.blurStyle = UIBlurEffectStyleLight;
    XCTAssertEqual(button.blurStyle, UIBlurEffectStyleLight);
}

- (void)testDelegateRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    TORoundedButtonTestDelegate *delegate = [TORoundedButtonTestDelegate new];
    button.delegate = delegate;
    XCTAssertEqualObjects(button.delegate, delegate);
}

- (void)testTappedHandlerRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    XCTAssertNil(button.tappedHandler);
    button.tappedHandler = ^{};
    XCTAssertNotNil(button.tappedHandler);
}

#ifdef __IPHONE_26_0
- (void)testCornerConfigurationRoundTrip {
    if (@available(iOS 26.0, *)) {
        TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
        UICornerConfiguration *config =
            [UICornerConfiguration configurationWithUniformRadius:[UICornerRadius fixedRadius:8.0]];
        button.cornerConfiguration = config;
        // Pointer equality: the setter stores the config directly without copying.
        XCTAssertEqualObjects(button.cornerConfiguration, config);
    }
}

- (void)testGlassStyleRoundTrip {
    if (@available(iOS 26.0, *)) {
        TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
        // Toggle away from and back to glass so the glass effect view exists and the
        // style is actually applied (the default is already glass on iOS 26).
        button.backgroundStyle = TORoundedButtonBackgroundStyleSolid;
        button.backgroundStyle = TORoundedButtonBackgroundStyleGlass;
        button.glassStyle = UIGlassEffectStyleClear;
        XCTAssertEqual(button.glassStyle, UIGlassEffectStyleClear);
    }
}
#endif

#pragma mark - Touch & Animation

- (void)testTouchSequenceTogglesTappedState {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    XCTAssertFalse([self isTappedForButton:button]);

    [button sendActionsForControlEvents:UIControlEventTouchDown];      // _didTouchDownInside
    XCTAssertTrue([self isTappedForButton:button]);

    [button sendActionsForControlEvents:UIControlEventTouchDragExit];  // _didDragOutside
    XCTAssertFalse([self isTappedForButton:button]);

    [button sendActionsForControlEvents:UIControlEventTouchDragEnter]; // _didDragInside
    XCTAssertTrue([self isTappedForButton:button]);

    [button sendActionsForControlEvents:UIControlEventTouchUpInside];  // _didTouchUpInside:event:
    XCTAssertFalse([self isTappedForButton:button]);
}

- (void)testTouchCancelResetsTappedState {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    XCTAssertTrue([self isTappedForButton:button]);
    [button sendActionsForControlEvents:UIControlEventTouchCancel];    // _didDragOutside
    XCTAssertFalse([self isTappedForButton:button]);
}

- (void)testTouchDownScalesContainerThenRestoresOnTouchUp {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    UIView *container = [button valueForKey:@"containerView"];

    [button sendActionsForControlEvents:UIControlEventTouchDown];
    // Container scales down to tappedButtonScale (default 0.97); .a is the x-scale factor.
    XCTAssertEqualWithAccuracy(container.transform.a, button.tappedButtonScale, 0.0001);

    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqualWithAccuracy(container.transform.a, 1.0, 0.0001);
}

- (void)testTouchDimsLabelWhenTappedTextAlphaSet {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    button.tappedTextAlpha = 0.4; // a value < 1 enables the alpha-dim path (1.0 disables it)
    UILabel *titleLabel = [button valueForKey:@"titleLabel"];

    [button sendActionsForControlEvents:UIControlEventTouchDown];
    XCTAssertEqualWithAccuracy(titleLabel.alpha, 0.4, 0.0001);

    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqualWithAccuracy(titleLabel.alpha, 1.0, 0.0001);
}

- (void)testTappedBackgroundColorPathForSolidStyle {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Tap"];
    button.backgroundStyle = TORoundedButtonBackgroundStyleSolid;
    button.tappedTintColor = [UIColor redColor];

    // With a tintable (solid) background and an explicit tapped tint, the tap sequence
    // exercises the background-color animation path in both directions.
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    XCTAssertTrue([self isTappedForButton:button]);
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertFalse([self isTappedForButton:button]);
}

@end
