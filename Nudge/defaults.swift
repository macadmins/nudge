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
let allowedDeferrals = nudgePreferences?.optionalFeatures?.allowedDeferrals ?? 1000000
let allowedDeferralsUntilForcedSecondaryQuitButton = nudgePreferences?.optionalFeatures?.allowedDeferralsUntilForcedSecondaryQuitButton ?? 14
let attemptToFetchMajorUpgrade = nudgePreferences?.optionalFeatures?.attemptToFetchMajorUpgrade ?? false
let enforceMinorUpdates = nudgePreferences?.optionalFeatures?.enforceMinorUpdates ?? true
let iconDarkPath = nudgePreferences?.optionalFeatures?.iconDarkPath ?? ""
let iconLightPath = nudgePreferences?.optionalFeatures?.iconLightPath ?? ""
let maxRandomDelayInSeconds = nudgePreferences?.optionalFeatures?.maxRandomDelayInSeconds ?? 1200
let noTimers = nudgePreferences?.optionalFeatures?.noTimers ?? false
let randomDelay = nudgePreferences?.optionalFeatures?.randomDelay ?? false
let screenShotDarkPath = nudgePreferences?.optionalFeatures?.screenShotDarkPath ?? ""
let screenShotLightPath = nudgePreferences?.optionalFeatures?.screenShotLightPath ?? ""
let simpleMode = nudgePreferences?.optionalFeatures?.simpleMode ?? false

// optionalFeatures - MDM
let alwaysShowManualEnrllment = nudgePreferences?.optionalFeatures?.mdmFeatures?.alwaysShowManulEnrollment ?? false
let depScreenShotPath = nudgePreferences?.optionalFeatures?.mdmFeatures?.depScreenShotPath ?? ""
let disableManualEnrollmentForDEP = nudgePreferences?.optionalFeatures?.mdmFeatures?.disableManualEnrollmentForDEP ?? false
let enforceMDMInstallation = nudgePreferences?.optionalFeatures?.mdmFeatures?.enforceMDMInstallation ?? false
let mdmInformationButtonPath = nudgePreferences?.optionalFeatures?.mdmFeatures?.mdmInformationButtonPath ??  "https://github.com/macadmins/umage"
let manulEnrollmentPath = nudgePreferences?.optionalFeatures?.mdmFeatures?.manualEnrollmentPath ?? "https://apple.com"
let mdmProfileIdentifier = nudgePreferences?.optionalFeatures?.mdmFeatures?.mdmProfileIdentifier ?? "com.example.mdm.profile"
let mdmRequiredInstallationDate = nudgePreferences?.optionalFeatures?.mdmFeatures?.mdmRequiredInstallationDate ?? Date(timeIntervalSince1970: 0)
let uamdmScreenShotPath = nudgePreferences?.optionalFeatures?.mdmFeatures?.uamdmScreenShotPath ?? ""

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
let approachingRefreshCycle = nudgePreferences?.userExperience?.approachingRefreshCycle ?? 6000
let approachingWindowTime = nudgePreferences?.userExperience?.approachingWindowTime ?? 72
let elapsedRefreshCycle = nudgePreferences?.userExperience?.elapsedRefreshCycle ?? 300
let imminentRefreshCycle = nudgePreferences?.userExperience?.imminentRefeshCycle ?? 600
let imminentWindowTime = nudgePreferences?.userExperience?.imminentWindowTime ?? 24
let initialRefreshCycle = nudgePreferences?.userExperience?.initialRefreshCycle ?? 18000
let nudgeRefreshCycle = nudgePreferences?.userExperience?.nudgeRefreshCycle ?? 60

