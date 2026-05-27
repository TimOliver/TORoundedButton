# TORoundedButton — `minimumWidth`, label-wrap fix, and test coverage

**Date:** 2026-05-27
**Status:** Approved
**Branch:** `alert-fixes`

## Context

`TORoundedButton` is consumed by a separate alert library (`UIAlertViewController`),
which surfaced two regressions plus a desire for far stronger test coverage.

Note: `spm/TORoundedButton.m` and `spm/include/TORoundedButton.h` are **symlinks** to
`TORoundedButton/TORoundedButton.{m,h}`. There is one real source file per pair — edits
to the canonical files cover the SPM package automatically.

Tests run via `xcodebuild test` on the `TORoundedButtonTests` scheme against an iOS 26.2
simulator (iPhone 16e). `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m` is
already a member of that target.

## Goals

1. Re-introduce a `minimumWidth` property that reports the smallest width the button can
   be while fitting its content — now padding-aware.
2. Fix a visual glitch where the title label wraps to two lines even when there is enough
   horizontal room.
3. Add comprehensive unit-test coverage.

## Non-goals

- No new public sizing API beyond `minimumWidth` (e.g. no `minimumHorizontalPadding`,
  no corner-radius-aware padding). `YAGNI` — `contentInset` is the agreed padding source.
- `setTextFont:` not always calling `setNeedsLayout` is a known separate latent issue and
  is explicitly out of scope.

## Design

### 1. `minimumWidth` (readonly, padding-aware)

Re-add to the public header:

```objc
/// The smallest width this button can be while still fitting its content on a single
/// line, including the horizontal `contentInset` padding.
@property (nonatomic, readonly) CGFloat minimumWidth;
```

Implementation reuses the existing, tested `sizeThatFits:` path rather than a parallel
calculation:

```objc
- (CGFloat)minimumWidth {
    return [self sizeThatFits:CGSizeMake(<large finite width>, CGFLOAT_MAX)].width;
}
```

Behaviour:

- Returns single-line natural content width **plus** `contentInset.left + contentInset.right`.
- Tracks `text`, `attributedText`, `textFont`, `textPointSize`, and `contentInset`
  automatically.
- Works for custom `contentView`s via the same `sizeThatFits:` dispatch.

Implementation detail: pass a **large finite** width (not literal `CGFLOAT_MAX`) into the
content/label measurement to avoid Core Text overflow edge cases when `sizeThatFits:`
subtracts the horizontal padding from the incoming width.

### 2. Title-label two-line wrap fix

Root cause: `layoutSubviews` calls `[_titleLabel sizeToFit]` against the label's *current*
frame. With `numberOfLines = 0`, a stale/too-narrow starting width makes
`sizeThatFits:` wrap the text to two lines even when the button is wide enough.

Fix (surgical seed) — in `layoutSubviews`, before the existing `sizeToFit`:

```objc
if (!_titleLabel) { return; }
CGRect labelFrame = _titleLabel.frame;
labelFrame.size = contentBounds.size;   // seed with the available content room
_titleLabel.frame = labelFrame;
[_titleLabel sizeToFit];                 // now wraps only when genuinely needed
```

`contentBounds` is the inset-adjusted rect already computed at the top of `layoutSubviews`.
Seeding with the real available width means the label wraps only when the text truly does
not fit, preserving intended multi-line behaviour for genuinely narrow buttons.

Rejected alternative (B): rewrite `layoutSubviews` to drive the label frame from
`sizeThatFits:` like any other content. More principled but a larger change with higher
regression risk for a published library.

### 3. Test coverage

Expand `TORoundedButtonExampleTests/TORoundedButtonExampleTests.m` in place (already a
target member — no `.pbxproj` changes). Organise with `#pragma mark` groups:

- **Init & defaults:** all four initializers (`init`, `initWithFrame:`, `initWithText:`,
  `initWithContentView:`), default property values, iOS 26 `cornerConfiguration` vs
  `cornerRadius`.
- **Text & appearance:** `text` / `attributedText` round-trips, `textColor`, `textFont`,
  `textPointSize`, `contentInset`.
- **Sizing:** `minimumWidth` relationships and `sizeThatFits:` / `sizeToFit`.
- **Glitch regression:** put the title label in a too-narrow state, force layout at an
  adequate width, assert the label stays a single line. Must fail before the fix and pass
  after.
- **Behavior:** `tappedHandler` + delegate fire on tap, `enabled` alpha,
  `overrideContentView` swap/restore, `backgroundStyle` (solid / blur / glass).

Testing conventions:

- **Relational assertions, not hard-coded pixels.** Compare against a freshly measured
  reference `UILabel` (same font/text) so tests survive Dynamic Type and font-metric
  differences across simulators. E.g. `minimumWidth ≈ referenceLabelWidth +
  contentInset.left + contentInset.right`; `minimumWidth` grows with longer text; grows
  with larger `contentInset`.
- **Private title label access via KVC:** `UILabel *label = [button valueForKey:@"titleLabel"];`
  (KVC resolves to the `_titleLabel` ivar). Pragmatic for same-project XCTest; used only
  where introspection is required (the glitch regression test).
- Drive layout in tests with `setNeedsLayout` + `layoutIfNeeded`.

## Acceptance criteria

- `minimumWidth` returns content single-line width + horizontal `contentInset`, and the
  relational sizing tests pass.
- The glitch regression test fails on the pre-fix code and passes on the fixed code.
- All new tests pass via the CI command:
  `xcodebuild -project TORoundedButtonExample.xcodeproj -scheme TORoundedButtonTests
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' clean test`.
- CHANGELOG updated (re-added `minimumWidth`, label-wrap fix).
