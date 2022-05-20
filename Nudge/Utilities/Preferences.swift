//
//  Preferences.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation

let nudgeJSONPreferences = Utils().getNudgeJSONPreferences()
let nudgeDefaults = UserDefaults.standard
let language = NSLocale.current.languageCode!
var nudgePrimaryState = ViewState()
var nudgeLogState = LogState()

// Get the language
func getDesiredLanguage() -> String {
    var desiredLanguage = language
    if forceFallbackLanguage {
        desiredLanguage = fallbackLanguage
    }
    return desiredLanguage
}

// optionalFeatures
// Even if profile/JSON is installed, return nil if in demo-mode
func getOptionalFeaturesProfile() -> [String:Any]? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let optionalFeatures = nudgeDefaults.dictionary(forKey: "optionalFeatures") {
        return optionalFeatures
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile optionalFeatures key is empty", privacy: .public)")
    }
    return nil
}

func getOptionalFeaturesJSON() -> OptionalFeatures? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let optionalFeatures = nudgeJSONPreferences?.optionalFeatures {
        return optionalFeatures
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON optionalFeatures key is empty", privacy: .public)")
    }
    return nil
}

// osVersionRequirements
// Mutate the profile into our required construct and then compare currentOS against targetedOSVersions
// Even if profile/JSON is installed, return nil if in demo-mode
func getOSVersionRequirementsProfile() -> OSVersionRequirement? {
    var fullMatch = OSVersionRequirement()
    var partialMatch = OSVersionRequirement()
    var defaultMatch = OSVersionRequirement()
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    var requirements = [OSVersionRequirement]()
    if let osRequirements = nudgeDefaults.array(forKey: "osVersionRequirements") as? [[String:AnyObject]] {
        for item in osRequirements {
            requirements.append(OSVersionRequirement(fromDictionary: item))
        }
    }
    if !requirements.isEmpty {
        for (_ , subPreferences) in requirements.enumerated() {
            if subPreferences.targetedOSVersionsRule == currentOSVersion {
                fullMatch = subPreferences
            // TODO: For some reason, Utils().getMajorOSVersion() triggers a crash, so I am directly calling ProcessInfo()
            } else if subPreferences.targetedOSVersionsRule == String(ProcessInfo().operatingSystemVersion.majorVersion) {
                partialMatch = subPreferences
            } else if subPreferences.targetedOSVersionsRule == "default" {
                defaultMatch = subPreferences
            } else {
                defaultMatch = subPreferences
            }
        }
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile osVersionRequirements key is empty", privacy: .public)")
    }
    if fullMatch.requiredMinimumOSVersion != nil {
        return fullMatch
    } else if partialMatch.requiredMinimumOSVersion != nil {
        return partialMatch
    } else if defaultMatch.requiredMinimumOSVersion != nil {
        return defaultMatch
    }
    return nil
}
// Loop through JSON osVersionRequirements preferences and then compare currentOS against targetedOSVersions
func getOSVersionRequirementsJSON() -> OSVersionRequirement? {
    var fullMatch = OSVersionRequirement()
    var partialMatch = OSVersionRequirement()
    var defaultMatch = OSVersionRequirement()
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let requirements = nudgeJSONPreferences?.osVersionRequirements {
        for (_ , subPreferences) in requirements.enumerated() {
            if subPreferences.targetedOSVersionsRule == currentOSVersion {
                fullMatch = subPreferences
            // TODO: For some reason, Utils().getMajorOSVersion() triggers a crash, so I am directly calling ProcessInfo()
            } else if subPreferences.targetedOSVersionsRule == String(ProcessInfo().operatingSystemVersion.majorVersion) {
                partialMatch = subPreferences
            } else if subPreferences.targetedOSVersionsRule == "default" {
                defaultMatch = subPreferences
            } else if subPreferences.targetedOSVersionsRule == nil {
                defaultMatch = subPreferences
            }
        }
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON osVersionRequirements key is empty", privacy: .public)")
    }
    if fullMatch.requiredMinimumOSVersion != nil {
        return fullMatch
    } else if partialMatch.requiredMinimumOSVersion != nil {
        return partialMatch
    } else if defaultMatch.requiredMinimumOSVersion != nil {
        return defaultMatch
    }
    return nil
}