// userInterface
let actionButtonText = nudgePreferences?.userInterface?.updateElements?.actionButtonText ?? "Update Device"
func getMainHeader() -> String {
    if Utils().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else {
        return nudgePreferences?.userInterface?.updateElements?.mainHeader ?? "Your device requires a security update"
    }
}
let informationButtonText = nudgePreferences?.userInterface?.updateElements?.informationButtonText ?? "More Info"
let mainContentHeader = nudgePreferences?.userInterface?.updateElements?.mainContentHeader ?? "Your device will restart during this update"
let mainContentNote = nudgePreferences?.userInterface?.updateElements?.mainContentNote ?? "Important Notes"
let mainContentSubHeader = nudgePreferences?.userInterface?.updateElements?.mainContentSubHeader ?? "Updates can take up to 30 minutes to complete"
let mainContentText = nudgePreferences?.userInterface?.updateElements?.mainContentText ?? "A fully up-to-date device is required to ensure that IT can your accurately protect your device. \n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks. \n\nTo begin the update, simply click on the button below and follow the provided steps."
let primaryQuitButtonText = nudgePreferences?.userInterface?.updateElements?.primaryQuitButtonText ?? "Defer"
let secondaryQuitButtonText = nudgePreferences?.userInterface?.updateElements?.secondaryQuitButtonText ?? "I understand"
let subHeader = nudgePreferences?.userInterface?.updateElements?.subHeader ?? "A friendly reminder from your local IT team"

// userInterface - MDM
let mdmActionButtonManualText = nudgePreferences?.userInterface?.mdmElements?.actionButtonManualText ?? "Manually Enroll"
let mdmActionButtonUAMDMText = nudgePreferences?.userInterface?.mdmElements?.actionButtonUAMDMText ?? "Open System Preferences"
let mdmActionButtonText = nudgePreferences?.userInterface?.mdmElements?.actionButtonText ?? ""
let mdmInformationButtonText = nudgePreferences?.userInterface?.mdmElements?.informationButtonText ?? "More Info"
let mdmLowerHeader = nudgePreferences?.userInterface?.mdmElements?.lowerHeader ?? "Ready to enroll?"
let mdmLowerHeaderDEPFailure = nudgePreferences?.userInterface?.mdmElements?.lowerHeaderDEPFailure ?? "Manual enrollment required"
let mdmLowerHeaderUAMDMFailure = nudgePreferences?.userInterface?.mdmElements?.lowerHeaderUAMDMFailure ?? "Manual intervention required"
let mdmLowerSubHeader = nudgePreferences?.userInterface?.mdmElements?.lowerSubHeader ?? ""
let mdmLowerSubHeaderDEPFailure = nudgePreferences?.userInterface?.mdmElements?.lowerSubHeaderDEPFailure ?? "You can also enroll manually below"
let mdmLowerSubHeaderManual = nudgePreferences?.userInterface?.mdmElements?.lowerSubHeaderManual ?? "Click on the Manually Enroll button below."
let mdmLowerSubHeaderUAMDMFailure = nudgePreferences?.userInterface?.mdmElements?.lowerSubHeaderUAMDMFailure ?? "Open System Preferences and approve Device Management."
let mdmMainContentHeader = nudgePreferences?.userInterface?.mdmElements?.mainContentHeader ?? "MDM Enrollment is required (No Restart Required)"
let mdmMainContentText = nudgePreferences?.userInterface?.mdmElements?.mainContentText ?? "Enrollment into MDM is required to ensure that IT can protect your computer with basic security necessities like encryption and threat detection.\n\nIf you do not enroll into MDM you may lose access to some items necessary for your day-to-day tasks.\n\nTo enroll, just look for the below notification, and click Details. Once prompted, log in with your username and password."
let mdmMainContentUAMDMText = nudgePreferences?.userInterface?.mdmElements?.mainContentUAMDMText ?? "Thank you for enrolling your device into MDM. We sincerely appreciate you doing this in a timely manner.\n\nUnfortunately, your device has been detected as only partially enrolled into our system.\n\nPlease go to System Preferences -> Profiles, click on the Device Enrollment profile and click on the approve button."
let mdmMainHeader = nudgePreferences?.userInterface?.mdmElements?.mainHeader ?? "MDM Enrollment"
let mdmPrimaryQuitButtonText = nudgePreferences?.userInterface?.mdmElements?.primaryQuitButtonText ?? "Okay"
let mdmSecondaryQuitButtonText = nudgePreferences?.userInterface?.mdmElements?.secondaryQuitButtonText ?? "I understand"
let mdmSubHeader = nudgePreferences?.userInterface?.mdmElements?.subHeader ?? "A friendly reminder from your local IT team"

// Other important defaults
let acceptableApps = [
    "com.apple.loginwindow",
    "com.apple.systempreferences"
]
