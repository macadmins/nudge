//
//  UILogic.swift
//  Nudge
//
//  Created by Erik Gomez on 2/10/21.
//

import AppKit
import Foundation

// Start doing a basic check
func nudgeStartLogic() {
    if Utils().unitTestingEnabled() {
        uiLog.debug("\("App being ran in test mode", privacy: .public)")
        return
    }

    if Utils().simpleModeEnabled() {
        uiLog.debug("\("Device in simple mode", privacy: .public)")
    }

    if Utils().demoModeEnabled() {
        uiLog.debug("\("Device in demo mode", privacy: .public)")
        nudgePrimaryState.userDeferrals = 0
        nudgePrimaryState.userQuitDeferrals = 0
        return
    }

    if Utils().newNudgeEvent() {
        uiLog.notice("\("New Nudge event detected - resetting all deferral values", privacy: .public)")
        Utils().logRequiredMinimumOSVersion()
        Utils().logUserDeferrals(resetCount: true)
        Utils().logUserQuitDeferrals(resetCount: true)
        Utils().logUserSessionDeferrals(resetCount: true)
        nudgeDefaults.removeObject(forKey: "deferRunUntil")
    } else {
        if nudgePrimaryState.userDeferrals >= 0 {
            nudgePrimaryState.userDeferrals = nudgePrimaryState.userSessionDeferrals + nudgePrimaryState.userQuitDeferrals
        }
        Utils().logRequiredMinimumOSVersion()
        Utils().logUserDeferrals()
        Utils().logUserQuitDeferrals()
        Utils().logUserSessionDeferrals()
    }
    if Utils().requireDualQuitButtons() || nudgePrimaryState.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
        nudgePrimaryState.requireDualQuitButtons = true
    }
    if nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime > Utils().getCurrentDate() && !Utils().pastRequiredInstallationDate() {
        uiLog.notice("\("User has selected a deferral date (\(nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime)) that is greater than the launch date (\(Utils().getCurrentDate()))", privacy: .public)")
        Utils().exitNudge()
    }
    if Utils().fullyUpdated() {
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        // https://zacwhite.com/2020/detecting-swiftui-previews/
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        } else {
            uiLog.notice("\("Device is fully updated", privacy: .public)")
            Utils().exitNudge()
        }
    } else if enforceMinorUpdates == false && Utils().requireMajorUpgrade() == false {
        uiLog.warning("\("Device requires a minor update but enforceMinorUpdates is false", privacy: .public)")
        Utils().exitNudge()
    }
}

func userHasClickedSecondaryQuitButton() {
    uiLog.notice("\("User clicked secondaryQuitButton", privacy: .public)")
}

func userHasClickedDeferralQuitButton(deferralTime: Date) {
    uiLog.notice("\("User initiated a deferral: \(deferralTime)", privacy: .public)")
}

