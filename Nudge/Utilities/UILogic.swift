//
//  UILogic.swift
//  Nudge
//
//  Created by Erik Gomez on 2/10/21.
//

import AppKit
import Foundation
import IOKit.pwr_mgt // Asertions

// Idea from https://github.com/saagarjha/vers/blob/d9460f6e14311e0a90c4c171975c93419481586b/vers/Headers.swift
let DNDServer = Bundle(path: "/System/Library/PrivateFrameworks/DoNotDisturbServer.framework")?.load() ?? false

class DNDConfig {
    static let rawType = NSClassFromString("DNDSAuxiliaryStateMonitor") as? NSObject.Type ?? nil
    let rawValue: NSObject?
    
    init() {
        self.rawValue = Self.rawType == nil ? nil : (Self.rawType!).init()
    }
    
    required init(rawValue: NSObject?) {
        guard rawValue!.isKind(of: Self.rawType!) else { fatalError() }
        self.rawValue = rawValue == nil ? nil : rawValue
    }
}

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
    let deferralDate = nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime
    if (deferralDate > Utils().getCurrentDate()) && !(deferralDate > requiredInstallationDate) && !Utils().pastRequiredInstallationDate() {
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
    if NSApplication.shared.isActive {
        uiLog.notice("\("Nudge is currrently the frontmostApplication", privacy: .public)")
        return false
    }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let runningApplications = NSWorkspace.shared.runningApplications
    let pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    
    Utils().logUserSessionDeferrals()
    Utils().logUserDeferrals()
    
    nudgePrimaryState.deferralCountPastThreshhold = nudgePrimaryState.userDeferrals > allowedDeferrals
    
    if nudgePrimaryState.deferralCountPastThreshhold {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThreshhold {
            uiLog.notice("\("allowedDeferrals has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThreshhold = true
        }
    }
    
    if nudgePrimaryState.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons {
            uiLog.notice("\("allowedDeferralsUntilForcedSecondaryQuitButton has been passed", privacy: .public)")
            nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons = true
        }
    }
    
    // Print both controllers back to back
    if !nudgeLogState.afterFirstRun {
        uiLog.info("\("nudgeRefreshCycle: \(nudgeRefreshCycle)", privacy: .public)")
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
    if noTimers {
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
        if NSURL.fileURL(withPath: majorUpgradeAppPath) == frontmostApplication?.bundleURL {
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
    if acceptableCameraUsage && !pastRequiredInstallationDate {
        for camera in cameras {
            if camera.isOn {
                uiLog.info("\("Ignoring Nudge activation - Camera is currently on and not pastRequiredInstallationDate", privacy: .public)")
                return false
            }
        }
    }

    // Don't nudge if screen sharing and prior to requiredInstallationDate
    if DNDServer && acceptableScreenSharingUsage && !pastRequiredInstallationDate {
        if (DNDConfig().rawValue?.value(forKey: "isScreenShared") as? Bool ?? false) == true && !pastRequiredInstallationDate {
            uiLog.info("\("Ignoring Nudge activation - Screen sharing is currently active and not pastRequiredInstallationDate", privacy: .public)")
            return false
        }
    }

    // Don't nudge if assertions are set and prior to requiredInstallationDate
    if acceptableAssertionUsage && !pastRequiredInstallationDate {
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
                if acceptableAssertionApplicationNames.contains(processName) {
                    uiLog.info("\("Ignoring Nudge activation - Assertion \(assertionType) is set for \(processName)", privacy: .public)")
                    return false
                }
            }
        }
    }

    // Don't nudge if acceptable apps are frontmostApplication
    if builtInAcceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier!)!) || customAcceptableApplicationBundleIDs.contains((frontmostApplication?.bundleIdentifier!)!) {
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
