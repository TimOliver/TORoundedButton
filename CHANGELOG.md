x.y.z Release Notes (yyyy-MM-dd)
=============================================================

1.2.2 Release Notes (2025-11-21)
=============================================================

### Fixed

* An issue where no text would be visible if the class was instantiated from `initWithText:`. ([#51](https://github.com/TimOliver/TORoundedButton/pull/51))

1.2.1 Release Notes (2023-10-09)
=============================================================

### Fixed

* Tint color peridoically resets itself when translucency is enabled. ([#50](https://github.com/TimOliver/TORoundedButton/pull/50))

1.2.0 Release Notes (2023-10-08)
=============================================================

### Added

* A `delegate` property to receive tap events for the button where delegates are preferred over blocks. ([#46](https://github.com/TimOliver/TORoundedButton/pull/46))
* An `isTranslucent` property (and a `blurStyle` property) that replaces the background of buttons from a solid color to a blurred background. ([#45](https://github.com/TimOliver/TORoundedButton/pull/45))
* A `contentView` property to enable adding custom view content to buttons. ([#44](https://github.com/TimOliver/TORoundedButton/pull/44))
* `sizeToFit` and `sizeThatFits:` methods to allow automatic sizing of buttons around their content. ([#44](https://github.com/TimOliver/TORoundedButton/pull/44))

### Fixed

* Re-calculating the darker tap color when moving between light and dark mode. ([#34](https://github.com/TimOliver/TORoundedButton/pull/34))
* Changed the tap-down animation to always use a fluid zoom animation. ([#35](https://github.com/TimOliver/TORoundedButton/pull/35))
* A broken symlink reference in the SPM integration. ([#48](https://github.com/TimOliver/TORoundedButton/pull/48))

1.1.3 Release Notes (2020-12-12)
=============================================================

### Added

* Dark Mode support for iOS 13 and up. ([#34](https://github.com/TimOliver/TORoundedButton/pull/34))

### Fixed

* Refined SwiftPM support to not need to touch the main sources directory.

1.1.2 Release Notes (2019-07-07)
=============================================================

### Fixed

* An issue where the header wasn't being added to the framework. ([#23](https://github.com/TimOliver/TORoundedButton/pull/23))

1.1.1 Release Notes (2019-06-21)
=============================================================

### Enhancements

* Added unit tests to check consistent initial behaviour. ([#22](https://github.com/TimOliver/TORoundedButton/pull/22))
* Updated the documentation in the header to match expected default values. ([#22](https://github.com/TimOliver/TORoundedButton/pull/22))

### Fixed

* A bug where the dynamic text size would not properly restore. ([#22](https://github.com/TimOliver/TORoundedButton/pull/22))


1.1.0 Release Notes (2019-06-21)
=============================================================

### Enchancements

* Added `minimumWidth` property to help with guiding external layout. ([#21](https://github.com/TimOliver/TORoundedButton/pull/21))
* Refactored button from Core Animation labs chat at WWDC 2019. ([#20](https://github.com/TimOliver/TORoundedButton/pull/20))
* Increased corner radius default value to 12.0. ([#20](https://github.com/TimOliver/TORoundedButton/pull/20))
* Added lower alpha value when button is set to disabled. ([#15](https://github.com/TimOliver/TORoundedButton/pull/15))
* Added `UIControlEventPrimaryActionTriggered` event handling for iOS 9 apps relying on that action. ([#13](https://github.com/TimOliver/TORoundedButton/pull/13))
* Added attributed string support to button. ([#11](https://github.com/TimOliver/TORoundedButton/pull/11))

### Fixed

* A bug where the label's background color sometimes didn't match the button tint color. ([#14](https://github.com/TimOliver/TORoundedButton/pull/14))
* Renamed framework project name to fix IB render crash. ([#20](https://github.com/TimOliver/TORoundedButton/pull/20))

1.0.0 Release Notes (2019-04-30)
=============================================================

* Initial Release! 🎉
