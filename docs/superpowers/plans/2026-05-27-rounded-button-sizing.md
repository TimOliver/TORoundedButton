# TORoundedButton Sizing & Test Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-add a padding-aware `minimumWidth` property, fix the title-label two-line wrap glitch, and add comprehensive unit tests.

**Architecture:** `minimumWidth` is a readonly property that delegates to the existing `sizeThatFits:` path at an unconstrained width, so it returns single-line content width + horizontal `contentInset`. The wrap glitch is fixed by seeding the title label's frame with the available content width before `sizeToFit` in `layoutSubviews`, so it wraps only when genuinely too narrow. Tests are added to the existing XCTest file and use relational assertions against a freshly-measured reference label.

**Tech Stack:** Objective-C, UIKit, XCTest, `xcodebuild`.

---

## Orientation (read once before starting)

- **One real source file.** `spm/TORoundedButton.m` and `spm/include/TORoundedButton.h` are symlinks to `TORoundedButton/TORoundedButton.m` and `TORoundedButton/TORoundedButton.h`. Edit only the `TORoundedButton/` copies.
- **Tests** live in `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m`, which is already a member of the `TORoundedButtonTests` scheme/target. Adding methods to this file needs **no** `.pbxproj` changes.
- **Private members** (`_titleLabel`, `_containerView`, `_backgroundView`) are reached from tests via KVC, e.g. `[button valueForKey:@"titleLabel"]` — KVC resolves key `titleLabel` to the `_titleLabel` ivar.
- **Run a single test:**
  ```bash
  xcodebuild test \
    -project TORoundedButtonExample.xcodeproj \
    -scheme TORoundedButtonTests \
    -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
    -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/<testMethodName>
  ```
  Output ends in `** TEST SUCCEEDED **` or `** TEST FAILED **`.
- **Run the whole suite (CI command):**
  ```bash
  xcodebuild -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
    -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' clean test
  ```
- If the `iPhone 16e` / `OS=26.2` simulator is not installed locally, run `xcrun simctl list devices available` and substitute an installed device/OS in the `-destination`.
- **Observation, not in scope:** the header comment for `init`/`initWithText:` says "50 tall" but the code uses `52`. Tests below assert the real value (`52`). Leave the comment alone.

---

## File Structure

- **Modify** `TORoundedButton/TORoundedButton.h` — declare the `minimumWidth` property.
- **Modify** `TORoundedButton/TORoundedButton.m` — implement `minimumWidth`; seed the label frame in `layoutSubviews`.
- **Modify** `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m` — add a test delegate class, a reference-label helper, and all new tests.
- **Modify** `CHANGELOG.md` — record the re-added property and the fix.

---

## Task 1: Fix the title-label two-line wrap glitch (TDD)

**Files:**
- Test: `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m`
- Modify: `TORoundedButton/TORoundedButton.m` (`layoutSubviews`, currently lines ~293-300)

- [ ] **Step 1: Add the reference-label helper and the failing regression test**

Add this helper and test inside `@implementation TORoundedButtonExampleTests` (e.g. just below the existing `testButtonInteraction`):

```objc
#pragma mark - Helpers

/// A standalone label configured like the button's private title label,
/// for measuring expected sizes without coupling tests to exact pixel values.
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

    XCTAssertEqualWithAccuracy(titleLabel.frame.size.height, singleLineHeight, 2.0,
        @"Title label wrapped to multiple lines despite adequate button width");
}
```

- [ ] **Step 2: Run the test and verify it FAILS**

Run:
```bash
xcodebuild test -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTitleLabelDoesNotWrapWhenButtonIsWideEnough
```
Expected: `** TEST FAILED **` — the label's height is ~2 lines because `layoutSubviews` calls `sizeToFit` against the width-10 frame.

- [ ] **Step 3: Apply the fix in `layoutSubviews`**

In `TORoundedButton/TORoundedButton.m`, replace:

```objc
    // Lay out the title label
    if (!_titleLabel) { return; }
    [_titleLabel sizeToFit];
```

with:

```objc
    // Lay out the title label
    if (!_titleLabel) { return; }
    // Seed the label with the available content width first; otherwise a stale,
    // too-narrow frame makes sizeToFit wrap the text onto multiple lines even
    // when there is plenty of horizontal room.
    CGRect labelFrame = _titleLabel.frame;
    labelFrame.size = contentBounds.size;
    _titleLabel.frame = labelFrame;
    [_titleLabel sizeToFit];
```

- [ ] **Step 4: Run the test and verify it PASSES**

Run the same command as Step 2.
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add TORoundedButton/TORoundedButton.m TORoundedButtonExampleTests/TORoundedButtonExampleTests.m
git commit -m "Fix title label wrapping to two lines on small frames

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Re-add the `minimumWidth` property (TDD)

**Files:**
- Test: `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m`
- Modify: `TORoundedButton/TORoundedButton.h` (after the `tappedHandler` property, ~line 135)
- Modify: `TORoundedButton/TORoundedButton.m` (after `sizeThatFits:`, ~line 331)

- [ ] **Step 1: Write the failing tests**

Add to `TORoundedButtonExampleTests.m` under a new pragma mark:

```objc
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
    // Horizontal inset went from 15+15 (30) to 40+40 (80): a 50pt increase.
    XCTAssertEqualWithAccuracy(after - before, 50.0, 1.0);
}
```

- [ ] **Step 2: Run the tests and verify they FAIL (compile error)**

Run:
```bash
xcodebuild test -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testMinimumWidthIncludesContentInset
```
Expected: build failure — `property 'minimumWidth' not found on object of type 'TORoundedButton *'`.

- [ ] **Step 3: Declare the property in the header**

In `TORoundedButton/TORoundedButton.h`, replace:

```objc
/// A callback handler triggered each time the button is tapped.
@property (nonatomic, copy) void (^tappedHandler)(void);
```

with:

```objc
/// A callback handler triggered each time the button is tapped.
@property (nonatomic, copy) void (^tappedHandler)(void);

/// The smallest width this button can be while still fitting its content on a single
/// line, including the horizontal `contentInset` padding. Useful for external layout
/// systems (such as alert controllers) sizing themselves around the button.
@property (nonatomic, readonly) CGFloat minimumWidth;
```

- [ ] **Step 4: Implement the property**

In `TORoundedButton/TORoundedButton.m`, find the end of `sizeThatFits:`:

```objc
    newSize.width += horizontalPadding;
    newSize.height += verticalPadding;
    return newSize;
}
```

and insert immediately after it:

```objc

- (CGFloat)minimumWidth {
    // Measure at a large but finite size so the content lays out on a single line
    // without tripping Core Text overflow handling (which a literal CGFLOAT_MAX can,
    // once sizeThatFits: subtracts the horizontal padding from it).
    return [self sizeThatFits:(CGSize){1.0e6, 1.0e6}].width;
}
```

- [ ] **Step 5: Run the tests and verify they PASS**

Run:
```bash
xcodebuild test -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testMinimumWidthIncludesContentInset \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testMinimumWidthGrowsWithLongerText \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testMinimumWidthGrowsWithContentInset
```
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add TORoundedButton/TORoundedButton.h TORoundedButton/TORoundedButton.m TORoundedButtonExampleTests/TORoundedButtonExampleTests.m
git commit -m "Re-add padding-aware minimumWidth property

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Characterization tests — init, defaults, text & appearance

These document existing behavior, so they should pass against current code on first run. If any fails, stop and investigate — it's a real bug.

**Files:**
- Test: `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m`

- [ ] **Step 1: Add the tests**

Add under a new pragma mark:

```objc
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
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:@"Styled"];
    button.attributedText = attributed;
    XCTAssertEqualObjects(button.attributedText.string, @"Styled");
}

- (void)testTextColorRoundTrip {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.textColor = [UIColor redColor];
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
```

- [ ] **Step 2: Run the new tests and verify they PASS**

Run:
```bash
xcodebuild test -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testInitUsesDefaultFrameSize \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testInitWithTextSetsText \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testInitWithContentViewSetsContentView \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTextRoundTrip \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testAttributedTextRoundTrip \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTextColorRoundTrip \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTextFontRoundTrip \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTextPointSizeSetsFontSize \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testContentInsetRoundTrip
```
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add TORoundedButtonExampleTests/TORoundedButtonExampleTests.m
git commit -m "Add init, default, and appearance tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Characterization tests — interaction, state & background style

