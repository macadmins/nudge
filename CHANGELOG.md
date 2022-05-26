## v1.0.0.03242021182514
Initial version of Nudge

## v1.1.0
- Nudge.app is now signed and notarized. The package has been signed, notarized and stapled.
- Updated to SwiftUI 5.5
- Developer ID is now `9GQZ7KUFR6`
- `targetedOSVersions` has been deprecated and replaced by `targetedOSVersionsRule`
- Added `allowUserQuitDeferrals`
- Added `actionButtonPath`
- Added `showDeferralCount`
- Added `customDeferralButtonText`
- Added `oneDayDeferralButtonText`
- Added `oneHourDeferralButtonText`
- Added `acceptableApplicationBundleIDs`
- Added `aggressiveUserExperience`
- Added `hideDeferralCount`
- Add Swedish localization
- Allow softwareupdate downloading on 11.4 and higher
- Create a nudge demo scheme
- update project compatibility to xcode 12 and higher
- Various French localization fixes Changes done: - in French we don't capitalize first letter of ervery words in a title - all punctuation with two parts (:;?!) require an insecable space before - using better words when appropriate - keeping homogenous translation for the word device accros the labels and buttons
- add new features to simplemode
- add actionButtonPath feature
- Show negative days remaining with red, bold color

## v1.1.1
- Pull Requests now build the application and save it to the job, allowing for easier testing for contributors outside of the `macadmin` organization. Build script exits out earlier to account for this new behavior.
- `primaryQuitButton`, `AdditionalInfoButton`, `companyLogo` and `informationButton` have all been moved to their own swift files, allowing for de-duplication of repeated code and proper previews.
- All UI swift files that are used both in standard and simple mode are in a new `Common` folder in the project
- A new Xcode scheme for `Debug -demo-mode` to allow testing directly within Xcode
- Most of the user interface `frame` calls have been re-factored, fixing the UI discrepancies between Big Sur and Monterey.
- `(?)` button and `DeferView` have been re-designed to make them more consistent and fully support Monterey changes.
- Moved more variables to `ObservableObject`, fixing the Xcode full debugging UI mode issues where one of the views would not update the other view when clicking on any of the quit buttons
- Moved `ObservableObject` to `main` and passed it down to `ContentView`
- Nudge now technically supports any arbitrary width/height, but is still forced into a 900x450 pixel height. This is because "full screen mode" is still disabled.
- Jamf JSON is now considered v2. It works around some of the UI issues present in jamf admin UI, preventing accidental management of non-required keys with "blank" string values.

Many many thanks to @bartreardon for most of the refactoring and fixes that come with v1.1.1

# v1.1.2
- Updated the Github Actions code to better protect the signing cert and allow PR testing from outside contributors
  - New PRs from forks will require the use of the `safe to test` label to kick off signed test application builds.
