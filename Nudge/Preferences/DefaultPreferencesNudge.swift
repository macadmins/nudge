//
//  DefaultPreferencesNudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/8/21.
//

import Foundation

// Globals
let currentOSVersion = OSVersion(ProcessInfo().operatingSystemVersion).description
var fetchMajorUpgradeSuccessful = false

public class PrefsWrapper {
    internal static var prefsOverride: [String:Any]?
    
    public class var requiredInstallationDate: Date {
        return prefsOverride?["requiredInstallationDate"] as? Date ?? osVersionRequirementsProfile?.requiredInstallationDate ?? osVersionRequirementsJSON?.requiredInstallationDate ?? Date(timeIntervalSince1970: 0)
    }
    public class var requiredMinimumOSVersion: String {
        return prefsOverride?["requiredMinimumOSVersion"] as? String ?? osVersionRequirementsProfile?.requiredMinimumOSVersion ?? osVersionRequirementsJSON?.requiredMinimumOSVersion ?? "0.0"
    }
    public class var allowGracePeriods: Bool {
        return (prefsOverride?["allowGracePeriods"] as? Bool) ?? userExperienceProfile?["allowGracePeriods"] as? Bool ?? userExperienceJSON?.allowGracePeriods ?? false
    }
}

// Features can be placed in multiple primary keys
let actionButtonPath = osVersionRequirementsProfile?.actionButtonPath ?? osVersionRequirementsJSON?.actionButtonPath ?? userInterfaceProfile?["actionButtonPath"] as? String ?? userInterfaceJSON?.actionButtonPath ?? nil

// optionalFeatures
let optionalFeaturesProfile = getOptionalFeaturesProfile()
let optionalFeaturesJSON = getOptionalFeaturesJSON()
let customAcceptableApplicationBundleIDs = optionalFeaturesProfile?["acceptableApplicationBundleIDs"] as? [String] ?? optionalFeaturesJSON?.acceptableApplicationBundleIDs ?? [String]()
let acceptableAssertionApplicationNames = optionalFeaturesProfile?["acceptableAssertionApplicationNames"] as? [String] ?? optionalFeaturesJSON?.acceptableAssertionApplicationNames ?? [String]()
let acceptableAssertionUsage = optionalFeaturesProfile?["acceptableAssertionUsage"] as? Bool ?? optionalFeaturesJSON?.acceptableAssertionUsage ?? false
let acceptableCameraUsage = optionalFeaturesProfile?["acceptableCameraUsage"] as? Bool ?? optionalFeaturesJSON?.acceptableCameraUsage ?? false
let acceptableScreenSharingUsage = optionalFeaturesProfile?["acceptableScreenSharingUsage"] as? Bool ?? optionalFeaturesJSON?.acceptableScreenSharingUsage ?? false
let aggressiveUserExperience = optionalFeaturesProfile?["aggressiveUserExperience"] as? Bool ?? optionalFeaturesJSON?.aggressiveUserExperience ?? true
let aggressiveUserFullScreenExperience = optionalFeaturesProfile?["aggressiveUserFullScreenExperience"] as? Bool ?? optionalFeaturesJSON?.aggressiveUserFullScreenExperience ?? true
let asynchronousSoftwareUpdate = optionalFeaturesProfile?["asynchronousSoftwareUpdate"] as? Bool ?? optionalFeaturesJSON?.asynchronousSoftwareUpdate ?? true
let attemptToBlockApplicationLaunches = optionalFeaturesProfile?["attemptToBlockApplicationLaunches"] as? Bool ?? optionalFeaturesJSON?.attemptToBlockApplicationLaunches ?? false
let attemptToFetchMajorUpgrade = optionalFeaturesProfile?["attemptToFetchMajorUpgrade"] as? Bool ?? optionalFeaturesJSON?.attemptToFetchMajorUpgrade ?? true
let blockedApplicationBundleIDs = optionalFeaturesProfile?["blockedApplicationBundleIDs"] as? [String] ?? optionalFeaturesJSON?.blockedApplicationBundleIDs ?? [String]()
let enforceMinorUpdates = optionalFeaturesProfile?["enforceMinorUpdates"] as? Bool ?? optionalFeaturesJSON?.enforceMinorUpdates ?? true
let disableSoftwareUpdateWorkflow = optionalFeaturesProfile?["disableSoftwareUpdateWorkflow"] as? Bool ?? optionalFeaturesJSON?.disableSoftwareUpdateWorkflow ?? false
let terminateApplicationsOnLaunch = optionalFeaturesProfile?["terminateApplicationsOnLaunch"] as? Bool ?? optionalFeaturesJSON?.terminateApplicationsOnLaunch ?? false

