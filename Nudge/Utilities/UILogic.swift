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

func initialLaunchLogic() {
    guard !CommandLineUtilities().unitTestingEnabled() else {
        LogManager.debug("App being ran in test mode", logger: uiLog)
        return
    }

    if CommandLineUtilities().simpleModeEnabled() {
        LogManager.debug("Device in simple mode", logger: uiLog)
    }

    if CommandLineUtilities().demoModeEnabled() {
        LogManager.debug("Device in demo mode", logger: uiLog)
        resetDeferralsForDemoMode()
        return
    }

    processNudgeEvent()
    updateDualQuitButtonRequirement()
    checkDeferralDate()
    handleUpdateStatus()
}

private func checkDeferralDate() {
    let deferralDate = nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime
    if shouldExitBasedOnDeferralDate(deferralDate: deferralDate) {
        LogManager.notice("User has selected a deferral date (\(nudgePrimaryState.deferRunUntil ?? nudgePrimaryState.lastRefreshTime)) that is greater than the launch date (\(DateManager().getCurrentDate())", logger: uiLog)
        AppStateManager().exitNudge()
    }
}

private func handleDemoMode() -> Bool {
    if nudgeLogState.afterFirstRun {
        LogManager.info("Ignoring Nudge activation - Device is in demo mode", logger: uiLog)
        nudgeLogState.afterFirstRun = true
        return false
    } else {
        LogManager.notice("Nudge activating - Launching demo mode UI", logger: uiLog)
        AppStateManager().activateNudge()
        return true
    }
}

private func handleUpdateStatus() {
    if VersionManager.fullyUpdated() {
        LogManager.notice("Device is fully updated", logger: uiLog)
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        if !uiConstants.isPreview {
            AppStateManager().exitNudge()
        }
    } else if !OptionalFeatureVariables.enforceMinorUpdates && !AppStateManager().requireMajorUpgrade() {
        LogManager.warning("Device requires a minor update but enforceMinorUpdates is false", logger: uiLog)
        AppStateManager().exitNudge()
    }
}

private func isAcceptableApplicationFrontmost(_ frontmostApplication: NSRunningApplication?) -> Bool {
    if builtInAcceptableApplicationBundleIDs.contains(frontmostApplication?.bundleIdentifier ?? "") ||
        OptionalFeatureVariables.acceptableApplicationBundleIDs.contains(frontmostApplication?.bundleIdentifier ?? "") {
        LogManager.info("Ignoring Nudge activation - acceptableApplication is currently the frontmostApplication", logger: uiLog)
        return true
    }
    return false
}

private func isAcceptableAssertionRunning() -> Bool {
    var assertions: Unmanaged<CFDictionary>?
    guard IOPMCopyAssertionsByProcess(&assertions) == kIOReturnSuccess,
          let assertionDict = assertions?.takeRetainedValue() as NSDictionary? else {
        LogManager.error("Could not assess assertions", logger: uiLog)
        return false
    }

    for (_, value) in assertionDict {
        if let assertionValues = value as? [NSDictionary] {
            for assertion in assertionValues {
                if let processName = assertion["Process Name"] as? String,
                   let assertionType = assertion["AssertionTrueType"] as? String,
                   OptionalFeatureVariables.acceptableAssertionApplicationNames.contains(processName) {
                    LogManager.info("Ignoring Nudge activation - Assertion \(assertionType) is set for \(processName)", logger: uiLog)
                    return true
                }
            }
        }
    }

    return false
}

private func isCameraOn() -> Bool {
    for camera in CameraUtilities().getCameras() {
        if camera.isOn {
            return true
        }
    }
    return false
}

private func isMajorUpgradeApp(_ runningApplication: NSRunningApplication) -> Bool {
    if majorUpgradeAppPathExists {
        let majorUpgradeAppURL = URL(fileURLWithPath: OSVersionRequirementVariables.majorUpgradeAppPath, isDirectory: false)
        return runningApplication.bundleURL == majorUpgradeAppURL
    }
    return false
}

private func isMajorUpgradeAppFrontmost(_ frontmostApplication: NSRunningApplication?) -> Bool {
    if majorUpgradeAppPathExists {
        let majorUpgradeAppURL = URL(fileURLWithPath: OSVersionRequirementVariables.majorUpgradeAppPath, isDirectory: false)
        if frontmostApplication?.bundleURL == majorUpgradeAppURL {
            LogManager.info("Ignoring Nudge activation - majorUpgradeApp is currently the frontmostApplication", logger: uiLog)
            return true
        }
    }

    if majorUpgradeBackupAppPathExists {
        let backupAppURL = URL(fileURLWithPath: NetworkFileManager().getBackupMajorUpgradeAppPath(), isDirectory: false)
        if frontmostApplication?.bundleURL == backupAppURL {
            LogManager.info("Ignoring Nudge activation - majorUpgradeBackupApp is currently the frontmostApplication", logger: uiLog)
            return true
        }
    }

    return false
}

