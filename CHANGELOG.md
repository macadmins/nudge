# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.7] - 2024-08-08
Requires macOS 12.0 and higher.

### Added
- If using `utilizeSOFAFeed`, you can now set the `aboutUpdateURL` to `sofa`
  - If a URL is found in the relevant `SecurityInfo` key for the corresponding update, this value will be used.
  - If no URL is found, the aboutUpdateURL button will not be shown to the user
  - [Feature Request 629](https://github.com/macadmins/nudge/issues/629)

### Changed
- The `SMAppService` logic logs have been moved to debug logs
- When an updated Managed Preference is sent for `com.github.macadmins.Nudge`, if the values are different, [Nudge will exit](https://github.com/macadmins/nudge/commit/f13a697dd61400f7f0d73dc38226f7769ed8e4f4)
  - This is a workaround for issue [602](https://github.com/macadmins/nudge/issues/602)
  - The LaunchAgent will ensure the application is successfully restarted at a future time.

### Fixed
- The Jamf JSON schema file had an [item missing](https://github.com/macadmins/nudge/pull/632) and a [key incorrectly set](https://github.com/macadmins/nudge/pull/634)

## [2.0.6] - 2024-08-01
Requires macOS 12.0 and higher.

### Added
- Device within the `nudgeMinorUpdateEventLaunchDelay` now show current and delayed date
  - These logs also now show in the default Nudge logs when use the `logger` LaunchDaemon
  - Addresses [625](https://github.com/macadmins/nudge/issues/625)

### Changed
- Some logs have been changed from `info` to `error`, `warning` or `notice` to give admins more visibility into Nudge behaviors
- The `board-id` property has been moved to a `debug` log event
  - Works around reports like [623](https://github.com/macadmins/nudge/issues/623)

### Fixed
- The `unsupportedURL` key was not being honored when clicking on the Unsupported UI button
  - Addresses [626](https://github.com/macadmins/nudge/issues/626)
- Intel Virtual Machines now have a forced `board-id` property that complies with Apple's own logic/SOFA.
  - Thanks to [Mykola Grymalyuk](https://github.com/khronokernel) for the [PR](https://github.com/macadmins/nudge/pull/622)
  - Addresses [621](https://github.com/macadmins/nudge/issues/621)
- `requiredInstallationDisplayFormat` was no longer being honored on Nudge versions 2.0.1 through 2.0.5 due to a regression
  - Addresses [627](https://github.com/macadmins/nudge/issues/627)

## [2.0.5] - 2024-07-24
Requires macOS 12.0 and higher.

### Added
- To artificially change the `requredInstallationDate` to honor a previous macOS minor version, set `minorVersionRecalculationThreshold` under `osVersionRequirement` in amount of minor versions.
  - Ex: `minorVersionRecalculationThreshold` is set to 1 and SOFA feed has macOS 14.5 available
    - macOS device is 14.0: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.1: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.2: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.3: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.4: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.4.1: Required OS: 14.5 - Target macOS 14.5 requiredInstallationDate of 2024-06-03 00:00:00 +0000
      - This device's requiredInstallationDate is different than the others as there is no active exploit on 14.4.1
    - macOS device is 14.5: Required OS: 14.5 - Fully updated
  - Ex: `minorVersionRecalculationThreshold` is set to 2 and SOFA feed has macOS 14.5 available
    - macOS device is 14.0: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-03-21 00:00:00 +0000
    - macOS device is 14.1: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-03-21 00:00:00 +0000
    - macOS device is 14.2: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-03-21 00:00:00 +0000
    - macOS device is 14.3: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-03-21 00:00:00 +0000
    - macOS device is 14.4: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.4.1: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-06-03 00:00:00 +0000
    - macOS device is 14.5: Required OS: 14.5 - Fully updated
  - Ex: `minorVersionRecalculationThreshold` is set to 3 and SOFA feed has macOS 14.5 available
    - macOS device is 14.0: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-02-22 00:00:00 +0000
    - macOS device is 14.1: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-02-22 00:00:00 +0000
    - macOS device is 14.2: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-02-22 00:00:00 +0000
    - macOS device is 14.3: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-02-22 00:00:00 +0000
    - macOS device is 14.4: Required OS: 14.5 - Target macOS 14.4 requiredInstallationDate of 2024-04-08 00:00:00 +0000
    - macOS device is 14.4.1: Required OS: 14.5 - Target macOS 14.4.1 requiredInstallationDate of 2024-06-03 00:00:00 +0000
    - macOS device is 14.5: Required OS: 14.5 - Fully updated
  - Addresses [612](https://github.com/macadmins/nudge/issues/612)
- To ease testing, you can now pass `-simulate-date` as an argument to override the built-in date check.
  - Ex: `-simulate-date "2024-07-25T00:00:00Z"`

### Changed
- The `Actively Exploited` logic internally within Nudge and the UI on the left sidebar will show `True` if any previous updates missing on the device had active exploits.
  - **WARNING BREAKING CHANGE** - This changes the SLA computation and will result in a different `requiredInstallationDate` than offered in Nudge v2.0 -> v2.01.
  - Ex: Device is on 14.3 and needing to go to 14.5.
    - While 14.4.1 -> 14.5 are not under active exploit, 14.4 contains fixes for 14.3 that were under active exploit.
  - Addresses [610](https://github.com/macadmins/nudge/issues/610) and [613](https://github.com/macadmins/nudge/issues/613)
- When `showRequiredDate` is set to `True` and the admin is using the default values for `requiredInstallationDisplayFormat`, Nudge will attempt to understand the current locale and display the menu item appropriately.
  - Addresses [615](https://github.com/macadmins/nudge/issues/615)
- Banned shortcut keys - including the ability to quit the application - are now allowed when passing `-simulate-os-version` or `-simulate-hardware-id` or `-simulate-date`

### Fixed
- Several components in the Github Actions were triggering deprecation warnings. These have been addressed by updating to the latest version of these components
  - Addresses [616](https://github.com/macadmins/nudge/issues/616)

## [2.0.4] - 2024-07-23
Requires macOS 12.0 and higher.

### Fixed
- Logic introduced in v2.0.1 for `requiredInstallatonDate` when using the new `gracePeriodInstallDelay` was still incorrect and has been rewritten a second time.
  - Unit tests were changed to match the fixed behavior
  - `gracePeriodLogic` is now computed _after_ the SOFA feed assessment
- Logic introduced in v2.0.2 accidentally forced the `randomDelay` when using the `-demo-mode` argument. This is now removed.
- `gracePeriodsPath` objects that were 0 bytes in size were ignored. This has been modified to allow these files
  - Ex: An admin simply runs `touch` on a file.
- The JAMF JSON schema had an incorrect title value for `unsupportedURLs`
- PRs sent to the Nudge repo will now have the tag `safe-to-test` removed after every CI/CD run, regardless of pass/fail status.
- The PR build script has been fixed to re-upload zipped `Nudge.app` files for user testing

## [2.0.3] - 2024-07-22
Requires macOS 12.0 and higher.

### Changed
- The command line argument `-disable-randomDelay` is now `-disable-random-delay`
  - Unit tests do not honor the `randomDelay` key

### Fixed
- When a user clicked on the `updateDevice` button, the logs would incorrectly state the user was entering the "Unsupported UI" workflow.
- When running unit tests, Nudge no longer honors the randomDelay key or command line argument

### Added
- To ease SOFA testing, you can now pass `-custom-sofa-feed-url` as an argument to override the built-in preferences and/or custom profile/json.
  - Ex: `-custom-sofa-feed-url "file:///Users/Shared/macos_data_feed.json"`

## [2.0.2] - 2024-07-20
Requires macOS 12.0 and higher.

### Changed
- With a default of `false`, many admins do not set the `randomDelay`, resulting in an increase in SOFA queries every 30 minutes due to the default LaunchAgent. Moving forward, this will be defaulted to `true` and an organization must actively opt-out of this behavior.
  - Fixes [607](https://github.com/macadmins/nudge/issues/607)

## [2.0.1] - 2024-07-19
Requires macOS 12.0 and higher.

### Fixed
- Some incorrect logic was applied to the `requiredInstallatonDate` when using the new `gracePeriodInstallDelay`
  - https://github.com/macadmins/nudge/commit/61997a6137f1fd345a1314285cecc083f8674a15

### Added
- To ease "Unsupported UI" testing, you can now pass `-simulate-os-version` as an argument to override the built-in OS check.
  - Ex: `-simulate-os-version "14.4.1"`
- To ease "Unsupported UI" testing, you can now pass `-simulate-hardware-id` as an argument to override the built-in hardware ID check.
  - Ex: `-simulate-hardware-id "J516cAP"`

## [2.0.0] - 2024-07-18
Requires macOS 12.0 and higher.

### Breaking Changes
- **macOS 11 is now unsupported**
  - Please use Nudge 1.x releases for macOS 11
- Due to implementing markdown support, many of the elements within Nudge may no longer be in **bold** if you customize them.
  - To work around this please add `**` elements to these customizations
  - For example: The `mainContentNote` value of `Important Notes` would become `**Important Notes**`
- The SOFA feed is **opt-out**, which included the new `Unsupported UI`. If you do not want the Unsupported UI features, you will need to actively opt-out of these options.

### Changed
- Now built on Swift 5.10, Xcode 15.4 and macOS 14
- macOS 12.3 and higher uses new logic for "delta major upgrades"
  - Admins are no longer required to use supplemental keys and hacks to get Nudge to open and enforce major upgrades
- New Xcode Scheme `-bundle-mode-profile` to test profile logic
  - `-bundle-mode` has been renamed to `-bundle-mode-json`
- You can now pass two formats of **strings** to `requiredInstallationDate`
  - `2025-01-01T00:00:00Z` for UTC
  - `2025-01-01T00:00:00` for local time
  - If you are using a MDM profile and passing the original `Date` key, you must change to utilizing `String` as Apple requires ISO8601 formatted dates
- You can now pass the strings `latest`, `latest-supported` and `latest-minor` in the `requiredMinimumOSVersion` key
  - `latest`: always force latest release and if the machine can't this version, show the new "unsupported device" user interface
  - `latest-supported`: always get the latest version sofa shows that is supported by this device
  - `latest-minor`: stay in the current major release and get the latest minor updates available
  - This requires utilizing the SOFA feed features to properly work, which is opt-out by default
  - Nudge will then utilize two date integers to automatically calculate the `requiredInstallationDate`
    - `activelyExploitedCVEsMajorUpgradeSLA` under the `osVersionRequirement` key will default to 14 days
    - `activelyExploitedCVEsMinorUpdateSLA` under the `osVersionRequirement` key will default to 14 days
    - `nonActivelyExploitedCVEsMajorUpgradeSLA` under the `osVersionRequirement` key will default to 21 days
    - `nonActivelyExploitedCVEsMinorUpdateSLA` under the `osVersionRequirement` key will default to 21 days
    - `standardMajorUpgradeSLA` under the `osVersionRequirement` key will default to 28 days
    - `standardMinorUpdateSLA` under the `osVersionRequirement` key will default to 28 days
    - These dates are calculated against the `ReleaseDate` key in the SOFA feed, which is UTC formatted. Local timezones will **not be supported** with the automatic sofa feed unless you use a custom feed and change this value yourself, following ISO-8601 date formats
      - To artificially delay the SOFA nudge events, see the details below for `nudgeMajorUpgradeEventLaunchDelay` and `nudgeMinorUpdateEventLaunchDelay`
    - If you'd like to not have nudge events for releases without any known CVEs, please configure the `disableNudgeForStandardInstalls` key under `optionalFeatures` to true
- You can now disable the `Days Remaining To Update:` item on the left side of the UI.
  - Configure the `showDaysRemainingToUpdate` key under `userInterface` to false

### Fixed
- `screenshotDisplay` view had a bug that may result in the screenshot being partially cut off or zoomable
- `fallbackLanguage` would return the wrong language even when specified in the configuration
  - Fixes [582](https://github.com/macadmins/nudge/issues/582)
- The timer controller logic was utilizing hours remaining vs seconds, which resulted in the `elapsedRefreshCycle` being used at the final hour of the nudge event vs the `imminentRefreshCycle`. This has been corrected to calculate the seconds remaining.
  - Fixes [568](https://github.com/macadmins/nudge/issues/568)
- More descriptive logs when loading json/mdm profile keys
- Refactor portions of the `softwareupdate` logic to reduce potential errors
- Fixed errors when moving to Swift 5.10
- Fixed wrong `requiredInstallationDate` calculations when using [Non-Gregorian calendars](https://github.com/macadmins/nudge/issues/509)
- Fixed UI logic when requiredInstallationDate is under an hour and `allowLaterDeferralButton` is set to false
  - Issue [475](https://github.com/macadmins/nudge/issues/475)

### Added
- To artificially change the `requredInstallationDate` thereby giving your users a default grace period for all Nudge events updates, please configure the `nudgeMajorUpgradeEventLaunchDelay` and `nudgeMinorUpdateEventLaunchDelay` keys under `userExperience` in amount of days.
- A local image path can now be specified for the notification event when Nudge terminates and application
  - Please configure the `applicationTerminatedNotificationImagePath` key under `userInterface`
  - Due to limitations within Apple's API, a local path is only supported at this time
- An admin can now alter the text when Nudge terminates and application
  - Please configure the `applicationTerminatedTitleText` and `applicationTerminatedBodyText` keys under the `updateElements` key in `UserInterface` 
- Remote URLs can now be used on `iconDarkPath`, `iconLightPath`, `screenShotDarkPath` and `screenShotLightPath`
  - Please note that these files will be downloaded each time Nudge is ran and there is currently not a way to cache these objects.
  - If these files fail to download, a default company logo will be shown.
- Actively Exploited CVEs in the left sidebar
  - To disable this item, please configure the `showActivelyExploitedCVEs` key under `userInterface` to false
- An admin can now allow users to move the Nudge window with `userExperience` key `allowMovableWindow`
- To ease testing, you can now pass `-disable-randomDelay` as an argument to ignore the `randomDelay` key if it is set by a JSON or mobileconfig
- Basic SwiftUI support for Markdown text options
  - Utilizing Apple's markdown features, you can now utilize, bold, italic, underline, subscript and url links directly into any of the text fields
- [SOFA](https://github.com/macadmins/sofa) feed support
  - Set the `utilizeSOFAFeed` key `false` under `optionalFeatures` to disable this feature 
  - Nudge will by default check the feed every 24 hours and save a cache file under `~/Library/Application Support/com.github.macadmins.Nudge/sofa-macos_data_feed.json`
  - In order to change this, please configure the `refreshSOFAFeedTime` key under `optionalFeatures` in seconds
  - If you are utilizing a custom sofa feed, please configure the `customSOFAFeedURL` key under `optionalFeatures`
- "Unsupported device" UI in standard mode that utilizes the SOFA feed
  - Set the `attemptToCheckForSupportedDevice` key `false` under `optionalFeatures` to disable this feature 
  - There are new keys to set all of text fields: `actionButtonTextUnsupported`, `mainContentHeaderUnsupported`, `mainContentNoteUnsupported`, `mainContentSubHeaderUnsupported`, `mainContentTextUnsupported`, `subHeaderUnsupported` under the `updateElements` key in `UserInterface` 
  - `unsupportedURL` and `unsupportedURLs` can change the information button itself, but it will remain in the `osVersionRequirement` key with `unsupportedURLs` and `unsupportedURLs`.
  - An icon will appear as an overlay on top of the company image to further emphasize the device is no longer supported
- An admin can now show the `requiredInstallationDate` as a item on the left side of nudge.
  - To enable this, please configure the `showRequiredDate` key under `userInterface` to true
  - You can also expirement with the format of this date through the key `requiredInstallationDisplayFormat` under `userInterface`
  - Be aware that the format you desire may not look good on the UI.
- Nudge can now honor the current cycle timers when user's press the `Quit` button.
  - Set the `honorCycleTimersOnExit` key to `true` under `optionalFeatures` to enable this feature
  - [Issue 548](https://github.com/macadmins/nudge/issues/548)
- When the device is running macOS 12.3 or higher, Nudge uses the delta logic for macOS Upgrades
  - [Issue 417](https://github.com/macadmins/nudge/issues/417)
- Nudge can now bypass activations and re-activations when a macOS update is `Downloading`, `Preparing` or `Staged` for installation.
  - To disable this, please configure the `acceptableUpdatePreparingUsage` key under `optionalFeatures` to false
  - Issue [555](https://github.com/macadmins/nudge/issues/555) and [571](https://github.com/macadmins/nudge/issues/571)
- Nudge can now attempt to honor DoNotDisturb/Focus times
  - To enable this, please configure the `honorFocusModes` key in `optionalFeatures` to true
  - This is an **expiremental feature** and may not work due to significant changes that Apple has designed for detecting these events.
- Nudge now attempts to reload the preferences if the MDM profile is updated
  - Issue [370](https://github.com/macadmins/nudge/issues/370)

## [1.1.16] - 2024-03-13
This will be the **final Nudge release** for macOS 11 and potentially other versions of macOS.

A subsequent regression caused by the v1.1.14 refactor was found in v1.1.15.

There are currently no known regressions from v1.1.13.

### Changed
- Nudge no longer resets or writes the User's plist file (`~/Library/Preferences/com.github.macadmins.Nudge.plist`) when there is a broken configuration, missing configuration or Nudge is unable to download a remote configuration file.
  - This impacted the following keys: `requiredInstallationDate`, `userDeferrals`, `userQuitDeferrals`, and `userSessionDeferrals`
  - When in this state, Nudge would improperly trigger the following log event: `New Nudge event detected - resetting all deferral values`
  - Addresses https://github.com/macadmins/nudge/issues/561

### Fixed
- When using `terminateApplicationsOnLaunch`, Nudge was terminating applications listed in `blockedApplicationBundleIDs` prior to the `requiredInstallationDate`
  - Application launches post Nudge launching were not impacted, but previously launched applications were.
  - Addresses https://github.com/macadmins/nudge/issues/562

## [1.1.15] - 2024-03-07
This will be the **final Nudge release** for macOS 11 and potentially other versions of macOS.

Due to several bugs found in the v1.1.14 release, including many subsequent v1.1.14.x builds, this release is being created to address them.

There are currently no known regressions from v1.1.13.

### Added
- `Essentials` Package
  - This signed and notarized package contains the Nudge application and LaunchAgent
- Additional shortcut keys to ignore list when Nudge is in the forefront
- `Security.md` file added for pentesters to send potential security issues within the project

### Changed
- macOS upgrade logic now uses `/System/Library/CoreServices/Software Update.app` as the default path for unknown installer versions
- The LaunchAgent and Logger packages are now signed and notarized
- The Zsh package scripts are now embedded into the Nudge application
  - Please note that if you install the LaunchAgent or Logger packages, you will need to install them **after** the Nudge application package. Failure to do this will result in the `postinstall` scripts not triggering.
- The `postinstall` script is now in Bash, but calls Zsh without global/user environment variables
- Moved the `preinstall` script logic to `postinstall`
  - This materially changes the Nudge application package and the Suite package

### Fixed
- All known regressions in v1.1.14
- Some ignored shortcut keys were improperly designed and not working
- `userSessionDeferrals` were not being accurately calculated
- When using `calendarDeferralUnit`, the upper bounds of the calendar may return a negative integer, causing Nudge to crash.
  - The behavior will now return `0`

## [1.1.14] - 2024-01-30
This will be the **final Nudge release** for macOS 11 and potentially other versions of macOS.

If there are any bugs present in the v1.1.14 branch, subsequent v1.1.14.x builds may be created to address them for legacy macOS versions.

### Added
- `screenShotAltText` key to customize the accessible hover over on screen shots

### Changed
- GitHub Actions now use Xcode 15.2 for building/signing/notarizing Nudge
- All code has been rewritten across all 29 Swift/SwiftUI files and Test files
 - Many small code paths have had increased safety added to them
- Slight changes to the unit tests based on new methods created

### Fixed
- Swift 5.9 compiler warnings have now been addressed
- [Base64 screenshots now scale appopriately](https://github.com/macadmins/nudge/issues/529)

## [1.1.13] - 2023-10-05
### Fixed
- [SMAppService preventing legacy LaunchAgent from loading](https://github.com/macadmins/nudge/pull/516)

## [1.1.12] - 2023-09-25
### Added
- `calendarDeferralUnit` key to utilize the `approachingWindowTime` or `imminentWindowTime` for calendar deferrals
- Ukrainian localization
- Created an inverted nudge icon for company logo tests
- Added base64 string support directly to `iconDarkPath`, `iconLightPath`, `screenShotDarkPath`, and `screenShotLightPath`
  - Some MDMs have issues deplyoying larger mdm profiles > 1MB, so please run your pngs through https://tinypng.com/ to compress them
  - Run base64 cli and convert to a string `base64 -b 100000000 < ~Downloads/tinified/screenShotDark.png | pbcopy`
  - Added them to your management file and prefixed the base64 encoded string with `data:image/png;base64,`
  - Ensure there is no extra lines on the preferences
- [Ability to load Launchagent with new SMAppService for macOS 13 and higher](https://github.com/macadmins/nudge/pull/456)

### Changed
- Improved Github Actions build time - Nudge.app is no longer directly notarized during the build process as it was a redundant action
- Moved to generic macOS icon for logo use. Will no longer have to maintain this logo for each major macOS version
- Github runner is now macOS 13
- Xcode 15 is now required to build Nudge
- Built with Swift 5.9
- Moved back to `apple-actions/import-codesign-certs` for codesigning certs
- Moved to Xcode 15's new `String Catalog` feature for all localization
- Enhancements to localization efforts to allow SwiftUI previews to properly work
- Updated SwiftUI previews for every view to properly preview the UI changes without rendering the entire application
- Moved to new Swift/SwiftUI previews built on macros
- Updated `builtInAcceptableApplicationBundleIDs` for Big Sur, updates and Sonoma
- Renamed background blur calls to a more appropriate name
- Moved as many things as possible to `EnvironmentObject` instead of `ObservedObject` to allow objects to flow to other UI views without directly calling them as a variable.
- Renamed `viewObserved` to `appState` due to EnvironmentObject changes
- Removed ContentView.swift and move everything to Main.swift to better understand its logic
- Made a new `Defaults` swift file for common things used across every swift file
- More sorting of files and order to better read the codebase
- Ran all pngs through TinyPNG to further reduce the size of the application (approximately 15% app size reduction)
- Ran all screen shots through TinyPNG to reduce code repo (muliple megabytes of reduction)

### Fixed
- [Window size was not adhering to ContentView size due to changes in Ventura and Xcode14](https://github.com/macadmins/nudge/pull/490)
- [Fix bug where softwareupdate could download the wrong update](https://github.com/macadmins/nudge/pull/497)
- Correctly centers window as soon as any screen properties change (Number of displays, order/position of displays, nudge window moved to another screen)
- Screen shot zoom functionality was too small
- Small changes to french localization

## [1.1.11] - 2023-02-08
### Changed
- Moved to the new "Mac Admins Open Source" Developer Certificate
- Developer ID is now `T4SK8ZXCXG`

## [1.1.10] - 2022-12-29
### Added
- `allowLaterDeferralButton` key to remove the "Later" button when using deferrals
- `builtInAcceptableApplicationBundleIDs` now includes the Ventura and Monterey upgrade apps
- `CMD + Option + M` and `CMD + Option + N` are now banned hotkeys when Nudge is the primary window
- `AssociatedBundleIdentifiers` is now added to the LaunchAgent

### Changed
- Modernized the Github Action dependencies
- Xcode 14 or higher is now required to build Nudge
- Xcode 14.2 is the verison used to build Nudge through Github Actions
- Built with Swift 5.7.2
- Monterey is the default icon, decreasing the size of Nudge by 55%!
- `asynchronousSoftwareUpdate` is no longer honored when the `requiredInstallationDate` has been passed
- The default Nudge package now attempts to install to `/Applications/Utilities` to improve deployments through Intune
- The default Nudge LaunchAgent package now attempts to install to `/Library/LaunchAgents` to improve deployments through Intune
- The default Nudge Logger package now attempts to install to `/Library/LaunchDaemons` to improve deployments through Intune
- German and Danish language improvements

### Fixed
- All known Xcode 14 warnings
- Custom Deferral buttons now expand to the entire string length

## [1.1.9] - 2022-09-12
Almost all of these changes were sent by others. Thank you for continuing to support Nudge!
### Added
- Polish Language support
- Backup macOS Ventura app link

### Changed
- Xcode 13 or higher is now required to build Nudge
- Small changes to Spanish localization

### Fixed
- Crash reported when using `aggressiveUserFullScreenExperience` and screen saver or lock screen was active.
- Nudge was not able to automatically open Software Updates on macOS Ventura
- Nudge now honors default `targetedOSVersionsRule` when a machine has no available rules but default is not the last item of the `osVersionRequirement` array

## [1.1.8] - 2022-06-01
### Fixed
- Crash reported when using `aggressiveUserFullScreenExperience` and screen saver or lock screen was active.

## [1.1.7] - 2022-06-01
### Added
- Nudge "Suite" package that includes the Logger LaunchDaemon, Nudge 30 minute LaunchAgent and Nudge.app
  - The Nudge application is identical to the standard package which is signed and notarized.
  - The package is signed, notarized and stapled, similarly to the standard package.
- Changlog in GitHub Actions
- Blurring feature when the user is passed the required installation date.
  - Many many thanks to @bartreardon for this feature!
  - Blurring will dynamically enable a blur for all of the user's screens until they click on the `Update Device` button.
  - If the user adds or removes a screen during Nudge's current session, after the next re-activation event, the blur will dynamically modify to the new screen count.
- Danish localization
- Added basic localizations for new Notification Center UX
  - Help on this would be appreciated

#### Arguments
- `-bundle-mode` argument to launch Nudge with a built-in json. Not for use in production.
- `-print-profile-config` argument to print out the current profile preferences applied to nudge. Nudge will not run when passing this argument.
- `-print-json-config` argument to print out the current json preferences applied to nudge. Nudge will not run when passing this argument.

#### Keys
- `acceptableApplicationBundleIDs` 
  - The application names using assertions which Nudge allows without taking focus. You can specify one or more applications. To find the names please run `/usr/bin/pmset -g assertions` in Terminal while the application is open and running.
- `acceptableAssertionUsage`
  - When enabled, Nudge will not activate or re-activate when assertions are currently set.
- `acceptableCameraUsage`
  - When enabled, Nudge will not activate or re-activate when the camera is on.
- `acceptableScreenSharingUsage`
  - When enabled, Nudge will not activate or re-activate when screen sharing is active.
- `aggressiveUserFullScreenExperience`
  - When disabled, Nudge will not create a blurred background when the user is passed the deferral window.
  - **defaulted to on**
- `customDeferralDropdownText`
  - This allows you to custom the "Defer" button.
---
- `attemptToBlockApplicationLaunches`
  - When enabled, Nudge will attempt to block application launches after the required installation date. This key must be used in conjunction with `blockedApplicationBundleIDs`.
- `blockedApplicationBundleIDs`
  - The application Bundle ID which Nudge disallows from launching after the required installation date. You can specify one or more Bundle ID.
- `terminateApplicationsOnLaunch`
  - When enabled, Nudge will terminate the applications listed in blockedApplicationBundleIDs upon initial launch.

Please note that with these three options, the user will be notified through Notification Center, but only if they approve the dialog. It is recommended to deploy an MDM profile for this to force user notifications, otherwise Nudge will ask the user upon the next launch to allow notifications.

### Changed
- **If a full screen application is already running prior to Nudge's initial launch and the user has not passed the required installation date, Nudge will wait until the user has moved to another application or change the full screen state of the current application before triggering it's first activation. This is due to poor behavior with full screen applications.**
- CMD+N and CMD+M are now banned if Nudge is the primary window on a macOS device
- Nudge no longer exits 0 when there are issues it detects and instead exits 1
- Refactored all log logic to reduce lines of code

### Fixed
- Improved Dutch localization
- Improved Norwegian localization
- Fixes the bug around people moving Nudge to a different desktop space and bypassing nudge event
- Fixes to non-Gregorian calendars and custom deferrals

## [1.1.6] - 2022-03-15
### Added
- Italian localization
- Norwegian localization
- `allowGracePeriods` functionality/key allowing Nudge to not appear during initial provisioning of out-of-date devices
  - `gracePeriodPath` specifies the file to look for for the initial provisioning time
    - defaults to `/private/var/db/.AppleSetupDone`
  - `gracePeriodInstallDelay` The amount of hours to allow a new out-of-date machine to install the required update
    - defaults to `23`
   - `gracePeriodLaunchDelay` The amount of hours to delay launching Nudge, circumventing the LaunchAgent for new machines
    - defaults to `1`
    - Unit tests for gracePeriods

### Changed
- Accessibility improvements for color blind users and users with high contract
- Set "sign locally" for Nudge project, allowing people without the developer certs to easily test nudge builds via Xcode
- Turn off parts of code hardening on debug projects, allowing unit tests to work
- `actionButtonPath` can now be put under a `osVersionRequirements` array, allowing multiple button actions for differing nudge events
  - Example: Major upgrade opens jamf, minor update doesn't have an actionButtonPath

### Fixed
- Improved additional localizations

## [1.1.5] - 2022-02-16
### Added
- Russian localization
- `disableSoftwareUpdateWorkflow`
  - When disableSoftwareUpdateWorkflow is true, nudge will not attempt to run
the softwareupdate process. Defaults to false.
  - This option is useful in cases where running `softwareupdate` causes other
issues for OS updates, or if the organization is already using a different
methods to start the download of an update.

## [1.1.4] - 2022-01-28
### Added
- Workaround Apple bug introduced in macOS 11.6 for updates that also have other pending updates https://github.com/macadmins/nudge/issues/291
  - Nudge will no longer download all available macOS updates and instead only download the required security update for the nudge event.
  - Added this workaround to macOS 11.3 and lower https://github.com/macadmins/nudge/commit/322bc558a1a089a1a982acae1499b8ae6415eec7
  - See https://openradar.appspot.com/radar?id=4987491098558464 for more information on the original bug for Big Sur 11.0 -> 11.3 and 11.6 and higher

### Changed
- Nudge is now built with Xcode 13.2.1 and has a new sub build version scheme https://github.com/macadmins/nudge/commit/94f03624e2227d43c0611679aa4c565b80b2bf66
  - GitHub Actions now pulls the entire repository to allow new sub build version scheme to accurately increase it's value
  
### Fixed
- Japanese localization https://github.com/macadmins/nudge/pull/295
- Typo with `asynchronousSoftwareUpdate` key https://github.com/macadmins/nudge/commit/55cc93bb16ce330706345e3b87659418014fddab
  - To support previous versions of Nudge and 1.1.4, if you are deploying this key with a value of `True` it is recommended to deploy the new key and the key with the typo until 1.1.4 is fully deployed to your organization

## [1.1.3] - 2021-11-23
### Added
- https://github.com/macadmins/nudge/issues/285

### Fixed
- https://github.com/macadmins/nudge/issues/257
- https://github.com/macadmins/nudge/issues/273
- https://github.com/macadmins/nudge/issues/278
- https://github.com/macadmins/nudge/issues/279
- https://github.com/macadmins/nudge/issues/281
- https://github.com/macadmins/nudge/issues/286

## [1.1.2] - 2021-10-21
### Added
- Updated the Github Actions code to better protect the signing cert and allow PR testing from outside contributors
  - New PRs from forks will require the use of the `safe to test` label to kick off signed test application builds.
- Chinese (Simplified) localization
- Japanese localizations
- Korean localization
- Portuguese localization
### Changed
- Improved German localization
- Removed redundant GitHub Actions for PRs
- Moves to Xcode 13.1 RC to use the updated macOS Swift SDK
### Fixed
- Many improvements to the README which were ultimately moved to the [Wiki](https://github.com/macadmins/nudge/wiki)
  - This allows anyone access to update the core documentation without a pull request

## [1.1.1] - 2021-09-20
### Added
- **Nudge 1.1.1 was re-released https://github.com/macadmins/nudge/releases/tag/v1.1.1.09202021202238 to use the Xcode 13 Beta SDK, since Xcode 13 GA did not include the macOS SDK.
- Pull Requests now build the application and save it to the job, allowing for easier testing for contributors outside of the `macadmin` organization. Build script exits out earlier to account for this new behavior.
- Xcode scheme for `Debug -demo-mode` to allow testing directly within Xcode

### Changed
- `primaryQuitButton`, `AdditionalInfoButton`, `companyLogo` and `informationButton` have all been moved to their own swift files, allowing for de-duplication of repeated code and proper previews.
- All UI swift files that are used both in standard and simple mode are in a new `Common` folder in the project
- Moved `ObservableObject` to `main` and passed it down to `ContentView`
- Nudge now technically supports any arbitrary width/height, but is still forced into a 900x450 pixel height. This is because "full screen mode" is still disabled.
- Jamf JSON is now considered v2. It works around some of the UI issues present in jamf admin UI, preventing accidental management of non-required keys with "blank" string values.

### Fixed
- Most of the user interface `frame` calls have been re-factored, fixing the UI discrepancies between Big Sur and Monterey.
- `(?)` button and `DeferView` have been re-designed to make them more consistent and fully support Monterey changes.
- Moved more variables to `ObservableObject`, fixing the Xcode full debugging UI mode issues where one of the views would not update the other view when clicking on any of the quit buttons

Many many thanks to @bartreardon for most of the refactoring and fixes that come with v1.1.1

## [1.1.0] - 2021-08-26
### Added
- Nudge.app is now signed and notarized. The package has been signed, notarized and stapled.
- Swedish localization
- `allowUserQuitDeferrals`
- `actionButtonPath`
- `showDeferralCount`
- `customDeferralButtonText`
- `oneDayDeferralButtonText`
- `oneHourDeferralButtonText`
- `acceptableApplicationBundleIDs`
- `aggressiveUserExperience`
- `hideDeferralCount`
- Allow softwareupdate downloading on 11.4 and higher
- Create a nudge demo scheme
- New features to simplemode
### Changed
- Updated to SwiftUI 5.5
- Developer ID is now `9GQZ7KUFR6`
- `targetedOSVersions` has been **deprecated** and replaced by `targetedOSVersionsRule`
- update project compatibility to xcode 12 and higher
- Show negative days remaining with red, bold color
### Fixed
- Various French localization fixes Changes done: - in French we don't capitalize first letter of every words in a title - all punctuation with two parts (:;?!) require a space before - using better words when appropriate - keeping homogenous translation for the word device across the labels and buttons

## [1.0.0] - 2021-03-24
### Added
- Initial version of Nudge
