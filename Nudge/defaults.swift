//
//  defaults.swift
//  Nudge
//
//  Created by Erik Gomez on 2/8/21.
//

import Foundation

// This is stupid and there has to be a better way but after 5 hours of pain I've given up
// Codable needs an easy way to set default values

let nudgePreferences = nudgePrefs().loadNudgePrefs()

// optionalFeatures
let attemptToFetchMajorUpgrade = nudgePreferences?.optionalFeatures?.attemptToFetchMajorUpgrade ?? false

// optionalFeatures - MDM
let alwaysShowManualEnerllment = nudgePreferences?.optionalFeatures?.umadFeatures?.alwaysShowManulEnrollment ?? false
let depScreenShotPath = nudgePreferences?.optionalFeatures?.umadFeatures?.depScreenShotPath ?? ""
let disableManualEnrollmentForDEP = nudgePreferences?.optionalFeatures?.umadFeatures?.disableManualEnrollmentForDEP ?? false
let enforceMDMInstallation = nudgePreferences?.optionalFeatures?.umadFeatures?.enforceMDMInstallation ?? false
let manulEnrollmentPath = nudgePreferences?.optionalFeatures?.umadFeatures?.manualEnrollmentPath ?? "https://apple.com"
let mdmInformationButtonPath = nudgePreferences?.optionalFeatures?.umadFeatures?.mdmInformationButtonPath ??  "https://github.com/macadmins/umad"
let mdmProfileIdentifier = nudgePreferences?.optionalFeatures?.umadFeatures?.mdmProfileIdentifier ?? "com.example.mdm.profile"
let mdmRequiredInstallationDate = nudgePreferences?.optionalFeatures?.umadFeatures?.mdmRequiredInstallationDate ?? Date(timeIntervalSince1970: 0)
let uamdmScreenShotPath = nudgePreferences?.optionalFeatures?.umadFeatures?.uamdmScreenShotPath ?? ""

// osVersionRequirements
// This is in a list that could expand so we need to treat it differently
let majorUpgradeAppPath = getOSVersionRequirements()?.majorUpgradeAppPath ?? ""
let requiredInstallationDate = getOSVersionRequirements()?.requiredInstallationDate ?? Date(timeIntervalSince1970: 0)
let requiredMinimumOSVersion = getOSVersionRequirements()?.requiredMinimumOSVersion ?? "0.0"
let aboutUpdateURL = getOSVersionRequirements()?.aboutUpdateURL ?? "https://support.apple.com/en-us/HT201541"
func getOSVersionRequirements() -> OSVersionRequirement? {
    let requirements = nudgePreferences?.osVersionRequirements
    if requirements != nil {
        for (_ , subPreferences) in requirements!.enumerated() {
            if subPreferences.targetedOSVersions?.contains(OSVersion(ProcessInfo().operatingSystemVersion).description) == true {
                return subPreferences
            }
        }
    }
    return nil
}

// userExperience
let allowedDeferrals = nudgePreferences?.userExperience?.allowedDeferrals ?? 1000000
let allowedDeferralsUntilForcedSecondaryQuitButton = nudgePreferences?.userExperience?.allowedDeferralsUntilForcedSecondaryQuitButton ?? 14
let approachingRefreshCycle = nudgePreferences?.userExperience?.approachingRefreshCycle ?? 6000
let approachingWindowTime = nudgePreferences?.userExperience?.approachingWindowTime ?? 72
let elapsedRefreshCycle = nudgePreferences?.userExperience?.elapsedRefreshCycle ?? 300
let imminentRefreshCycle = nudgePreferences?.userExperience?.imminentRefeshCycle ?? 600
let imminentWindowTime = nudgePreferences?.userExperience?.imminentWindowTime ?? 24
let initialRefreshCycle = nudgePreferences?.userExperience?.initialRefreshCycle ?? 18000
let maxRandomDelayInSeconds = nudgePreferences?.userExperience?.maxRandomDelayInSeconds ?? 1200
let noTimers = nudgePreferences?.userExperience?.noTimers ?? false
let nudgeRefreshCycle = nudgePreferences?.userExperience?.nudgeRefreshCycle ?? 60
let randomDelay = nudgePreferences?.userExperience?.randomDelay ?? false

