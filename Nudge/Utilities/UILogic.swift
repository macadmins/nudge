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
    if deferRunUntil ?? lastRefreshTime > Date() {
        let msg = "User has selected a deferral date that is in the future"
        uiLog.notice("\(msg, privacy: .public)")
        Utils().exitNudge()
    }
    if Utils().fullyUpdated() {
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        // https://zacwhite.com/2020/detecting-swiftui-previews/
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        } else {
            if Utils().demoModeEnabled() {
                let msg = "Device in demo mode"
                uiLog.debug("\(msg, privacy: .public)")
                if Utils().simpleModeEnabled() {
                    let msg = "Device in simple mode"
                    uiLog.debug("\(msg, privacy: .public)")
                }
            } else {
                let msg = "Device is fully updated"
                uiLog.notice("\(msg, privacy: .public)")
                Utils().exitNudge()
            }
        }
    } else if enforceMinorUpdates == false && Utils().requireMajorUpgrade() == false {
        let msg = "Device requires a minor update but enforceMinorUpdates is false"
        uiLog.warning("\(msg, privacy: .public)")
        Utils().exitNudge()
    }
}

// These are initial variables that needToActivateNudge() will update within the timer controller
// This type of logic is not indeal and should be redesigned.
var lastRefreshTime = Utils().getInitialDate()
var afterFirstRun = false
var deferralCount = 1
var hasLoggedDeferralCountPastThreshold = false
var hasLoggedDeferralCountPastThresholdDualQuitButtons = false

func userHasClickedSecondaryQuitButton() {
    let msg = "User clicked secondaryQuitButton"
    uiLog.notice("\(msg, privacy: .public)")
}

func needToActivateNudge(deferralCountVar: Int, lastRefreshTimeVar: Date) -> Bool {
    // Center Nudge
    Utils().centerNudge()

    // If noTimers is true, just bail
    if noTimers {
        return false
    }

    let currentTime = Date().timeIntervalSince1970
    let timeDiff = Int((currentTime - lastRefreshTimeVar.timeIntervalSince1970))

    // The first time the main timer contoller hits we don't care
    if !afterFirstRun {
        let msg = "Initializing nudgeRefreshCycle"
        uiLog.info("\(msg, privacy: .public)")
        _ = afterFirstRun = true
        _ = lastRefreshTime = Date()
        return false
    }

    if Utils().getTimerController() > timeDiff  {
        return false
    }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let runningApplications = NSWorkspace.shared.runningApplications

    // Don't nudge if major upgrade is frontmostApplication
    if majorUpgradeAppPathExists {
        if NSURL.fileURL(withPath: majorUpgradeAppPath) == frontmostApplication?.bundleURL {
            let msg = "majorUpgradeApp is currently the frontmostApplication"
            uiLog.info("\(msg, privacy: .public)")
            return false
        }
    }

    // Don't nudge if acceptable apps are frontmostApplication
    if acceptableApps.contains((frontmostApplication?.bundleIdentifier!)!) {
        let msg = "acceptableApp is currently the frontmostApplication"
        uiLog.info("\(msg, privacy: .public)")
        return false
    }

    // If we get here, Nudge if not frontmostApplication
    if !NSApplication.shared.isActive {
        _ = deferralCount += 1
        _ = lastRefreshTime = Date()
        if !hasLoggedDeferralCountPastThresholdDualQuitButtons && (deferralCountVar > allowedDeferralsUntilForcedSecondaryQuitButton) {
            let msg = "allowedDeferralsUntilForcedSecondaryQuitButton has been passed"
            uiLog.warning("\(msg, privacy: .public)")
            _ = hasLoggedDeferralCountPastThresholdDualQuitButtons = true
        }
        if deferralCountVar > allowedDeferrals  {
            if !hasLoggedDeferralCountPastThreshold {
                let msg = "allowedDeferrals has been passed"
                uiLog.warning("\(msg, privacy: .public)")
            }
            _ = hasLoggedDeferralCountPastThreshold = true
            // Loop through all the running applications and hide them
            for runningApplication in runningApplications {
                let appName = runningApplication.bundleIdentifier ?? ""
                let appBundle = runningApplication.bundleURL
                if acceptableApps.contains(appName) {
                    continue
                }
                if majorUpgradeAppPathExists {
                    if NSURL.fileURL(withPath: majorUpgradeAppPath) == appBundle {
                        continue
                    }
                }
                // Taken from nudge-python as there was a race condition with NSWorkspace
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001, execute: {
                    runningApplication.hide()
                })
            }
            Utils().activateNudge()
            Utils().updateDevice(userClicked: false)
        } else {
            Utils().activateNudge()
        }
        return true
    }
    return false
}