// osVersionRequirements
let osVersionRequirementsProfile = getOSVersionRequirementsProfile()
let osVersionRequirementsJSON = getOSVersionRequirementsJSON()
let majorUpgradeAppPath = osVersionRequirementsProfile?.majorUpgradeAppPath ?? osVersionRequirementsJSON?.majorUpgradeAppPath ?? ""
var majorUpgradeAppPathExists = FileManager.default.fileExists(atPath: majorUpgradeAppPath)
var majorUpgradeBackupAppPathExists = FileManager.default.fileExists(atPath: Utils().getBackupMajorUpgradeAppPath())
var requiredInstallationDate = Utils().getFormattedDate(date: PrefsWrapper.requiredInstallationDate)
let requiredMinimumOSVersion = try! OSVersion(PrefsWrapper.requiredMinimumOSVersion).description
let requiredMinimumOSVersionTest = try! OSVersion(PrefsWrapper.requiredMinimumOSVersion).description

let aboutUpdateURL = getAboutUpdateURL(OSVerReq: osVersionRequirementsProfile) ?? getAboutUpdateURL(OSVerReq: osVersionRequirementsJSON) ?? ""

// userExperience
let userExperienceProfile = getUserExperienceProfile()
let userExperienceJSON = getUserExperienceJSON()
let allowGracePeriods = PrefsWrapper.allowGracePeriods
let allowLaterDeferralButton = userExperienceProfile?["allowLaterDeferralButton"] as? Bool ?? userExperienceJSON?.allowLaterDeferralButton ?? true
let allowUserQuitDeferrals = userExperienceProfile?["allowUserQuitDeferrals"] as? Bool ?? userExperienceJSON?.allowUserQuitDeferrals ?? true
let allowedDeferrals = userExperienceProfile?["allowedDeferrals"] as? Int ?? userExperienceJSON?.allowedDeferrals ?? 1000000
let allowedDeferralsUntilForcedSecondaryQuitButton = userExperienceProfile?["allowedDeferralsUntilForcedSecondaryQuitButton"] as? Int ?? userExperienceJSON?.allowedDeferralsUntilForcedSecondaryQuitButton ?? 14
let approachingRefreshCycle = userExperienceProfile?["approachingRefreshCycle"] as? Int ?? userExperienceJSON?.approachingRefreshCycle ?? 6000
let approachingWindowTime = userExperienceProfile?["approachingWindowTime"] as? Int ?? userExperienceJSON?.approachingWindowTime ?? 72
let elapsedRefreshCycle = userExperienceProfile?["elapsedRefreshCycle"] as? Int ?? userExperienceJSON?.elapsedRefreshCycle ?? 300
let gracePeriodInstallDelay = userExperienceProfile?["gracePeriodInstallDelay"] as? Int ?? userExperienceJSON?.gracePeriodInstallDelay ?? 23
let gracePeriodLaunchDelay = userExperienceProfile?["gracePeriodLaunchDelay"] as? Int ?? userExperienceJSON?.gracePeriodLaunchDelay ?? 1
let gracePeriodPath = userExperienceProfile?["gracePeriodPath"] as? String ?? userExperienceJSON?.gracePeriodPath ?? "/private/var/db/.AppleSetupDone"
let imminentRefreshCycle = userExperienceProfile?["imminentRefreshCycle"] as? Int ?? userExperienceJSON?.imminentRefreshCycle ?? 600
let imminentWindowTime = userExperienceProfile?["imminentWindowTime"] as? Int ?? userExperienceJSON?.imminentWindowTime ?? 24
let initialRefreshCycle = userExperienceProfile?["initialRefreshCycle"] as? Int ?? userExperienceJSON?.initialRefreshCycle ?? 18000
let launchAgentIdentifier = userExperienceProfile?["launchAgentIdentifier"] as? String ?? userExperienceJSON?.launchAgentIdentifier ?? "com.github.macadmins.Nudge"
let loadLaunchAgent = userExperienceProfile?["loadLaunchAgent"] as? Bool ?? userExperienceJSON?.loadLaunchAgent ?? false
let maxRandomDelayInSeconds = userExperienceProfile?["maxRandomDelayInSeconds"] as? Int ?? userExperienceJSON?.maxRandomDelayInSeconds ?? 1200
let noTimers = userExperienceProfile?["noTimers"] as? Bool ?? userExperienceJSON?.noTimers ?? false
let nudgeRefreshCycle = userExperienceProfile?["nudgeRefreshCycle"] as? Int ?? userExperienceJSON?.nudgeRefreshCycle ?? 60
let randomDelay = userExperienceProfile?["randomDelay"] as? Bool ?? userExperienceJSON?.randomDelay ?? false
let calendarDeferUntilApproaching = userExperienceProfile?["calendarDeferUntilApproaching"] as? Bool ?? userExperienceJSON?.calendarDeferUntilApproaching ?? false

