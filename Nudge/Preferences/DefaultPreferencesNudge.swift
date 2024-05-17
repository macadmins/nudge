//
//  DefaultPreferencesNudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/8/21.
//

import Foundation

// Global Variables
struct GlobalVariables {
    static let currentOSVersion = OSVersion(ProcessInfo().operatingSystemVersion).description
    static var fetchMajorUpgradeSuccessful = false
}

// Preferences Wrapper
public class PrefsWrapper {
    internal static var prefsOverride: [String: Any]?
    
    public static var requiredInstallationDate: Date {
        prefsOverride?["requiredInstallationDate"] as? Date ??
        OSVersionRequirementVariables.osVersionRequirementsProfile?.requiredInstallationDate ??
        OSVersionRequirementVariables.osVersionRequirementsJSON?.requiredInstallationDate ??
        Date(timeIntervalSince1970: 0)
    }
    
    public static var requiredMinimumOSVersion: String {
        prefsOverride?["requiredMinimumOSVersion"] as? String ??
        OSVersionRequirementVariables.osVersionRequirementsProfile?.requiredMinimumOSVersion ??
        OSVersionRequirementVariables.osVersionRequirementsJSON?.requiredMinimumOSVersion ??
        "0.0"
    }
    
    public static var allowGracePeriods: Bool {
        prefsOverride?["allowGracePeriods"] as? Bool ??
        UserExperienceVariables.userExperienceProfile?["allowGracePeriods"] as? Bool ??
        UserExperienceVariables.userExperienceJSON?.allowGracePeriods ??
        false
    }
}

// Features that can be placed in multiple primary keys
struct FeatureVariables {
    static var osVersionRequirementsProfile: OSVersionRequirement? = getOSVersionRequirementsProfile()
    static var osVersionRequirementsJSON: OSVersionRequirement? = getOSVersionRequirementsJSON()
    static var userInterfaceProfile: [String: Any]? = getUserInterfaceProfile()
    static var userInterfaceJSON: UserInterface? = getUserInterfaceJSON()

    static var actionButtonPath: String? {
        osVersionRequirementsProfile?.actionButtonPath ??
        osVersionRequirementsJSON?.actionButtonPath ??
        userInterfaceProfile?["actionButtonPath"] as? String ??
        userInterfaceJSON?.actionButtonPath
    }
}

// Optional Features
struct OptionalFeatureVariables {
    static var optionalFeaturesProfile: [String: Any]? = getOptionalFeaturesProfile()
    static var optionalFeaturesJSON: OptionalFeatures? = getOptionalFeaturesJSON()
    
    static var acceptableApplicationBundleIDs: [String] {
        optionalFeaturesProfile?["acceptableApplicationBundleIDs"] as? [String] ??
        optionalFeaturesJSON?.acceptableApplicationBundleIDs ??
        [String]()
    }

    static var acceptableAssertionApplicationNames: [String] {
        optionalFeaturesProfile?["acceptableAssertionApplicationNames"] as? [String] ??
        optionalFeaturesJSON?.acceptableAssertionApplicationNames ??
        [String]()
    }
    
    static var acceptableAssertionUsage: Bool {
        optionalFeaturesProfile?["acceptableAssertionUsage"] as? Bool ??
        optionalFeaturesJSON?.acceptableAssertionUsage ??
        false
    }
    
    static var acceptableCameraUsage: Bool {
        optionalFeaturesProfile?["acceptableCameraUsage"] as? Bool ??
        optionalFeaturesJSON?.acceptableCameraUsage ??
        false
    }
    
    static var acceptableScreenSharingUsage: Bool {
        optionalFeaturesProfile?["acceptableScreenSharingUsage"] as? Bool ??
        optionalFeaturesJSON?.acceptableScreenSharingUsage ??
        false
    }
    
    static var aggressiveUserExperience: Bool {
        optionalFeaturesProfile?["aggressiveUserExperience"] as? Bool ??
        optionalFeaturesJSON?.aggressiveUserExperience ??
        true
    }
    
