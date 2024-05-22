//
//  Preferences.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation

// Generics
func getDesiredLanguage(locale: Locale? = nil) -> String {
    if UserInterfaceVariables.forceFallbackLanguage {
        return UserInterfaceVariables.fallbackLanguage
    }

    if uiConstants.isPreview, let previewLocale = locale?.identifier {
        return previewLocale
    }

    return UIConstants.languageCode
}

// optionalFeatures
// Even if profile/JSON is installed, return nil if in demo-mode
func getOptionalFeaturesJSON() -> OptionalFeatures? {
    guard !CommandLineUtilities().demoModeEnabled(),
          !CommandLineUtilities().unitTestingEnabled(),
          let optionalFeatures = Globals.nudgeJSONPreferences?.optionalFeatures else {
        logEmptyKey("optionalFeatures", forJSON: true)
        return nil
    }
    return optionalFeatures
}

func getOptionalFeaturesProfile() -> [String: Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        logEmptyKey("optionalFeatures", forJSON: false)
        return nil
    }

    // Check if the Data is empty
    if Globals.configProfile.isEmpty {
        logEmptyKey("optionalFeatures", forJSON: false)
        return nil
    }

    do {
        // Attempt to decode the plist Data into a dictionary
        if let dictionary = try PropertyListSerialization.propertyList(from: Globals.configProfile, options: [], format: nil) as? [String: Any],
           let optionalFeatures = dictionary["optionalFeatures"] as? [String: Any] {
            return optionalFeatures
        } else {
            logEmptyKey("optionalFeatures", forJSON: false)
            return nil
        }
    } catch {
        print("Failed to decode plist: \(error)")
        return nil
    }
}

private func logEmptyKey(_ key: String, forJSON: Bool) {
    if !nudgeLogState.afterFirstLaunch {
        let log = forJSON ? prefsJSONLog : prefsProfileLog
        let type = forJSON ? "json" : "profile"
        LogManager.info("\(key) key is empty - \(type)", logger: log)
    }
}

// osVersionRequirements
// Loop through osVersionRequirements preferences and then compare currentOS against targetedOSVersions
// Mutates the profile into our required construct and then compare currentOS against targetedOSVersions
// Even if profile/JSON is installed, return nil if in demo-mode
func getAboutUpdateURL(OSVerReq: OSVersionRequirement?) -> String? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return "https://apple.com"
    }

    if let update = OSVerReq?.aboutUpdateURL {
        return update
    }

    let desiredLanguage = getDesiredLanguage()
    if let updates = OSVerReq?.aboutUpdateURLs {
        for subUpdate in updates {
            if subUpdate.language == desiredLanguage {
                return subUpdate.aboutUpdateURL ?? ""
            }
        }
    }

    return nil
}

func getOSVersionRequirementsJSON() -> OSVersionRequirement? {
    guard let osRequirementsArray = Globals.nudgeJSONPreferences?.osVersionRequirements else {
        logEmptyKey("osVersionRequirements", forJSON: true)
        return nil
    }
    return getOSVersionRequirements(from: osRequirementsArray)
}

func getOSVersionRequirementsProfile() -> OSVersionRequirement? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        logEmptyKey("osVersionRequirements", forJSON: false)
        return nil
    }

    // Check if the Data is empty
    if Globals.configProfile.isEmpty {
        logEmptyKey("osVersionRequirements", forJSON: false)
        return nil
    }

    do {
        // Attempt to decode the plist Data into a dictionary
        if let dictionary = try PropertyListSerialization.propertyList(from: Globals.configProfile, options: [], format: nil) as? [String: Any],
           let osVersionRequirements = dictionary["osVersionRequirements"] as? [[String: AnyObject]] {
            let requirements = osVersionRequirements.map { OSVersionRequirement(fromDictionary: $0) }
            return getOSVersionRequirements(from: requirements)
        } else {
            logEmptyKey("osVersionRequirements", forJSON: false)
            return nil
        }
    } catch {
        print("Failed to decode plist: \(error)")
        return nil
    }
}