// userInterface
let userInterfaceProfile = getUserInterfaceProfile()
let userInterfaceJSON = getUserInterfaceJSON()
let userInterfaceUpdateElementsProfile = getUserInterfaceUpdateElementsProfile()
let userInterfaceUpdateElementsJSON = getUserInterfaceUpdateElementsJSON()
let fallbackLanguage = userInterfaceProfile?["fallbackLanguage"] as? String ?? userInterfaceJSON?.fallbackLanguage ?? "en"
let forceFallbackLanguage = userInterfaceProfile?["forceFallbackLanguage"] as? Bool ?? userInterfaceJSON?.forceFallbackLanguage ?? false
let iconDarkPath = userInterfaceProfile?["iconDarkPath"] as? String ?? userInterfaceJSON?.iconDarkPath ?? ""
let iconLightPath = userInterfaceProfile?["iconLightPath"] as? String ?? userInterfaceJSON?.iconLightPath ?? ""
let screenShotDarkPath = userInterfaceProfile?["screenShotDarkPath"] as? String ?? userInterfaceJSON?.screenShotDarkPath ?? ""
let screenShotLightPath = userInterfaceProfile?["screenShotLightPath"] as? String ?? userInterfaceJSON?.screenShotLightPath ?? ""
let actionButtonText = userInterfaceUpdateElementsProfile?["actionButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.actionButtonText ?? "Update Device".localized(desiredLanguage: getDesiredLanguage())
let informationButtonText = userInterfaceUpdateElementsProfile?["informationButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.informationButtonText ?? "More Info".localized(desiredLanguage: getDesiredLanguage())
let mainContentHeader = userInterfaceUpdateElementsProfile?["mainContentHeader"] as? String ?? userInterfaceUpdateElementsJSON?.mainContentHeader ?? "Your device will restart during this update".localized(desiredLanguage: getDesiredLanguage())
let mainContentNote = userInterfaceUpdateElementsProfile?["mainContentNote"] as? String ?? userInterfaceUpdateElementsJSON?.mainContentNote ?? "Important Notes".localized(desiredLanguage: getDesiredLanguage())
let mainContentSubHeader = userInterfaceUpdateElementsProfile?["mainContentSubHeader"] as? String ?? userInterfaceUpdateElementsJSON?.mainContentSubHeader ?? "Updates can take around 30 minutes to complete".localized(desiredLanguage: getDesiredLanguage())
let mainContentText = userInterfaceUpdateElementsProfile?["mainContentText"] as? String ?? userInterfaceUpdateElementsJSON?.mainContentText ?? "A fully up-to-date device is required to ensure that IT can accurately protect your device.\n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks.\n\nTo begin the update, simply click on the Update Device button and follow the provided steps.".localized(desiredLanguage: getDesiredLanguage())
let primaryQuitButtonText = userInterfaceUpdateElementsProfile?["primaryQuitButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.primaryQuitButtonText ?? "Later".localized(desiredLanguage: getDesiredLanguage())
let secondaryQuitButtonText = userInterfaceUpdateElementsProfile?["secondaryQuitButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.secondaryQuitButtonText ?? "I understand".localized(desiredLanguage: getDesiredLanguage())
let showDeferralCount = userInterfaceProfile?["showDeferralCount"] as? Bool ?? userInterfaceJSON?.showDeferralCount ?? true
let singleQuitButton = userInterfaceProfile?["singleQuitButton"] as? Bool ?? userInterfaceJSON?.singleQuitButton ?? false
let subHeader = userInterfaceUpdateElementsProfile?["subHeader"] as? String ?? userInterfaceUpdateElementsJSON?.subHeader ?? "A friendly reminder from your local IT team".localized(desiredLanguage: getDesiredLanguage())
let customDeferralDropdownText = userInterfaceUpdateElementsProfile?["customDeferralDropdownText"] as? String ?? userInterfaceUpdateElementsJSON?.customDeferralDropdownText ?? "Defer".localized(desiredLanguage: getDesiredLanguage())
let customDeferralButtonText = userInterfaceUpdateElementsProfile?["customDeferralButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.customDeferralButtonText ?? "Custom".localized(desiredLanguage: getDesiredLanguage())
let oneDayDeferralButtonText = userInterfaceUpdateElementsProfile?["oneDayDeferralButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.oneDayDeferralButtonText ?? "One Day".localized(desiredLanguage: getDesiredLanguage())
let oneHourDeferralButtonText = userInterfaceUpdateElementsProfile?["oneHourDeferralButtonText"] as? String ?? userInterfaceUpdateElementsJSON?.oneHourDeferralButtonText ?? "One Hour".localized(desiredLanguage: getDesiredLanguage())

// Other important defaults
#if DEBUG
let builtInAcceptableApplicationBundleIDs = [
    "com.apple.InstallAssistant.macOSMonterey",
    "com.apple.InstallAssistant.macOSVentura",
    "com.apple.loginwindow",
    "com.apple.ScreenSaver.Engine",
    "com.apple.systempreferences",
    "com.apple.dt.Xcode",
]
#else
let builtInAcceptableApplicationBundleIDs = [
    "com.apple.InstallAssistant.macOSMonterey",
    "com.apple.InstallAssistant.macOSVentura",
    "com.apple.loginwindow",
    "com.apple.ScreenSaver.Engine",
    "com.apple.systempreferences",
]
#endif
