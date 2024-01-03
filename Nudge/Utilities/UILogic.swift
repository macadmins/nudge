//
//  UILogic.swift
//  Nudge
//
//  Created by Erik Gomez on 2/10/21.
//

import AppKit
import Foundation
import IOKit.pwr_mgt // Asertions
import SwiftUI

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
    if Utils().requireDualQuitButtons() || nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton {
        nudgePrimaryState.requireDualQuitButtons = true
    }
    let deferralDate = nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime
    if (deferralDate > Utils().getCurrentDate()) && !(deferralDate > requiredInstallationDate) && !Utils().pastRequiredInstallationDate() {
        uiLog.notice("\("User has selected a deferral date (\(nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime)) that is greater than the launch date (\(Utils().getCurrentDate()))", privacy: .public)")
        Utils().exitNudge()
    }
    if Utils().fullyUpdated() {
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        if isPreview {
            return
        } else {
            uiLog.notice("\("Device is fully updated", privacy: .public)")
            Utils().exitNudge()
        }
    } else if OptionalFeatureVariables.enforceMinorUpdates == false && Utils().requireMajorUpgrade() == false {
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
    if NSApplication.shared.isActive {
        uiLog.notice("\("Nudge is currrently the frontmostApplication", privacy: .public)")
        return false
    }
    
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let runningApplications = NSWorkspace.shared.runningApplications
    let pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    
    Utils().logUserSessionDeferrals()
    Utils().logUserDeferrals()
    
    nudgePrimaryState.deferralCountPastThreshhold = nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferrals
    
    if nudgePrimaryState.deferralCountPastThreshhold {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThreshhold {
            uiLog.notice("\("allowedDeferrals has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThreshhold = true
        }
    }
    
    if nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons {
            uiLog.notice("\("allowedDeferralsUntilForcedSecondaryQuitButton has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons = true
        }
    }
    
    // Print both controllers back to back
    if !nudgeLogState.afterFirstRun {
        uiLog.info("\("nudgeRefreshCycle: \(UserExperienceVariables.nudgeRefreshCycle)", privacy: .public)")
        if !DNDServer {
            uiLog.error("\("acceptableScreenSharingUsage is set but DoNotDisturbServer framework is unavailable", privacy: .public)")
        }
    }
    let timerController = Utils().getTimerController()
    
    // Start to return true or false
    // Demo Mode should activate one time and then never again
    if Utils().demoModeEnabled() {
        if nudgeLogState.afterFirstRun {
            uiLog.info("\("Ignoring Nudge activation - Device is in demo mode", privacy: .public)")
            nudgeLogState.afterFirstRun = true
            return false
        } else {
            uiLog.notice("\("Nudge activating - Launching demo mode UI", privacy: .public)")
            nudgePrimaryState.lastRefreshTime = Utils().getCurrentDate()
            Utils().activateNudge()
            return true
        }
    }
    
    if !nudgeLogState.afterFirstRun {
        nudgeLogState.afterFirstRun = true
    }
    
    // If noTimers is true, just bail
    if UserExperienceVariables.noTimers {
        uiLog.info("\("Ignoring Nudge activation - noTimers is set", privacy: .public)")
        return false
    }
    
    // Don't nudge if screen is locked
    if nudgePrimaryState.screenCurrentlyLocked {
        uiLog.info("\("Ignoring Nudge activation - Screen is currently locked", privacy: .public)")
        return false
    }
    
    // Don't nudge if major upgrade is frontmostApplication
    if majorUpgradeAppPathExists {
        if NSURL.fileURL(withPath: OSVersionRequirementVariables.majorUpgradeAppPath) == frontmostApplication?.bundleURL {
            uiLog.info("\("Ignoring Nudge activation - majorUpgradeApp is currently the frontmostApplication", privacy: .public)")
            return false
        }
    }
    
    if majorUpgradeBackupAppPathExists {
        if NSURL.fileURL(withPath: Utils().getBackupMajorUpgradeAppPath()) == frontmostApplication?.bundleURL {
            uiLog.info("\("Ignoring Nudge activation - majorUpgradeApp (backup) is currently the frontmostApplication", privacy: .public)")
            return false
        }
    }
    
    // Don't nudge if camera is on and prior to requiredInstallationDate
    if OptionalFeatureVariables.acceptableCameraUsage && !pastRequiredInstallationDate {
        for camera in cameras {
            if camera.isOn {
                uiLog.info("\("Ignoring Nudge activation - Camera is currently on and not pastRequiredInstallationDate", privacy: .public)")
                return false
            }
        }
    }
    
    // Don't nudge if screen sharing and prior to requiredInstallationDate
    if DNDServer && OptionalFeatureVariables.acceptableScreenSharingUsage && !pastRequiredInstallationDate {
        if (DNDConfig().rawValue?.value(forKey: "isScreenShared") as? Bool ?? false) == true && !pastRequiredInstallationDate {
            uiLog.info("\("Ignoring Nudge activation - Screen sharing is currently active and not pastRequiredInstallationDate", privacy: .public)")
            return false
        }
    }
    
    // Don't nudge if assertions are set and prior to requiredInstallationDate
    if OptionalFeatureVariables.acceptableAssertionUsage && !pastRequiredInstallationDate {
        // Credit to https://github.com/francescofact/DualDimmer/blob/main/DualDimmer/Worker.swift
        var assertions: Unmanaged<CFDictionary>?
        if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
            uiLog.info("\("Could not assess assertions", privacy: .public)")
        }
        let retainedAssertions = assertions?.takeRetainedValue()
        for assertion in retainedAssertions.unsafelyUnwrapped as NSDictionary{
            let assertionValues = (assertion.value as? NSArray).unsafelyUnwrapped
            for value in assertionValues as! [NSDictionary]{
                let processName = value["Process Name"] as? String ?? ""
                let assertionType = value["AssertionTrueType"] as? String ?? ""
                if OptionalFeatureVariables.acceptableAssertionApplicationNames.contains(processName) {
                    uiLog.info("\("Ignoring Nudge activation - Assertion \(assertionType) is set for \(processName)", privacy: .public)")
                    return false
                }
            }
        }
    }
    
    // Don't nudge if acceptable apps are frontmostApplication
    if builtInAcceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier ?? "")!) || OptionalFeatureVariables.acceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier ?? "")!) {
        uiLog.info("\("Ignoring Nudge activation - acceptableApplication (\(frontmostApplication?.bundleIdentifier ?? "")) is currently the frontmostApplication", privacy: .public)")
        return false
    }
    
    // Don't nudge if refresh timer hasn't passed threshold
    if (timerController > Int((Utils().getCurrentDate().timeIntervalSince1970 - nudgePrimaryState.lastRefreshTime.timeIntervalSince1970))) && nudgeLogState.afterFirstLaunch  {
        uiLog.info("\("Ignoring Nudge activation - Device is currently within current timer range", privacy: .public)")
        return false
    }
    
    // Aggressive logic
    if frontmostApplication?.bundleIdentifier != nil {
        uiLog.info("\("\(frontmostApplication!.bundleIdentifier ?? "") is currently the frontmostApplication", privacy: .public)")
    }
    
    if (nudgePrimaryState.deferralCountPastThreshhold || Utils().pastRequiredInstallationDate()) && OptionalFeatureVariables.aggressiveUserExperience {
        // Loop through all the running applications and hide them
        for runningApplication in runningApplications {
            let appName = runningApplication.bundleIdentifier ?? ""
            let appBundle = runningApplication.bundleURL
            if builtInAcceptableApplicationBundleIDs.contains(appName) || OptionalFeatureVariables.acceptableApplicationBundleIDs.contains(appName) {
                continue
            }
            if majorUpgradeAppPathExists {
                if NSURL.fileURL(withPath: OSVersionRequirementVariables.majorUpgradeAppPath) == appBundle {
                    continue
                }
            }
            
            if majorUpgradeBackupAppPathExists {
                if NSURL.fileURL(withPath: Utils().getBackupMajorUpgradeAppPath()) == appBundle {
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
    
    nudgePrimaryState.lastRefreshTime = Utils().getCurrentDate()
    return true
}
