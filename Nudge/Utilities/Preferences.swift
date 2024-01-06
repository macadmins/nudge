//
//  Preferences.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

// TODO: Finish refactor
import Foundation

// Generics
func getDesiredLanguage(locale: Locale? = nil) -> String {
    var desiredLanguage = languageID
    if isPreview {
        if locale?.identifier != nil {
            desiredLanguage = locale!.identifier
        }
    } else {
        desiredLanguage = languageCode
    }
    if UserInterfaceVariables.forceFallbackLanguage {
        desiredLanguage = UserInterfaceVariables.fallbackLanguage
    }
    return desiredLanguage
}

// optionalFeatures
// Even if profile/JSON is installed, return nil if in demo-mode
func getOptionalFeaturesJSON() -> OptionalFeatures? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let optionalFeatures = nudgeJSONPreferences?.optionalFeatures {
        return optionalFeatures
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON optionalFeatures key is empty", privacy: .public)")
    }
    return nil
}

func getOptionalFeaturesProfile() -> [String:Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let optionalFeatures = nudgeDefaults.dictionary(forKey: "optionalFeatures") {
        return optionalFeatures
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile optionalFeatures key is empty", privacy: .public)")
    }
    return nil
}

// osVersionRequirements
// Loop through osVersionRequirements preferences and then compare currentOS against targetedOSVersions
// Mutates the profile into our required construct and then compare currentOS against targetedOSVersions
// Even if profile/JSON is installed, return nil if in demo-mode
func getAboutUpdateURL(OSVerReq: OSVersionRequirement?) -> String? {
    // Compare current language against the available updateURLs
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
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

func getOSVersionRequirementsJSON() -> OSVersionRequirement? {
    var fullMatch = OSVersionRequirement()
    var partialMatch = OSVersionRequirement()
    var defaultMatch = OSVersionRequirement()
    var defaultMatchSet = false
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let requirements = nudgeJSONPreferences?.osVersionRequirements {
        for (_ , subPreferences) in requirements.enumerated() {
            if subPreferences.targetedOSVersionsRule == GlobalVariables.currentOSVersion {
                fullMatch = subPreferences
                // TODO: For some reason, Utils().getMajorOSVersion() triggers a crash, so I am directly calling ProcessInfo()
            } else if subPreferences.targetedOSVersionsRule == String(ProcessInfo().operatingSystemVersion.majorVersion) {
                partialMatch = subPreferences
            } else if subPreferences.targetedOSVersionsRule == "default" {
                defaultMatch = subPreferences
                defaultMatchSet = true
            } else if subPreferences.targetedOSVersionsRule == nil && !(defaultMatchSet) {
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

func getOSVersionRequirementsProfile() -> OSVersionRequirement? {
    var fullMatch = OSVersionRequirement()
    var partialMatch = OSVersionRequirement()
    var defaultMatch = OSVersionRequirement()
    var defaultMatchSet = false
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
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
            if subPreferences.targetedOSVersionsRule == GlobalVariables.currentOSVersion {
                fullMatch = subPreferences
                // TODO: For some reason, Utils().getMajorOSVersion() triggers a crash, so I am directly calling ProcessInfo()
            } else if subPreferences.targetedOSVersionsRule == String(ProcessInfo().operatingSystemVersion.majorVersion) {
                partialMatch = subPreferences
            } else if subPreferences.targetedOSVersionsRule == "default" {
                defaultMatch = subPreferences
                defaultMatchSet = true
            } else if !(defaultMatchSet) {
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

// userExperience
// Even if profile/JSON is installed, return nil if in demo-mode
func getUserExperienceJSON() -> UserExperience? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let userExperience = nudgeJSONPreferences?.userExperience {
        return userExperience
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON userExperience key is empty", privacy: .public)")
    }
    return nil
}

func getUserExperienceProfile() -> [String:Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let userExperience = nudgeDefaults.dictionary(forKey: "userExperience") {
        return userExperience
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile userExperience key is empty", privacy: .public)")
    }
    return nil
}


// userInterface
// Even if profile/JSON is installed, return nil if in demo-mode
func forceScreenShotIconMode() -> Bool {
    if CommandLineUtilities().forceScreenShotIconModeEnabled() {
        return true
    } else {
        return UserInterfaceVariables.userInterfaceProfile?["forceScreenShotIcon"] as? Bool ?? nudgeJSONPreferences?.userInterface?.forceScreenShotIcon ?? false
    }
}

func getUserInterfaceJSON() -> UserInterface? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let userInterface = nudgeJSONPreferences?.userInterface {
        return userInterface
    } else if !nudgeLogState.afterFirstLaunch {
        prefsJSONLog.info("\("JSON userInterface key is empty", privacy: .public)")
    }
    return nil
}

func getUserInterfaceProfile() -> [String:Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    if let userInterface = nudgeDefaults.dictionary(forKey: "userInterface") {
        return userInterface
    } else if !nudgeLogState.afterFirstLaunch {
        prefsProfileLog.info("\("Profile userInterface key is empty", privacy: .public)")
    }
    return nil
}

// Loop through JSON userInterface -> updateElements preferences and then compare language
func getUserInterfaceUpdateElementsJSON() -> UpdateElement? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
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

// Mutate the profile into our required construct
func getUserInterfaceUpdateElementsProfile() -> [String:AnyObject]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return nil
    }
    let updateElements = UserInterfaceVariables.userInterfaceProfile?["updateElements"] as? [[String:AnyObject]]
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

// Returns the mainHeader
func getMainHeader() -> String {
    if CommandLineUtilities().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else if CommandLineUtilities().unitTestingEnabled() {
        return "Your device requires a security update (Unit Testing Mode)"
    } else {
        return UserInterfaceVariables.userInterfaceUpdateElementsProfile?["mainHeader"] as? String ?? getUserInterfaceUpdateElementsJSON()?.mainHeader ?? "Your device requires a security update"
    }
}

func simpleMode() -> Bool {
    if CommandLineUtilities().simpleModeEnabled() {
        return true
    } else {
        return UserInterfaceVariables.userInterfaceProfile?["simpleMode"] as? Bool ?? nudgeJSONPreferences?.userInterface?.simpleMode ?? false
    }
}