    static var aggressiveUserFullScreenExperience: Bool {
        optionalFeaturesProfile?["aggressiveUserFullScreenExperience"] as? Bool ??
        optionalFeaturesJSON?.aggressiveUserFullScreenExperience ??
        true
    }

    static var asynchronousSoftwareUpdate: Bool {
        optionalFeaturesProfile?["asynchronousSoftwareUpdate"] as? Bool ??
        optionalFeaturesJSON?.asynchronousSoftwareUpdate ??
        true
    }

    static var attemptToBlockApplicationLaunches: Bool {
        optionalFeaturesProfile?["attemptToBlockApplicationLaunches"] as? Bool ??
        optionalFeaturesJSON?.attemptToBlockApplicationLaunches ??
        false
    }

    static var attemptToCheckForSupportedDevice: Bool {
        optionalFeaturesProfile?["attemptToCheckForSupportedDevice"] as? Bool ??
        optionalFeaturesJSON?.attemptToCheckForSupportedDevice ??
        false
    }

    static var attemptToFetchMajorUpgrade: Bool {
        optionalFeaturesProfile?["attemptToFetchMajorUpgrade"] as? Bool ??
        optionalFeaturesJSON?.attemptToFetchMajorUpgrade ??
        true
    }

    static var blockedApplicationBundleIDs: [String] {
        optionalFeaturesProfile?["blockedApplicationBundleIDs"] as? [String] ??
        optionalFeaturesJSON?.blockedApplicationBundleIDs ??
        [String]()
    }

    static var enforceMinorUpdates: Bool {
        optionalFeaturesProfile?["enforceMinorUpdates"] as? Bool ??
        optionalFeaturesJSON?.enforceMinorUpdates ??
        true
    }

    static var disableSoftwareUpdateWorkflow: Bool {
        optionalFeaturesProfile?["disableSoftwareUpdateWorkflow"] as? Bool ??
        optionalFeaturesJSON?.disableSoftwareUpdateWorkflow ??
        false
    }

    static var terminateApplicationsOnLaunch: Bool {
        optionalFeaturesProfile?["terminateApplicationsOnLaunch"] as? Bool ??
        optionalFeaturesJSON?.terminateApplicationsOnLaunch ??
        false
    }

    static var utilizeSOFAFeed: Bool {
        optionalFeaturesProfile?["utilizeSOFAFeedh"] as? Bool ??
        optionalFeaturesJSON?.utilizeSOFAFeed ??
        false
    }
}

// OS Version Requirements
var majorUpgradeAppPathExists = FileManager.default.fileExists(atPath: OSVersionRequirementVariables.majorUpgradeAppPath)
var majorUpgradeBackupAppPathExists = FileManager.default.fileExists(atPath: NetworkFileManager().getBackupMajorUpgradeAppPath())
var requiredInstallationDate = DateManager().getFormattedDate(date: PrefsWrapper.requiredInstallationDate)
struct OSVersionRequirementVariables {
    static var osVersionRequirementsProfile: OSVersionRequirement? = getOSVersionRequirementsProfile()
    static var osVersionRequirementsJSON: OSVersionRequirement? = getOSVersionRequirementsJSON()
    
    static var aboutUpdateURL: String {
        getAboutUpdateURL(OSVerReq: osVersionRequirementsProfile) ??
        getAboutUpdateURL(OSVerReq: osVersionRequirementsJSON) ??
        ""
    }

    static var activelyExploitedInstallationSLA: Int {
        osVersionRequirementsProfile?.activelyExploitedInstallationSLA ??
        osVersionRequirementsJSON?.activelyExploitedInstallationSLA ??
        14
    }

    static var majorUpgradeAppPath: String {
        osVersionRequirementsProfile?.majorUpgradeAppPath ??
        osVersionRequirementsJSON?.majorUpgradeAppPath ??
        ""
    }
    
    static var requiredMinimumOSVersion: String {
        if PrefsWrapper.requiredMinimumOSVersion == "latest" {
            PrefsWrapper.requiredMinimumOSVersion
        } else {
            try! OSVersion(PrefsWrapper.requiredMinimumOSVersion).description
        }
    }