private func isMajorUpgradeAppBackup(_ runningApplication: NSRunningApplication) -> Bool {
    if majorUpgradeBackupAppPathExists {
        let backupAppURL = URL(fileURLWithPath: NetworkFileManager().getBackupMajorUpgradeAppPath(), isDirectory: false)
        return runningApplication.bundleURL == backupAppURL
    }
    return false
}

private func isRefreshTimerPassedThreshold() -> Bool {
    let currentTime = DateManager().getCurrentDate().timeIntervalSince1970
    let timeSinceLastRefresh = currentTime - nudgePrimaryState.lastRefreshTime.timeIntervalSince1970
    if nudgeLogState.afterFirstLaunch && Double(ConfigurationManager().getTimerController()) > timeSinceLastRefresh {
        LogManager.info("Ignoring Nudge activation - Device is currently within current timer range", logger: uiLog)
        return true
    }
    return false
}

private func isScreenSharingActive() -> Bool {
    if (DNDConfig().rawValue?.value(forKey: "isScreenShared") as? Bool ?? false) == true {
        return true
    }
    return false
}

private func logControllers() {
    if !nudgeLogState.afterFirstRun {
        LogManager.info("nudgeRefreshCycle: \(UserExperienceVariables.nudgeRefreshCycle)", logger: uiLog)
        nudgeLogState.afterFirstRun = true
        if !UIConstants.DNDServer {
            LogManager.error("acceptableScreenSharingUsage is set but DoNotDisturbServer framework is unavailable", logger: uiLog)
        }
    }
}

private func logDeferralStates() {
    LoggerUtilities().logRequiredMinimumOSVersion()
    LoggerUtilities().logUserSessionDeferrals()
    LoggerUtilities().logUserQuitDeferrals()
    LoggerUtilities().logUserDeferrals()
}

func needToActivateNudge() -> Bool {
    if NSApplication.shared.isActive && nudgeLogState.afterFirstLaunch {
        LogManager.notice("Nudge is currently the frontmostApplication", logger: uiLog)
        return false
    }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let runningApplications = NSWorkspace.shared.runningApplications

    updateNudgeState()
    logControllers()

    if CommandLineUtilities().demoModeEnabled() {
        return handleDemoMode()
    }

    if shouldBailOutEarly() {
        return false
    }

    if shouldActivateNudgeBasedOnAggressiveExperience(runningApplications, frontmostApplication) {
        return true
    }

    return false
}

private func processNudgeEvent() {
    if VersionManager.newNudgeEvent() {
        LogManager.notice("New Nudge event detected - resetting all deferral values", logger: uiLog)
        resetAllDeferralValues()
    } else {
        updateDeferralCounts()
    }
}

private func resetAllDeferralValues() {
    LoggerUtilities().logRequiredMinimumOSVersion()
    LoggerUtilities().logUserSessionDeferrals(resetCount: true)
    LoggerUtilities().logUserQuitDeferrals(resetCount: true)
    LoggerUtilities().logUserDeferrals(resetCount: true)
    Globals.nudgeDefaults.removeObject(forKey: "deferRunUntil")
}

private func resetDeferralsForDemoMode() {
    nudgePrimaryState.userDeferrals = 0
    nudgePrimaryState.userQuitDeferrals = 0
}

private func shouldActivateNudgeBasedOnAggressiveExperience(_ runningApplications: [NSRunningApplication], _ frontmostApplication: NSRunningApplication?) -> Bool {
    if frontmostApplication?.bundleIdentifier != nil {
        LogManager.info("\(frontmostApplication!.bundleIdentifier ?? "") is currently the frontmostApplication", logger: uiLog)
    }

    let shouldActivate = nudgePrimaryState.deferralCountPastThreshold || DateManager().pastRequiredInstallationDate()

    if shouldActivate && OptionalFeatureVariables.aggressiveUserExperience {
        // Loop through all running applications and hide them if needed
        for runningApplication in runningApplications {
            if shouldHideApplication(runningApplication) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                    LogManager.info("Attempting to hide \(runningApplication.bundleIdentifier ?? "")", logger: uiLog)
                    runningApplication.hide()
                }
            }
        }
        AppStateManager().activateNudge()
        if !CommandLineUtilities().unitTestingEnabled() {
            UIUtilities().updateDevice(userClicked: false)
        }
        return true
    } else {
        AppStateManager().activateNudge()
        return true
    }
}