// Compare current language against the available updateURLs
func getAboutUpdateURL(OSVerReq: OSVersionRequirement?) -> String? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return "https://apple.com"
    }
    if let update = OSVerReq?.aboutUpdateURL {
        return update
    }
    if let updates = OSVerReq?.aboutUpdateURLs {
        for (_, subUpdates) in updates.enumerated() {
            if subUpdates.language == getDesiredLanguage() {
                return subUpdates.aboutUpdateURL ?? ""
            }
        }
    }
    return nil
}

// userExperience
// Even if profile/JSON is installed, return nil if in demo-mode
func getUserExperienceProfile() -> [String:Any]? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let userExperience = nudgeDefaults.dictionary(forKey: "userExperience") {
        return userExperience
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile userExperience key is empty", privacy: .public)")
    }
    return nil
}

func getUserExperienceJSON() -> UserExperience? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let userExperience = nudgeJSONPreferences?.userExperience {
        return userExperience
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON userExperience key is empty", privacy: .public)")
    }
    return nil
}


// userInterface
// Even if profile/JSON is installed, return nil if in demo-mode
func getUserInterfaceProfile() -> [String:Any]? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let userInterface = nudgeDefaults.dictionary(forKey: "userInterface") {
        return userInterface
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile userInterface key is empty", privacy: .public)")
    }
    return nil
}

func getUserInterfaceJSON() -> UserInterface? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    if let userInterface = nudgeJSONPreferences?.userInterface {
        return userInterface
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON userInterface key is empty", privacy: .public)")
    }
    return nil
}

func forceScreenShotIconMode() -> Bool {
    if Utils().forceScreenShotIconModeEnabled() {
        return true
    } else {
        return userInterfaceProfile?["forceScreenShotIcon"] as? Bool ?? nudgeJSONPreferences?.userInterface?.forceScreenShotIcon ?? false
    }
}

func simpleMode() -> Bool {
    if Utils().simpleModeEnabled() {
        return true
    } else {
        return userInterfaceProfile?["simpleMode"] as? Bool ?? nudgeJSONPreferences?.userInterface?.simpleMode ?? false
    }
}

// Mutate the profile into our required construct
// Even if profile/JSON is installed, return nil if in demo-mode
func getUserInterfaceUpdateElementsProfile() -> [String:AnyObject]? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    let updateElements = userInterfaceProfile?["updateElements"] as? [[String:AnyObject]]
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences["_language"] as? String == getDesiredLanguage() {
                return subPreferences
            }
        }
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile updateElements key is empty", privacy: .public)")
    }
    return nil
}

// Loop through JSON userInterface -> updateElements preferences and then compare language
func getUserInterfaceUpdateElementsJSON() -> UpdateElement? {
    if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
        return nil
    }
    let updateElements = getUserInterfaceJSON()?.updateElements
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences.language == getDesiredLanguage() {
                return subPreferences
            }
        }
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON updateElements key is empty", privacy: .public)")
    }
    return nil
}

// Returns the mainHeader
func getMainHeader() -> String {
    if Utils().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)".localized(desiredLanguage: getDesiredLanguage())
    } else if Utils().unitTestingEnabled() {
        return "Your device requires a security update (Unit Testing Mode)".localized(desiredLanguage: getDesiredLanguage())
    } else {
        return userInterfaceUpdateElementsProfile?["mainHeader"] as? String ?? getUserInterfaceUpdateElementsJSON()?.mainHeader ?? "Your device requires a security update".localized(desiredLanguage: getDesiredLanguage())
    }
}