    static var standardInstallationSLA: Int {
        osVersionRequirementsProfile?.standardInstallationSLA ??
        osVersionRequirementsJSON?.standardInstallationSLA ??
        28
    }

    static var unsupportedURL: String {
        getUnsupportedURL(OSVerReq: osVersionRequirementsProfile) ??
        getUnsupportedURL(OSVerReq: osVersionRequirementsJSON) ??
        ""
    }
}


// User Experience
struct UserExperienceVariables {
    static var userExperienceProfile: [String: Any]? = getUserExperienceProfile()
    static var userExperienceJSON: UserExperience? = getUserExperienceJSON()
    
    static var allowGracePeriods: Bool {
        PrefsWrapper.allowGracePeriods
    }

    static var allowLaterDeferralButton: Bool {
        userExperienceProfile?["allowLaterDeferralButton"] as? Bool ??
        userExperienceJSON?.allowLaterDeferralButton ??
        true
    }

    static var allowMovableWindow: Bool {
        userExperienceProfile?["allowMovableWindow"] as? Bool ??
        userExperienceJSON?.allowMovableWindow ??
        false
    }

    static var allowUserQuitDeferrals: Bool {
        userExperienceProfile?["allowUserQuitDeferrals"] as? Bool ??
        userExperienceJSON?.allowUserQuitDeferrals ??
        true
    }

    static var allowedDeferrals: Int {
        userExperienceProfile?["allowedDeferrals"] as? Int ??
        userExperienceJSON?.allowedDeferrals ??
        1000000
    }

    static var allowedDeferralsUntilForcedSecondaryQuitButton: Int {
        userExperienceProfile?["allowedDeferralsUntilForcedSecondaryQuitButton"] as? Int ??
        userExperienceJSON?.allowedDeferralsUntilForcedSecondaryQuitButton ??
        14
    }

    static var approachingRefreshCycle: Int {
        userExperienceProfile?["approachingRefreshCycle"] as? Int ??
        userExperienceJSON?.approachingRefreshCycle ??
        6000
    }

    static var approachingWindowTime: Int {
        userExperienceProfile?["approachingWindowTime"] as? Int ??
        userExperienceJSON?.approachingWindowTime ??
        72
    }

    static var calendarDeferralUnit: String {
        userExperienceProfile?["calendarDeferralUnit"] as? String ??
        userExperienceJSON?.calendarDeferralUnit ??
        "calendarDeferralUnit"
    }

    static var elapsedRefreshCycle: Int {
        userExperienceProfile?["elapsedRefreshCycle"] as? Int ??
        userExperienceJSON?.elapsedRefreshCycle ??
        300
    }

    static var gracePeriodInstallDelay: Int {
        userExperienceProfile?["gracePeriodInstallDelay"] as? Int ??
        userExperienceJSON?.gracePeriodInstallDelay ??
        23
    }

    static var gracePeriodLaunchDelay: Int {
        userExperienceProfile?["gracePeriodLaunchDelay"] as? Int ??
        userExperienceJSON?.gracePeriodLaunchDelay ??
        1
    }

    static var gracePeriodPath: String {
        userExperienceProfile?["gracePeriodPath"] as? String ??
        userExperienceJSON?.gracePeriodPath ??
        "/private/var/db/.AppleSetupDone"
    }

    static var imminentRefreshCycle: Int {
        userExperienceProfile?["imminentRefreshCycle"] as? Int ??
        userExperienceJSON?.imminentRefreshCycle ??
        600
    }

    static var imminentWindowTime: Int {
        userExperienceProfile?["imminentWindowTime"] as? Int ??
        userExperienceJSON?.imminentWindowTime ??
        24
    }

    static var initialRefreshCycle: Int {
        userExperienceProfile?["initialRefreshCycle"] as? Int ??
        userExperienceJSON?.initialRefreshCycle ??
        18000
    }

    static var launchAgentIdentifier: String {
        userExperienceProfile?["launchAgentIdentifier"] as? String ??
        userExperienceJSON?.launchAgentIdentifier ??
        "com.github.macadmins.Nudge"
    }

