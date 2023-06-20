# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.12] - 2023-08-01
### Added
- `calendarDeferralUnit` key to utilize the `approachingWindowTime` or `imminentWindowTime` for calendar deferrals
- Ukrainian localization
- Create an inverted nudge icon for company logo tests
- Added base64 string support directly to `iconDarkPath`, `iconLightPath`, `screenShotDarkPath`, and `screenShotLightPath`
  - Some MDMs have issues deplyoying larger mdm profiles > 1MB, so please run your pngs through https://tinypng.com/ to compress them
  - Run base64 cli and convert to a string `base64 -b 100000000 < ~Downloads/tinified/screenShotDark.png | pbcopy`
  - Added them to your management file and prefixed the base64 encoded string with `data:image/png;base64,`
  - Ensure there is no extra lines on the preferences
- [Ability to load Launchagent with new SMAppService for macOS 13 and higher](https://github.com/macadmins/nudge/pull/456)

### Changed
- Improved Github Actions build time - Nudge.app is no longer directly notarized during the build process as it was a redundant action
- Move to generic macOS icon for logo use. Will no longer have to maintain this logo for each major macOS version
- Github runner is now macOS 13
- Xcode 15 is now required to build Nudge
- Built with Swift 5.9
- Moved back to `apple-actions/import-codesign-certs` for codesigning certs
- Move to Xcode 15's new `String Catalog` feature for all localization
- Enhancements to localization efforts to allow SwiftUI previews to properly work
- Update SwiftUI previews for every view to properly preview the UI changes without rendering the entire application
- Update `builtInAcceptableApplicationBundleIDs` for Big Sur, updates and Sonoma
- Rename background blur calls to a more appropriate name
- Move as many things as possible to `EnvironmentObject` instead of `ObservedObject` to allow objects to flow to other UI views without directly calling them as a variable.
- Rename `viewObserved` to `appState` due to EnvironmentObject changes
- Remove ContentView.swift and move everything to Main.swift to better understand its logic
- Make a new `Defaults` swift file for common things used across every swift file
- More sorting of files and order to better read the codebase

### Fixed
- [Window size was not adhering to ContentView size due to changes in Ventura and Xcode14](https://github.com/macadmins/nudge/pull/490)
- [Fix bug where softwareupdate could download the wrong update](https://github.com/macadmins/nudge/pull/497)
- Screen shot zoom functionality was too small

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
  - The application Bundle ID which Nudge disallows from lauching after the required installation date. You can specify one or more Bundle ID.
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
