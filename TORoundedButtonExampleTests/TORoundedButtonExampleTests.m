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
}

@end