private func shouldBailOutEarly() -> Bool {
    /// 1. Admin has set noTimers
    /// 2. Screen is Locked
    /// 3. App Upgrade is in front
    /// 4. Camera is on
    /// 5. Screen Sharing is on
    /// 6. Acceptable Assertions are on
    /// 7. Acceptable Apps are in front
    /// 8. Refresh Timer hasn't been met
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let pastRequiredInstallationDate = DateManager().pastRequiredInstallationDate()

    // Check if admin has set noTimers
    if UserExperienceVariables.noTimers {
        LogManager.info("Ignoring Nudge activation - noTimers is set", logger: uiLog)
        return true
    }

    // Check if screen is locked
    if nudgePrimaryState.screenCurrentlyLocked {
        LogManager.info("Ignoring Nudge activation - Screen is currently locked", logger: uiLog)
        return true
    }

    // Check if a major upgrade app is frontmost
    if isMajorUpgradeAppFrontmost(frontmostApplication) {
        return true
    }

    // Check if camera is on and it's before the required installation date
    if OptionalFeatureVariables.acceptableCameraUsage && !pastRequiredInstallationDate && isCameraOn() {
        LogManager.info("Ignoring Nudge activation - Camera is currently on and not past required installation date", logger: uiLog)
        return true
    }

    // Check if screen sharing is active and it's before the required installation date
    if OptionalFeatureVariables.acceptableScreenSharingUsage && !pastRequiredInstallationDate && isScreenSharingActive() {
        LogManager.info("Ignoring Nudge activation - Screen sharing is currently active and not past required installation date", logger: uiLog)
        return true
    }

    // Check if acceptable assertions are running
    if OptionalFeatureVariables.acceptableAssertionUsage && !pastRequiredInstallationDate {
        if isAcceptableAssertionRunning() {
            return true
        }
    }

    // Check if acceptable applications are frontmost
    if isAcceptableApplicationFrontmost(frontmostApplication) {
        return true
    }

    // Check if refresh timer hasn't passed threshold
    if isRefreshTimerPassedThreshold() {
        return true
    }

    return false
}

private func shouldHideApplication(_ runningApplication: NSRunningApplication) -> Bool {
    let acceptableApps = builtInAcceptableApplicationBundleIDs + OptionalFeatureVariables.acceptableApplicationBundleIDs
    let appName = runningApplication.bundleIdentifier ?? ""

    return !acceptableApps.contains(appName) &&
    !isMajorUpgradeApp(runningApplication) &&
    !isMajorUpgradeAppBackup(runningApplication) &&
    appName != "com.github.macadmins.Nudge"
}

private func shouldExitBasedOnDeferralDate(deferralDate: Date) -> Bool {
    return (deferralDate > DateManager().getCurrentDate()) && !(deferralDate > requiredInstallationDate) && !DateManager().pastRequiredInstallationDate()
}

private func updateDeferralCounts() {
    if nudgePrimaryState.userDeferrals >= 0 {
        nudgePrimaryState.userDeferrals = nudgePrimaryState.userSessionDeferrals + nudgePrimaryState.userQuitDeferrals
    }
    logDeferralStates()
}

private func updateDualQuitButtonRequirement() {
    let deferralThreshold = UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton
    nudgePrimaryState.requireDualQuitButtons = AppStateManager().requireDualQuitButtons() || nudgePrimaryState.userDeferrals > deferralThreshold
}

func updateNudgeState() {
    nudgePrimaryState.deferralCountPastThreshold = nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferrals

    if nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton {
        nudgePrimaryState.requireDualQuitButtons = true
    }

    if nudgePrimaryState.deferralCountPastThreshold {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThreshold {
            LogManager.notice("allowedDeferrals has been passed: \(UserExperienceVariables.allowedDeferrals)", logger: uiLog)
            nudgePrimaryState.hasLoggedDeferralCountPastThreshold = true
        }
    }

    if nudgePrimaryState.userDeferrals > UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton {
        if !nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons {
            LogManager.notice("allowedDeferralsUntilForcedSecondaryQuitButton has been passed: \(UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton)", logger: uiLog)
            nudgePrimaryState.hasLoggedDeferralCountPastThresholdDualQuitButtons = true
        }
    }
}

func userHasClickedSecondaryQuitButton() {
    LogManager.notice("User clicked secondaryQuitButton", logger: uiLog)
}

func userHasClickedDeferralQuitButton(deferralTime: Date) {
    LogManager.notice("User initiated a deferral: \(deferralTime)", logger: uiLog)
}