private func getOSVersionRequirements(from requirements: [OSVersionRequirement]?) -> OSVersionRequirement? {
    guard !CommandLineUtilities().demoModeEnabled(),
          !CommandLineUtilities().unitTestingEnabled(),
          let requirements = requirements else {
        return nil
    }

    var fullMatch: OSVersionRequirement?
    var partialMatch: OSVersionRequirement?
    var defaultMatch: OSVersionRequirement?

    let currentMajorVersion = String(VersionManager.getMajorOSVersion())
    let currentOSVersion = GlobalVariables.currentOSVersion

    for requirement in requirements {
        if requirement.targetedOSVersionsRule == currentOSVersion {
            fullMatch = requirement
            break
        } else if requirement.targetedOSVersionsRule == currentMajorVersion {
            partialMatch = requirement
        } else if requirement.targetedOSVersionsRule == "default" {
            defaultMatch = requirement
        } else if requirement.targetedOSVersionsRule == nil {
            defaultMatch = requirement
        }
    }

    return fullMatch ?? partialMatch ?? defaultMatch ?? nil
}

func getUnsupportedURL(OSVerReq: OSVersionRequirement?) -> String? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        return "https://apple.com"
    }

    if let update = OSVerReq?.unsupportedURL {
        return update
    }

    let desiredLanguage = getDesiredLanguage()
    if let updates = OSVerReq?.unsupportedURLs {
        for subUpdate in updates {
            if subUpdate.language == desiredLanguage {
                return subUpdate.unsupportedURL ?? ""
            }
        }
    }

    return nil
}

// userExperience
// Even if profile/JSON is installed, return nil if in demo-mode
func getUserExperienceJSON() -> UserExperience? {
    guard !CommandLineUtilities().demoModeEnabled(),
          !CommandLineUtilities().unitTestingEnabled(),
          let userExperience = Globals.nudgeJSONPreferences?.userExperience else {
        logEmptyKey("userExperience", forJSON: true)
        return nil
    }
    return userExperience
}

func getUserExperienceProfile() -> [String: Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        logEmptyKey("userExperience", forJSON: false)
        return nil
    }

    // Check if the Data is empty
    if Globals.configProfile.isEmpty {
        logEmptyKey("userExperience", forJSON: false)
        return nil
    }

    do {
        // Attempt to decode the plist Data into a dictionary
        if let dictionary = try PropertyListSerialization.propertyList(from: Globals.configProfile, options: [], format: nil) as? [String: Any],
           let userExperience = dictionary["userExperience"] as? [String: Any] {
            return userExperience
        } else {
            logEmptyKey("userExperience", forJSON: false)
            return nil
        }
    } catch {
        print("Failed to decode plist: \(error)")
        return nil
    }
}

// userInterface
// Even if profile/JSON is installed, return nil if in demo-mode
func forceScreenShotIconMode() -> Bool {
    return CommandLineUtilities().forceScreenShotIconModeEnabled() ||
    UserInterfaceVariables.userInterfaceProfile?["forceScreenShotIcon"] as? Bool ??
    Globals.nudgeJSONPreferences?.userInterface?.forceScreenShotIcon ?? false
}

func getUserInterfaceJSON() -> UserInterface? {
    guard !CommandLineUtilities().demoModeEnabled(),
          !CommandLineUtilities().unitTestingEnabled() else {
        return nil
    }

    if let userInterface = Globals.nudgeJSONPreferences?.userInterface {
        return userInterface
    }
    logEmptyKey("userInterface", forJSON: true)
    return nil
}

func getUserInterfaceProfile() -> [String: Any]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        logEmptyKey("userInterface", forJSON: false)
        return nil
    }

    // Check if the Data is empty
    if Globals.configProfile.isEmpty {
        logEmptyKey("userInterface", forJSON: false)
        return nil
    }

    do {
        // Attempt to decode the plist Data into a dictionary
        if let dictionary = try PropertyListSerialization.propertyList(from: Globals.configProfile, options: [], format: nil) as? [String: Any],
           let userInterface = dictionary["userInterface"] as? [String: Any] {
            return userInterface
        } else {
            logEmptyKey("userInterface", forJSON: false)
            return nil
        }
    } catch {
        print("Failed to decode plist: \(error)")
        return nil
    }
}

