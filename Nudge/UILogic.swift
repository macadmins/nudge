//
//  UILogic.swift
//  Nudge
//
//  Created by Erik Gomez on 2/10/21.
//

import AppKit
import Foundation

// This likely needs to be refactored into PolicyManager.swift, but I wanted all functions out of Nudge.swift for now
// Start doing a basic check
func nudgeStartLogic() {
    if Utils().fullyUpdated() {
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        // https://zacwhite.com/2020/detecting-swiftui-previews/
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        } else {
            if Utils().demoModeEnabled() {
                print("Device in demo mode")
                if Utils().simpleModeEnabled() {
                    print("Device in simple mode")
                }
            } else {
                print("Device fully up-to-date.")
                AppKit.NSApp.terminate(nil)
            }
        }
    }
}

// These are initial variables that needToActivateNudge() will update within the timer controller
// This type of logic is not indeal and should be redesigned.
var lastRefreshTime = Utils().getInitialDate()
var afterFirstRun = false
var deferralCount = 0

func needToActivateNudge(deferralCountVar: Int, lastRefreshTimeVar: Date) -> Bool {
    // If noTimers is true, just bail
    if noTimers {
        return false
    }
    
    let currentTime = Date().timeIntervalSince1970
    let timeDiff = Int((currentTime - lastRefreshTimeVar.timeIntervalSince1970))

    // The first time the main timer contoller hits we don't care
    if !afterFirstRun {
        print("First run detected")
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
    if FileManager.default.fileExists(atPath: majorUpgradeAppPath) {
        if NSURL.fileURL(withPath: majorUpgradeAppPath) == frontmostApplication?.bundleURL {
            print("Upgrade app is currently frontmostApplication")
            return false
        }
    }
    
    // Don't nudge if acceptable apps are frontmostApplication
    if acceptableApps.contains((frontmostApplication?.bundleIdentifier!)!) {
        print("An acceptable app is currently frontmostApplication")
        return false
    }
    
    // If we get here, Nudge if not frontmostApplication
    if !NSApplication.shared.isActive {
        _ = deferralCount += 1
        _ = lastRefreshTime = Date()
        Utils().activateNudge()
        if deferralCountVar > allowedDeferrals  {
            print("Nudge deferral count over threshold")
            // Loop through all the running applications and hide them
            for runningApplication in runningApplications {
                let appName = runningApplication.bundleIdentifier ?? ""
                let appBundle = runningApplication.bundleURL
                if acceptableApps.contains(appName) {
                    continue
                }
                if NSURL.fileURL(withPath: majorUpgradeAppPath) == appBundle {
                    continue
                }
                // Taken from nudge-python as there was a race condition with NSWorkspace
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001, execute: {
                    runningApplication.hide()
                })
            }
            Utils().updateDevice()
        }
        return true
    }
    return false
}