    static var loadLaunchAgent: Bool {
        userExperienceProfile?["loadLaunchAgent"] as? Bool ??
        userExperienceJSON?.loadLaunchAgent ??
        false
    }

    static var maxRandomDelayInSeconds: Int {
        userExperienceProfile?["maxRandomDelayInSeconds"] as? Int ??
        userExperienceJSON?.maxRandomDelayInSeconds ??
        1200
    }

    static var noTimers: Bool {
        userExperienceProfile?["noTimers"] as? Bool ??
        userExperienceJSON?.noTimers ??
        false
    }

    static var nudgeRefreshCycle: Int {
        userExperienceProfile?["nudgeRefreshCycle"] as? Int ??
        userExperienceJSON?.nudgeRefreshCycle ??
        60
    }

    static var randomDelay: Bool {
        userExperienceProfile?["randomDelay"] as? Bool ??
        userExperienceJSON?.randomDelay ??
        false
    }
}

// User Interface
struct UserInterfaceVariables {
    static var userInterfaceProfile: [String: Any]? = getUserInterfaceProfile()
    static var userInterfaceJSON: UserInterface? = getUserInterfaceJSON()
    static var userInterfaceUpdateElementsProfile: [String:AnyObject]? = getUserInterfaceUpdateElementsProfile()
    static var userInterfaceUpdateElementsJSON: UpdateElement? = getUserInterfaceUpdateElementsJSON()
    
    static var fallbackLanguage: String {
        userInterfaceProfile?["fallbackLanguage"] as? String ??
        userInterfaceJSON?.fallbackLanguage ??
        "en"
    }

    static var forceFallbackLanguage: Bool {
        userInterfaceProfile?["forceFallbackLanguage"] as? Bool ??
        userInterfaceJSON?.forceFallbackLanguage ??
        false
    }

    static var iconDarkPath: String {
        userInterfaceProfile?["iconDarkPath"] as? String ??
        userInterfaceJSON?.iconDarkPath ??
        ""
    }

    static var iconLightPath: String {
        userInterfaceProfile?["iconLightPath"] as? String ??
        userInterfaceJSON?.iconLightPath ??
        ""
    }

    static var screenShotDarkPath: String {
        userInterfaceProfile?["screenShotDarkPath"] as? String ??
        userInterfaceJSON?.screenShotDarkPath ??
        ""
    }

    static var screenShotLightPath: String {
        userInterfaceProfile?["screenShotLightPath"] as? String ??
        userInterfaceJSON?.screenShotLightPath ??
        ""
    }