func needToActivateNudge() -> Bool {
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let runningApplications = NSWorkspace.shared.runningApplications

    // Center Nudge
    Utils().centerNudge()
    
    // Don't nudge if camera is on
    if nudgePrimaryState.cameraOn && acceptableCameraUsage {
        uiLog.info("\("Camera is currently on", privacy: .public)")
        return false
    }

    // Don't nudge if screen sharing
    if nudgePrimaryState.isScreenSharing && acceptableScreenSharingUsage {
        uiLog.info("\("Screen sharing is currently active", privacy: .public)")
        return false
    }

    // Don't nudge if acceptable apps are frontmostApplication
    if builtInAcceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier!)!) || customAcceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier!)!) {
        if !nudgeLogState.afterFirstLaunch && NSWorkspace.shared.isActiveSpaceFullScreen() {
            uiLog.info("\("acceptableApplication (\(frontmostApplication?.bundleIdentifier ?? "")) running in full screen and first launch", privacy: .public)")
            return false
        } else {
            uiLog.info("\("acceptableApplication (\(frontmostApplication?.bundleIdentifier ?? "")) is currently the frontmostApplication", privacy: .public)")
            return false
        }
    }
    
    // Demo Mode should activate one time and then never again
    if Utils().demoModeEnabled() {
        if !nudgeLogState.afterFirstRun {
            uiLog.info("\("Launching demo mode UI", privacy: .public)")
            nudgeLogState.afterFirstRun = true
            Utils().activateNudge()
            return true
        } else {
            return false
        }
    }

    Utils().logUserSessionDeferrals()
    Utils().logUserDeferrals()

    // If noTimers is true, just bail
    if noTimers {
        return false
    }

    let currentTime = Date().timeIntervalSince1970
    let timeDiff = Int((currentTime - nudgePrimaryState.lastRefreshTime.timeIntervalSince1970))

    // The first time the main timer controller hits we don't care
    if !nudgeLogState.afterFirstRun {
        uiLog.info("\("Initializing nudgeRefreshCycle: \(nudgeRefreshCycle)", privacy: .public)")
        nudgeLogState.afterFirstRun = true
        nudgePrimaryState.lastRefreshTime = Date()
    }

    if Utils().getTimerController() > timeDiff  {
        return false
    }
    
    nudgePrimaryState.deferralCountPastThreshhold = nudgePrimaryState.userDeferrals > allowedDeferrals
    
    if nudgePrimaryState.deferralCountPastThreshhold {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThreshhold {
            uiLog.warning("\("allowedDeferrals has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThreshhold = true
        }
    }
    
    if nudgePrimaryState.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons {
            uiLog.warning("\("allowedDeferralsUntilForcedSecondaryQuitButton has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons = true
        }
    }

    // Don't nudge if major upgrade is frontmostApplication
    if majorUpgradeAppPathExists {
        if NSURL.fileURL(withPath: majorUpgradeAppPath) == frontmostApplication?.bundleURL {
            uiLog.info("\("majorUpgradeApp is currently the frontmostApplication", privacy: .public)")
            return false
        }
    }

    if majorUpgradeBackupAppPathExists {
        if NSURL.fileURL(withPath: Utils().getBackupMajorUpgradeAppPath()) == frontmostApplication?.bundleURL {
            uiLog.info("\("majorUpgradeApp is currently the frontmostApplication", privacy: .public)")
            return false
        }
    }
    
    if frontmostApplication?.bundleIdentifier != nil {
        uiLog.info("\("\(frontmostApplication!.bundleIdentifier ?? "") is currently the frontmostApplication", privacy: .public)")
    }

    // If we get here, Nudge if not frontmostApplication
    if !NSApplication.shared.isActive {
        nudgePrimaryState.lastRefreshTime = Date()
        if (nudgePrimaryState.deferralCountPastThreshhold || Utils().pastRequiredInstallationDate()) && aggressiveUserExperience {
            // Loop through all the running applications and hide them
            for runningApplication in runningApplications {
                let appName = runningApplication.bundleIdentifier ?? ""
                let appBundle = runningApplication.bundleURL
                if builtInAcceptableApplicationBundleIDs.contains(appName) || customAcceptableApplicationBundleIDs.contains(appName) {
                    continue
                }
                if majorUpgradeAppPathExists {
                    if NSURL.fileURL(withPath: majorUpgradeAppPath) == appBundle {
                        continue
                    }
                }
                
                if appName == "com.github.macadmins.Nudge" {
                    continue
                }
                // Taken from nudge-python as there was a race condition with NSWorkspace
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001, execute: {
                    uiLog.info("\("Attempting to hide \(appName)", privacy: .public)")
                    runningApplication.hide()
                })
            }
            Utils().activateNudge()
            if !Utils().unitTestingEnabled() {
                Utils().updateDevice(userClicked: false)
            }
        } else {
            Utils().activateNudge()
        }
        return true
    }
    return false
}

// https://github.com/brackeen/calculate-widget/blob/master/Calculate/NSWindow%2BMoveToActiveSpace.swift#L64
extension NSWorkspace {
    func isActiveSpaceFullScreen() -> Bool {
        guard let winInfoArray = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? Array<[String : Any]> else {
            return false
        }
        for winInfo in winInfoArray {
            guard let windowLayer = winInfo[kCGWindowLayer as String] as? NSNumber, windowLayer == 0 else {
                continue
            }
            guard let boundsDict = winInfo[kCGWindowBounds as String] as? [String : Any], let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                continue
            }
            if bounds.size == NSScreen.main?.frame.size {
                return true
            }
        }
        return false
    }
}