// userInterface
let language = NSLocale.current.languageCode!
func getuserInterface() -> Element? {
    let updateElements = nudgePreferences?.userInterface?.updateElements
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences.language == language {
                return subPreferences
            }
        }
    }
    return nil
}
let actionButtonText = getuserInterface()?.actionButtonText ?? "Update Device"
func getMainHeader() -> String {
    if Utils().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else {
        return getuserInterface()?.mainHeader ?? "Your device requires a security update"
    }
}
func forceScreenShotIconMode() -> Bool {
    if Utils().forceScreenShotIconModeEnabled() {
        return true
    } else {
        return nudgePreferences?.userInterface?.forceScreenShotIcon ?? false
    }
}
let iconDarkPath = nudgePreferences?.userInterface?.iconDarkPath ?? ""
let iconLightPath = nudgePreferences?.userInterface?.iconLightPath ?? ""
let informationButtonText = getuserInterface()?.informationButtonText ?? "More Info"
let mainContentHeader = getuserInterface()?.mainContentHeader ?? "Your device will restart during this update"
let mainContentNote = getuserInterface()?.mainContentNote ?? "Important Notes"
let mainContentSubHeader = getuserInterface()?.mainContentSubHeader ?? "Updates can take around 30 minutes to complete"
let mainContentText = getuserInterface()?.mainContentText ?? "A fully up-to-date device is required to ensure that IT can your accurately protect your device. \n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks. \n\nTo begin the update, simply click on the Update Device button and follow the provided steps."
let primaryQuitButtonText = getuserInterface()?.primaryQuitButtonText ?? "Later"
let screenShotDarkPath = nudgePreferences?.userInterface?.screenShotDarkPath ?? ""
let screenShotLightPath = nudgePreferences?.userInterface?.screenShotLightPath ?? ""
let secondaryQuitButtonText = getuserInterface()?.secondaryQuitButtonText ?? "I understand"
func simpleMode() -> Bool {
    if Utils().simpleModeEnabled() {
        return true
    } else {
        return nudgePreferences?.userInterface?.simpleMode ?? false
    }
}
let subHeader = getuserInterface()?.subHeader ?? "A friendly reminder from your local IT team"

// userInterface - MDM
func getMDMUserInterface() -> Element? {
    let updateElements = nudgePreferences?.userInterface?.umadElements
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences.language == language {
                return subPreferences
            }
        }
    }
    return nil
}
let mdmActionButtonManualText = getMDMUserInterface()?.actionButtonManualText ?? "Manually Enroll"
let mdmActionButtonText = getMDMUserInterface()?.actionButtonText ?? ""
let mdmActionButtonUAMDMText = getMDMUserInterface()?.actionButtonUAMDMText ?? "Open System Preferences"
let mdmInformationButtonText = getMDMUserInterface()?.informationButtonText ?? "More Info"
let mdmMainContentHeader = getMDMUserInterface()?.mainContentHeader ?? "This process does not require a restart"
let mdmMainContentNote = getMDMUserInterface()?.mainContentNote ?? "Important Notes"
let mdmMainContentText = getMDMUserInterface()?.mainContentText ?? "Enrollment into MDM is required to ensure that IT can protect your computer with basic security necessities like encryption and threat detection.\n\nIf you do not enroll into MDM you may lose access to some items necessary for your day-to-day tasks.\n\nTo enroll, just look for the below notification, and click Details. Once prompted, log in with your username and password."
let mdmMainContentUAMDMText = getMDMUserInterface()?.mainContentUAMDMText ?? "Thank you for enrolling your device into MDM. We sincerely appreciate you doing this in a timely manner.\n\nUnfortunately, your device has been detected as only partially enrolled into our system.\n\nPlease go to System Preferences -> Profiles, click on the Device Enrollment profile and click on the approve button."
let mdmMainHeader = getMDMUserInterface()?.mainHeader ?? "Your device requires management"
let mdmPrimaryQuitButtonText = getMDMUserInterface()?.primaryQuitButtonText ?? "Later"
let mdmSecondaryQuitButtonText = getMDMUserInterface()?.secondaryQuitButtonText ?? "I understand"
let mdmSubHeader = getMDMUserInterface()?.subHeader ?? "A friendly reminder from your local IT team"

// Other important defaults
let acceptableApps = [
    "com.apple.loginwindow",
    "com.apple.systempreferences"
]