**Files:**
- Test: `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m`

- [ ] **Step 1: Add a test delegate class**

At the top of the file, after the `#import` lines and before `@interface TORoundedButtonExampleTests`:

```objc
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
```

- [ ] **Step 2: Add the behavior tests**

Add under a new pragma mark in `@implementation TORoundedButtonExampleTests`:

```objc
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
    button.backgroundStyle = TORoundedButtonBackgroundStyleBlur;
    XCTAssertEqual(button.backgroundStyle, TORoundedButtonBackgroundStyleBlur);
    UIView *backgroundView = [button valueForKey:@"backgroundView"];
    XCTAssertTrue([backgroundView isKindOfClass:[UIVisualEffectView class]]);
}

- (void)testSizeToFitResizesButtonToMinimumWidth {
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:@"Test"];
    button.frame = CGRectMake(0, 0, 1000, 200);
    [button sizeToFit];
    XCTAssertEqualWithAccuracy(button.bounds.size.width, button.minimumWidth, 1.0);
    XCTAssertGreaterThan(button.bounds.size.height, 0.0);
}
```

- [ ] **Step 3: Run the new tests and verify they PASS**

Run:
```bash
xcodebuild test -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testTappedHandlerFiresOnTouchUpInside \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testDelegateReceivesTap \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testDisabledReducesContainerAlpha \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testOverrideContentViewHidesAndRestoresContentView \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testBackgroundStyleBlurUsesVisualEffectView \
  -only-testing:TORoundedButtonExampleTests/TORoundedButtonExampleTests/testSizeToFitResizesButtonToMinimumWidth
```
Expected: `** TEST SUCCEEDED **`. (If `testBackgroundStyleBlurUsesVisualEffectView` fails, inspect `_makeBackgroundViewWithStyle:` — the assertion documents the real return type; adjust the assertion to match observed behavior rather than forcing it.)

- [ ] **Step 4: Commit**

```bash
git add TORoundedButtonExampleTests/TORoundedButtonExampleTests.m
git commit -m "Add interaction, state, and background-style tests

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: Update CHANGELOG and verify the full suite

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add CHANGELOG entries**

In `CHANGELOG.md`, replace:

```
x.y.z Release Notes (yyyy-MM-dd)
=============================================================

2.0.0 Release Notes (2026-01-22)
```

with:

```
x.y.z Release Notes (yyyy-MM-dd)
=============================================================

### Added

* Re-added the `minimumWidth` property, now including the horizontal `contentInset` padding, to help external layout systems size the button around its content.

### Fixed

* An issue where the title label could wrap onto two lines after `sizeToFit` was called against an already-narrow frame.

2.0.0 Release Notes (2026-01-22)
```

- [ ] **Step 2: Run the full suite and verify it PASSES**

Run:
```bash
xcodebuild -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' clean test
```
Expected: `** TEST SUCCEEDED **` with all tests (the original 2 plus the new ones) passing.

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "Update CHANGELOG for minimumWidth and label-wrap fix

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Self-Review (completed by plan author)

**Spec coverage:**
- `minimumWidth` (readonly, contentInset-aware) → Task 2.
- Label two-line wrap fix (surgical seed in `layoutSubviews`) → Task 1.
- Comprehensive tests (init/defaults, text/appearance, sizing, glitch regression, behavior) → Tasks 1–4.
- Relational assertions + KVC private access → helper in Task 1, used throughout.
- CHANGELOG update (acceptance criterion) → Task 5.
- Out-of-scope `setTextFont:` relayout quirk → correctly omitted.

**Placeholder scan:** No TBD/TODO/"add error handling" — every code step contains complete code; the spec's `<large finite width>` stand-in is resolved to `1.0e6`.

**Type consistency:** `referenceLabelForButton:` defined once (Task 1) and reused (Tasks 2, plus inline single-line reference). `minimumWidth` declared in Task 2 Step 3 and used in Task 4's `testSizeToFitResizesButtonToMinimumWidth`. KVC keys (`titleLabel`, `containerView`, `backgroundView`) match the ivars in `TORoundedButton.m`. Test target/class path `TORoundedButtonExampleTests/TORoundedButtonExampleTests` consistent across all commands.