// Loop through JSON userInterface -> updateElements preferences and then compare language
func getUserInterfaceUpdateElementsJSON() -> UpdateElement? {
    return getMatchingUpdateElements(
        updateElements: getUserInterfaceJSON()?.updateElements,
        languageKey: "language",
        logKey: "JSON"
    )
}

func getUserInterfaceUpdateElementsProfile() -> [String: AnyObject]? {
    if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
        logEmptyKey("updateElements", forJSON: false)
        return nil
    }

    // Check if the Data is empty
    if Globals.configProfile.isEmpty {
        logEmptyKey("updateElements", forJSON: false)
        return nil
    }

    do {
        // Attempt to decode the plist Data into a dictionary
        if let dictionary = try PropertyListSerialization.propertyList(from: Globals.configProfile, options: [], format: nil) as? [String: Any],
           let userInterface = dictionary["userInterface"] as? [String: Any] {
            guard let updateElementsArray = userInterface["updateElements"] as? [[String: AnyObject]] else {
                logEmptyKey("updateElements", forJSON: false)
                return nil
            }
            return getMatchingUpdateElements(
                updateElements: updateElementsArray,
                languageKey: "_language",
                logKey: "Profile"
            )
        } else {
            logEmptyKey("updateElements", forJSON: false)
            return nil
        }
    } catch {
        print("Failed to decode plist: \(error)")
        return nil
    }
}

private func getMatchingUpdateElements<T>(updateElements: [T]?, languageKey: String, logKey: String) -> T? {
    guard !CommandLineUtilities().demoModeEnabled(),
          !CommandLineUtilities().unitTestingEnabled(),
          let updateElements = updateElements else {
        logEmptyKey("updateElements", forJSON: logKey == "JSON")
        return nil
    }

    let desiredLanguage = getDesiredLanguage()

    if let elements = updateElements as? [[String: AnyObject]] {
        // Handle dictionary (profile) type elements
        for element in elements {
            if element[languageKey] as? String == desiredLanguage {
                return element as? T
            }
        }
    } else if let elements = updateElements as? [UpdateElement] {
        // Handle UpdateElement (json) type elements
        for element in elements {
            if element.language == desiredLanguage {
                return element as? T
            }
        }
    }

    logEmptyKey("No match found in \(logKey) updateElements for the desired language \(desiredLanguage)", forJSON: logKey == "JSON")

    return nil
}

// Returns the mainHeader
func getMainHeader() -> String {
    if CommandLineUtilities().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else if CommandLineUtilities().unitTestingEnabled() {
        return "Your device requires a security update (Unit Testing Mode)"
    }
    return UserInterfaceVariables.userInterfaceUpdateElementsProfile?["mainHeader"] as? String ??
    getUserInterfaceUpdateElementsJSON()?.mainHeader ?? "Your device requires a security update"
}

func getMainHeaderUnsupported() -> String {
    if CommandLineUtilities().demoModeEnabled() {
        return "Your device requires a security update (Demo Mode)"
    } else if CommandLineUtilities().unitTestingEnabled() {
        return "Your device requires a security update (Unit Testing Mode)"
    }
    return UserInterfaceVariables.userInterfaceUpdateElementsProfile?["mainHeaderUnsupported"] as? String ??
    getUserInterfaceUpdateElementsJSON()?.mainHeaderUnsupported ?? "Your device requires a security update"
}

func simpleMode() -> Bool {
    return CommandLineUtilities().simpleModeEnabled() ||
    UserInterfaceVariables.userInterfaceProfile?["simpleMode"] as? Bool ??
    Globals.nudgeJSONPreferences?.userInterface?.simpleMode ?? false
}