- Removed redundant GitHub Actions for PRs
- Added Chinese (Simplified), Japanese, Korean and Portuguese localizations
-  Improved German localization
- Many improvements to the README which were ultimately moved to the [Wiki](https://github.com/macadmins/nudge/wiki)
  - This allows anyone access to update the core documentation without a pull request
-   Bump version to 1.1.2
- Moves to Xcode 13.1 RC to use the updated macOS Swift SDK

## v1.1.3
Bug Fixes:
- https://github.com/macadmins/nudge/issues/257
- https://github.com/macadmins/nudge/issues/273
- https://github.com/macadmins/nudge/issues/278
- https://github.com/macadmins/nudge/issues/279
- https://github.com/macadmins/nudge/issues/281
- https://github.com/macadmins/nudge/issues/286

Feature Requests / Enhancements:
- https://github.com/macadmins/nudge/issues/285

## v1.1.4
- Workaround Apple bug introduced in macOS 11.6 for updates that also have other pending updates https://github.com/macadmins/nudge/issues/291
  - Nudge will no longer download all available macOS updates and instead only download the required security update for the nudge event.
  - Added this workaround to macOS 11.3 and lower https://github.com/macadmins/nudge/commit/322bc558a1a089a1a982acae1499b8ae6415eec7
  - See https://openradar.appspot.com/radar?id=4987491098558464 for more information on the original bug for Big Sur 11.0 -> 11.3 and 11.6 and higher
- Fix Japanese localization https://github.com/macadmins/nudge/pull/295
- Fix typo with `asynchronousSoftwareUpdate` key https://github.com/macadmins/nudge/commit/55cc93bb16ce330706345e3b87659418014fddab
  - To support previous versions of Nudge and 1.1.4, if you are deploying this key with a value of `True` it is recommended to deploy the new key and the key with the typo until 1.1.4 is fully deployed to your organization
- Nudge is now built with Xcode 13.2.1 and has a new sub build version scheme https://github.com/macadmins/nudge/commit/94f03624e2227d43c0611679aa4c565b80b2bf66
  - GitHub Actions now pulls the entire repository to allow new sub build version scheme to accurately increase it's value

## v1.1.5
- Add Russian localization
- Add new `disableSoftwareUpdateWorkflow` key

When disableSoftwareUpdateWorkflow is true, nudge will not attempt to run
the softwareupdate process. Defaults to false.

This option is useful in cases where running `softwareupdate` causes other
issues for OS updates, or if the organization is already using a different
methods to start the download of an update.

## v1.1.6
- Localizations
  - Italian
  - Norwegian
  - Additional localization fixes
- Accessibility improvements for color blind users and users with high contract
- `actionButtonPath` can now be put under a `osVersionRequirements` array, allowing multiple button actions for major
- new `allowGracePeriods` functionality/key allowing Nudge to not appear during initial provisioning of out-of-date devices
  - `gracePeriodPath` specifies the file to look for for the initial provisioning time
    - defaults to `/private/var/db/.AppleSetupDone`
  - `gracePeriodInstallDelay` The amount of hours to allow a new out-of-date machine to install the required update
    - defaults to `23`
   - `gracePeriodLaunchDelay` The amount of hours to delay launching Nudge, circumventing the LaunchAgent for new machines
    - defaults to `1`
    - Unit tests for gracePeriods
- Set "sign locally" for Nudge project, allowing people without the developer certs to easily test nudge builds via Xcode
- Turn off parts of code hardening on debug projects, allowing unit tests to work

## v1.1.7
- New Nudge "Suite" package that included Logger, LaunchAgent and Nudge.app
- New blurring feature when the user is passed the required installation date.
  - Many many thanks to @bartreardon for this feature!
- New Changlog in GitHub Actions
- Improved Norwegian localization
- New Danish localization
- Improved Dutch localization
- Added basic localizations for new Notification Center UX
- Fixes the bug around people moving Nudge to a different desktop space and bypassing nudge event
- CMD+N and CMD+M are now banned if Nudge is the primary window on a macOS device
- New `-bundle-mode` argument to launch Nudge with a built-in json. Not for use in production.
- New `-print-profile-config` argument to print out the current profile preferences applied to nudge. Nudge will not run when passing this argument.
- New `-print-json-config` argument to print out the current json preferences applied to nudge. Nudge will not run when passing this argument.
- Fixes to non-Gregorian calendars and custom deferrals
- Nudge no longer exits 0 when there are issues it detects
- Refactored all log logic to reduce lines of code

### New keys and features:
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
---
- `attemptToBlockApplicationLaunches`
  - When enabled, Nudge will attempt to block application launches after the required installation date. This key must be used in conjunction with `blockedApplicationBundleIDs`.
- `blockedApplicationBundleIDs`
  - The application Bundle ID which Nudge disallows from lauching after the required installation date. You can specify one or more Bundle ID.
- `terminateApplicationsOnLaunch`
  - When enabled, Nudge will terminate the applications listed in blockedApplicationBundleIDs upon initial launch.

Please note that with these three options, the user will be notified through Notification Center, but only if they approve the dialog. It is recommended to deploy an MDM profile for this to force user notifications, otherwise Nudge will ask the user upon the next launch to allow notifications.
