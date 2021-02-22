//
//  DefaultPreferencesNudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/8/21.
//

import Foundation

// optionalFeatures
let optionalFeaturesProfile = getOptionalFeaturesProfile()
let asyncronousSoftwareUpdate = optionalFeaturesProfile?["asyncronousSoftwareUpdate"] as? Bool ?? nudgeJSONPreferences?.optionalFeatures?.asyncronousSoftwareUpdate ?? true
let attemptToFetchMajorUpgrade = optionalFeaturesProfile?["attemptToFetchMajorUpgrade"] as? Bool ?? nudgeJSONPreferences?.optionalFeatures?.attemptToFetchMajorUpgrade ?? false
let enforceMinorUpdates = optionalFeaturesProfile?["enforceMinorUpdates"] as? Bool ?? nudgeJSONPreferences?.optionalFeatures?.enforceMinorUpdates ?? true

// osVersionRequirements
let majorUpgradeAppPath = getOSVersionRequirementsProfile()?.majorUpgradeAppPath ?? getOSVersionRequirementsJSON()?.majorUpgradeAppPath ?? ""
let requiredInstallationDate = getOSVersionRequirementsProfile()?.requiredInstallationDate ?? getOSVersionRequirementsJSON()?.requiredInstallationDate ?? Date(timeIntervalSince1970: 0)
let requiredMinimumOSVersion = getOSVersionRequirementsProfile()?.requiredMinimumOSVersion ?? getOSVersionRequirementsJSON()?.requiredMinimumOSVersion ?? "0.0"
let aboutUpdateURL = getUpdateURL() ?? ""

// userExperience
let userExperienceProfile = nudgeDefaults.dictionary(forKey: "userExperience")
let allowedDeferrals = userExperienceProfile?["allowedDeferrals"] as? Int ?? nudgeJSONPreferences?.userExperience?.allowedDeferrals ?? 1000000
let allowedDeferralsUntilForcedSecondaryQuitButton = userExperienceProfile?["allowedDeferralsUntilForcedSecondaryQuitButton"] as? Int ?? nudgeJSONPreferences?.userExperience?.allowedDeferralsUntilForcedSecondaryQuitButton ?? 14
let approachingRefreshCycle = userExperienceProfile?["approachingRefreshCycle"] as? Int ?? nudgeJSONPreferences?.userExperience?.approachingRefreshCycle ?? 6000
let approachingWindowTime = userExperienceProfile?["approachingWindowTime"] as? Int ?? nudgeJSONPreferences?.userExperience?.approachingWindowTime ?? 72
let elapsedRefreshCycle = userExperienceProfile?["elapsedRefreshCycle"] as? Int ?? nudgeJSONPreferences?.userExperience?.elapsedRefreshCycle ?? 300
let imminentRefreshCycle = userExperienceProfile?["imminentRefreshCycle"] as? Int ?? nudgeJSONPreferences?.userExperience?.imminentRefeshCycle ?? 600
let imminentWindowTime = userExperienceProfile?["imminentWindowTime"] as? Int ?? nudgeJSONPreferences?.userExperience?.imminentWindowTime ?? 24
let initialRefreshCycle = userExperienceProfile?["initialRefreshCycle"] as? Int ?? nudgeJSONPreferences?.userExperience?.initialRefreshCycle ?? 18000
let maxRandomDelayInSeconds = userExperienceProfile?["maxRandomDelayInSeconds"] as? Int ?? nudgeJSONPreferences?.userExperience?.maxRandomDelayInSeconds ?? 1200
let noTimers = userExperienceProfile?["noTimers"] as? Bool ?? nudgeJSONPreferences?.userExperience?.noTimers ?? false
let nudgeRefreshCycle = userExperienceProfile?["nudgeRefreshCycle"] as? Int ?? nudgeJSONPreferences?.userExperience?.nudgeRefreshCycle ?? 60
let randomDelay = userExperienceProfile?["randomDelay"] as? Bool ?? nudgeJSONPreferences?.userExperience?.randomDelay ?? false

// userInterface
let userInterfaceProfile = getUserInterfaceProfile()
let fallbackLanguage = userInterfaceProfile?["fallbackLanguage"] as? String ?? nudgeJSONPreferences?.userInterface?.fallbackLanguage ?? "en"
let forceFallbackLanguage = userInterfaceProfile?["forceFallbackLanguage"] as? Bool ?? nudgeJSONPreferences?.userInterface?.forceFallbackLanguage ?? false
let iconDarkPath = userInterfaceProfile?["iconDarkPath"] as? String ?? nudgeJSONPreferences?.userInterface?.iconDarkPath ?? ""
let iconLightPath = userInterfaceProfile?["iconLightPath"] as? String ?? nudgeJSONPreferences?.userInterface?.iconLightPath ?? ""
let screenShotDarkPath = userInterfaceProfile?["screenShotDarkPath"] as? String ?? nudgeJSONPreferences?.userInterface?.screenShotDarkPath ?? ""
let screenShotLightPath = userInterfaceProfile?["screenShotLightPath"] as? String ?? nudgeJSONPreferences?.userInterface?.screenShotLightPath ?? ""
let actionButtonText = getUserInterfaceUpdateElementsProfile()?["actionButtonText"] as? String ?? getUserInterfaceJSON()?.actionButtonText ?? "Update Device".localized(desiredLanguage: getDesiredLanguage())
let informationButtonText = getUserInterfaceUpdateElementsProfile()?["informationButtonText"] as? String ?? getUserInterfaceJSON()?.informationButtonText ?? "More Info".localized(desiredLanguage: getDesiredLanguage())
let mainContentHeader = getUserInterfaceUpdateElementsProfile()?["mainContentHeader"] as? String ?? getUserInterfaceJSON()?.mainContentHeader ?? "Your device will restart during this update".localized(desiredLanguage: getDesiredLanguage())
let mainContentNote = getUserInterfaceUpdateElementsProfile()?["mainContentNote"] as? String ?? getUserInterfaceJSON()?.mainContentNote ?? "Important Notes".localized(desiredLanguage: getDesiredLanguage())
let mainContentSubHeader = getUserInterfaceUpdateElementsProfile()?["mainContentSubHeader"] as? String ?? getUserInterfaceJSON()?.mainContentSubHeader ?? "Updates can take around 30 minutes to complete".localized(desiredLanguage: getDesiredLanguage())
let mainContentText = getUserInterfaceUpdateElementsProfile()?["mainContentText"] as? String ?? getUserInterfaceJSON()?.mainContentText ?? "A fully up-to-date device is required to ensure that IT can accurately protect your device.\n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks.\n\nTo begin the update, simply click on the Update Device button and follow the provided steps.".localized(desiredLanguage: getDesiredLanguage())
let primaryQuitButtonText = getUserInterfaceUpdateElementsProfile()?["primaryQuitButtonText"] as? String ?? getUserInterfaceJSON()?.primaryQuitButtonText ?? "Later".localized(desiredLanguage: getDesiredLanguage())
let secondaryQuitButtonText = getUserInterfaceUpdateElementsProfile()?["secondaryQuitButtonText"] as? String ?? getUserInterfaceJSON()?.secondaryQuitButtonText ?? "I understand".localized(desiredLanguage: getDesiredLanguage())
let subHeader = getUserInterfaceUpdateElementsProfile()?["subHeader"] as? String ?? getUserInterfaceJSON()?.subHeader ?? "A friendly reminder from your local IT team".localized(desiredLanguage: getDesiredLanguage())

// Other important defaults
let acceptableApps = [
    "com.apple.loginwindow",
    "com.apple.systempreferences"
]
