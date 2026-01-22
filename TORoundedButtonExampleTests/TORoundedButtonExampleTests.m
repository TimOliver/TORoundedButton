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

@end
