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
var shouldExit = false

// optionalFeatures
// Even if profile is installed, return nil if in demo-mode
func getOptionalFeaturesProfile() -> [String:Any]? {
    if Utils().demoModeEnabled() {
        return nil
    } else {
        return nudgeDefaults.dictionary(forKey: "optionalFeatures")
    }
}

// osVersionRequirements
// Mutate the profile into our required construct and then compare currentOS against targetedOSVersions
func getOSVersionRequirementsProfile() -> OSVersionRequirement? {
    if Utils().demoModeEnabled() {
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
            if subPreferences.targetedOSVersions?.contains(OSVersion(ProcessInfo().operatingSystemVersion).description) == true {
                return subPreferences
            }
        }
    }
    return nil
}
// Loop through JSON osVersionRequirements preferences and then compare currentOS against targetedOSVersions
func getOSVersionRequirementsJSON() -> OSVersionRequirement? {
    if Utils().demoModeEnabled() {
        return nil
    }
    if let requirements = nudgeJSONPreferences?.osVersionRequirements {
        for (_ , subPreferences) in requirements.enumerated() {
            if subPreferences.targetedOSVersions?.contains(OSVersion(ProcessInfo().operatingSystemVersion).description) == true {
                return subPreferences
            }
        }
    }
    return nil
}

// Compare current language against the available updateURLs
func getUpdateURL() -> String? {
    if Utils().demoModeEnabled() {
        return "https://support.apple.com/en-us/HT201541"
    }
    var desiredLanguage = language
    if forceFallbackLanguage {
        desiredLanguage = fallbackLanguage
    }
    if let updates = getOSVersionRequirementsProfile()?.aboutUpdateURLs ?? getOSVersionRequirementsJSON()?.aboutUpdateURLs {
        for (_, subUpdates) in updates.enumerated() {
            if subUpdates.language == desiredLanguage {
                return subUpdates.aboutUpdateURL ?? ""
            }
        }
    }
    return ""
}


// userInterface
func getUserInterfaceProfile() -> [String:Any]? {
    if Utils().demoModeEnabled() {
        return nil
    } else {
        return nudgeDefaults.dictionary(forKey: "userInterface")
    }
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
func getUserInterfaceUpdateElementsProfile() -> [String:AnyObject]? {
    if Utils().demoModeEnabled() {
        return nil
    }
    var desiredLanguage = language
    if forceFallbackLanguage {
        desiredLanguage = fallbackLanguage
    }
    let updateElements = userInterfaceProfile?["updateElements"] as? [[String:AnyObject]]
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences["_language"] as? String == desiredLanguage {
                return subPreferences
            }
        }
    }
    return nil
}

// Loop through JSON userInterface -> updateElements preferences and then compare language
func getUserInterfaceJSON() -> UpdateElement? {
    if Utils().demoModeEnabled() {
        return nil
    }
    var desiredLanguage = language
    if forceFallbackLanguage {
        desiredLanguage = fallbackLanguage
    }
    let updateElements = nudgeJSONPreferences?.userInterface?.updateElements
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences.language == desiredLanguage {
                return subPreferences
            }
        }
    }
    return nil
}

// Returns the mainHeader
func getMainHeader() -> String {
    if Utils().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else {
        return getUserInterfaceUpdateElementsProfile()?["mainHeader"] as? String ?? getUserInterfaceJSON()?.mainHeader ?? "Your device requires a security update"
    }
}