    static var actionButtonText: String {
        userInterfaceUpdateElementsProfile?["actionButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.actionButtonText ??
        "Update Device"
    }

    static var informationButtonText: String {
        userInterfaceUpdateElementsProfile?["informationButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.informationButtonText ??
        "More Info"
    }

    static var informationButtonTextUnsupported: String {
        userInterfaceUpdateElementsProfile?["informationButtonTextUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.informationButtonTextUnsupported ??
        "Replace Your Device"
    }

    static var mainContentHeader: String {
        userInterfaceUpdateElementsProfile?["mainContentHeader"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentHeader ??
        "**Your device will restart during this update**"
    }

    static var mainContentHeaderUnsupported: String {
        userInterfaceUpdateElementsProfile?["mainContentHeaderUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentHeaderUnsupported ??
        "**Your device is no longer capable of receving critical security updates**"
    }

    static var mainContentNote: String {
        userInterfaceUpdateElementsProfile?["mainContentNote"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentNote ??
        "**Important Notes**"
    }

    static var mainContentNoteUnsupported: String {
        userInterfaceUpdateElementsProfile?["mainContentNoteUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentNoteUnsupported ??
        "**Important Notes**"
    }

    static var mainContentSubHeader: String {
        userInterfaceUpdateElementsProfile?["mainContentSubHeader"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentSubHeader ??
        "Updates can take around 30 minutes to complete"
    }

    static var mainContentSubHeaderUnsupported: String {
        userInterfaceUpdateElementsProfile?["mainContentSubHeaderUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentSubHeaderUnsupported ??
        "Please work with your local IT team to obtain a replacement device"
    }

    static var mainContentText: String {
        userInterfaceUpdateElementsProfile?["mainContentText"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentText ??
        "A fully up-to-date device is required to ensure that IT can accurately protect your device.\n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks.\n\nTo begin the update, simply click on the Update Device button and follow the provided steps."
    }

    static var mainContentTextUnsupported: String {
        userInterfaceUpdateElementsProfile?["mainContentTextUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.mainContentTextUnsupported ??
        "A fully up-to-date device is required to ensure that IT can accurately protect your device.\n\nIf you do not obtain a replacement device, you will lose access to some items necessary for your day-to-day tasks.\n\nFor more information about this, please click on the **Replace Your Device** button."
    }

    static var primaryQuitButtonText: String {
        userInterfaceUpdateElementsProfile?["primaryQuitButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.primaryQuitButtonText ??
        "Later"
    }

    static var secondaryQuitButtonText: String {
        userInterfaceUpdateElementsProfile?["secondaryQuitButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.secondaryQuitButtonText ??
        "I understand"
    }

    static var showDeferralCount: Bool {
        userInterfaceProfile?["showDeferralCount"] as? Bool ??
        userInterfaceJSON?.showDeferralCount ??
        true
    }

    static var singleQuitButton: Bool {
        userInterfaceProfile?["singleQuitButton"] as? Bool ??
        userInterfaceJSON?.singleQuitButton ??
        false
    }

    static var subHeader: String {
        userInterfaceUpdateElementsProfile?["subHeader"] as? String ??
        userInterfaceUpdateElementsJSON?.subHeader ??
        "**A friendly reminder from your local IT team**"
    }

    static var subHeaderUnsupported: String {
        userInterfaceUpdateElementsProfile?["subHeaderUnsupported"] as? String ??
        userInterfaceUpdateElementsJSON?.subHeaderUnsupported ??
        "**A friendly reminder from your local IT team**"
    }


    static var customDeferralDropdownText: String {
        userInterfaceUpdateElementsProfile?["customDeferralDropdownText"] as? String ??
        userInterfaceUpdateElementsJSON?.customDeferralDropdownText ??
        "Defer"
    }

    static var customDeferralButtonText: String {
        userInterfaceUpdateElementsProfile?["customDeferralButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.customDeferralButtonText ??
        "Custom"
    }

    static var oneDayDeferralButtonText: String {
        userInterfaceUpdateElementsProfile?["oneDayDeferralButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.oneDayDeferralButtonText ??
        "One Day"
    }

    static var oneHourDeferralButtonText: String {
        userInterfaceUpdateElementsProfile?["oneHourDeferralButtonText"] as? String ??
        userInterfaceUpdateElementsJSON?.oneHourDeferralButtonText ??
        "One Hour"
    }

    static var screenShotAltText: String {
        userInterfaceUpdateElementsProfile?["screenShotAltText"] as? String ??
        userInterfaceUpdateElementsJSON?.screenShotAltText ??
        "Click to zoom into screenshot"
    }
}

// Other important defaults
#if DEBUG
let builtInAcceptableApplicationBundleIDs = [
    "com.apple.InstallAssistant.macOSBigSur",
    "com.apple.InstallAssistant.macOSMonterey",
    "com.apple.InstallAssistant.macOSVentura",
    "com.apple.InstallAssistant.macOSSonoma",
    "com.apple.loginwindow",
    "com.apple.MobileAsset.MacSoftwareUpdate",
    "com.apple.ScreenSaver.Engine",
    "com.apple.systempreferences",
    "com.apple.dt.Xcode",
]
#else
let builtInAcceptableApplicationBundleIDs = [
    "com.apple.InstallAssistant.macOSBigSur",
    "com.apple.InstallAssistant.macOSMonterey",
    "com.apple.InstallAssistant.macOSVentura",
    "com.apple.InstallAssistant.macOSSonoma",
    "com.apple.loginwindow",
    "com.apple.MobileAsset.MacSoftwareUpdate",
    "com.apple.ScreenSaver.Engine",
    "com.apple.systempreferences",
]
#endif
