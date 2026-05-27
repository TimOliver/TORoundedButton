//
//  TORoundedButtonExampleTests.m
//  TORoundedButtonExampleTests
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TORoundedButton.h"

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

@end
