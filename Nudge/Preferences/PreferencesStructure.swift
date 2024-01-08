//
//  PreferencesStructure.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import Foundation

// MARK: - NudgePreferences
struct NudgePreferences: Codable {
    var optionalFeatures: OptionalFeatures?
    var osVersionRequirements: [OSVersionRequirement]?
    var userExperience: UserExperience?
    var userInterface: UserInterface?
}

extension NudgePreferences {
    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Use ISO 8601 date format
        self = try decoder.decode(NudgePreferences.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        optionalFeatures: OptionalFeatures?? = nil,
        osVersionRequirements: [OSVersionRequirement]?? = nil,
        userExperience: UserExperience?? = nil,
        userInterface: UserInterface?? = nil
    ) -> NudgePreferences {
        return NudgePreferences(
            optionalFeatures: optionalFeatures ?? self.optionalFeatures,
            osVersionRequirements: osVersionRequirements ?? self.osVersionRequirements,
            userExperience: userExperience ?? self.userExperience,
            userInterface: userInterface ?? self.userInterface
        )
    }
}

// MARK: - OptionalFeatures
struct OptionalFeatures: Codable {
    var acceptableApplicationBundleIDs, acceptableAssertionApplicationNames: [String]?
    var acceptableAssertionUsage, acceptableCameraUsage, acceptableScreenSharingUsage, aggressiveUserExperience, aggressiveUserFullScreenExperience, asynchronousSoftwareUpdate, attemptToBlockApplicationLaunches, attemptToFetchMajorUpgrade: Bool?
    var blockedApplicationBundleIDs: [String]?
    var disableSoftwareUpdateWorkflow, enforceMinorUpdates, terminateApplicationsOnLaunch: Bool?
}

// MARK: OptionalFeatures convenience initializers and mutators
extension OptionalFeatures {
    init(data: Data) throws {
        self = try JSONDecoder().decode(OptionalFeatures.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    func with(
        acceptableApplicationBundleIDs: [String]? = nil,
        acceptableAssertionApplicationNames: [String]? = nil,
        acceptableAssertionUsage: Bool? = nil,
        acceptableCameraUsage: Bool? = nil,
        acceptableScreenSharingUsage: Bool? = nil,
        aggressiveUserExperience: Bool? = nil,
        aggressiveUserFullScreenExperience: Bool? = nil,
        asynchronousSoftwareUpdate: Bool? = nil,
        attemptToBlockApplicationLaunches: Bool? = nil,
        attemptToFetchMajorUpgrade: Bool? = nil,
        blockedApplicationBundleIDs: [String]? = nil,
        disableSoftwareUpdateWorkflow: Bool? = nil,
        enforceMinorUpdates: Bool? = nil,
        terminateApplicationsOnLaunch: Bool? = nil
    ) -> OptionalFeatures {
        return OptionalFeatures(
            acceptableApplicationBundleIDs: acceptableApplicationBundleIDs ?? self.acceptableApplicationBundleIDs,
            acceptableAssertionApplicationNames: acceptableAssertionApplicationNames ?? self.acceptableAssertionApplicationNames,
            acceptableAssertionUsage: acceptableAssertionUsage ?? self.acceptableAssertionUsage,
            acceptableCameraUsage: acceptableCameraUsage ?? self.acceptableCameraUsage,
            acceptableScreenSharingUsage: acceptableScreenSharingUsage ?? self.acceptableScreenSharingUsage,
            aggressiveUserExperience: aggressiveUserExperience ?? self.aggressiveUserExperience,
            aggressiveUserFullScreenExperience: aggressiveUserFullScreenExperience ?? self.aggressiveUserFullScreenExperience,
            asynchronousSoftwareUpdate: asynchronousSoftwareUpdate ?? self.asynchronousSoftwareUpdate,
            attemptToBlockApplicationLaunches: attemptToBlockApplicationLaunches ?? self.attemptToBlockApplicationLaunches,
            attemptToFetchMajorUpgrade: attemptToFetchMajorUpgrade ?? self.attemptToFetchMajorUpgrade,
            blockedApplicationBundleIDs: blockedApplicationBundleIDs ?? self.blockedApplicationBundleIDs,
            disableSoftwareUpdateWorkflow: disableSoftwareUpdateWorkflow ?? self.disableSoftwareUpdateWorkflow,
            enforceMinorUpdates: enforceMinorUpdates ?? self.enforceMinorUpdates,
            terminateApplicationsOnLaunch: terminateApplicationsOnLaunch ?? self.terminateApplicationsOnLaunch
        )
    }
}

// MARK: - OSVersionRequirement
struct OSVersionRequirement: Codable {
    var aboutUpdateURL: String?
    var aboutUpdateURLs: [AboutUpdateURL]?
    var actionButtonPath, majorUpgradeAppPath: String?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion, targetedOSVersionsRule: String?
}

// MARK: OSVersionRequirement convenience initializers and mutators
extension OSVersionRequirement {
    init(fromDictionary: [String: AnyObject]) {
        self.aboutUpdateURL = fromDictionary["aboutUpdateURL"] as? String
        self.actionButtonPath = fromDictionary["actionButtonPath"] as? String
        self.majorUpgradeAppPath = fromDictionary["majorUpgradeAppPath"] as? String
        self.requiredMinimumOSVersion = fromDictionary["requiredMinimumOSVersion"] as? String
        self.targetedOSVersionsRule = fromDictionary["targetedOSVersionsRule"] as? String

        // Handling AboutUpdateURLs
        if let aboutURLs = fromDictionary["aboutUpdateURLs"] as? [[String: String]] {
            self.aboutUpdateURLs = aboutURLs.compactMap { dict in
                guard let language = dict["_language"], let url = dict["aboutUpdateURL"] else { return nil }
                return AboutUpdateURL(language: language, aboutUpdateURL: url)
            }
        } else {
            self.aboutUpdateURLs = []
        }

        // Handling requiredInstallationDate
        // Jamf JSON Schema for mobileconfigurations do not support Date types (JSON does not support it)
        // In order to support this, an admin would need to pass a string and then coerce it into our Date format
        // https://docs.jamf.com/technical-papers/jamf-pro/json-schema/10.26.0/Understanding_the_Structure_of_a_JSON_Schema_Manifest.html
        if let dateString = fromDictionary["requiredInstallationDate"] as? String {
            self.requiredInstallationDate = DateManager().coerceStringToDate(dateString: dateString)
        } else {
            self.requiredInstallationDate = fromDictionary["requiredInstallationDate"] as? Date
        }
    }

    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Use ISO 8601 date format
        self = try decoder.decode(OSVersionRequirement.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    func with(
        aboutUpdateURL: String? = nil,
        aboutUpdateURLs: [AboutUpdateURL]? = nil,
        actionButtonPath: String? = nil,
        majorUpgradeAppPath: String? = nil,
        requiredInstallationDate: Date? = nil,
        requiredMinimumOSVersion: String? = nil,
        targetedOSVersionsRule: String? = nil
    ) -> OSVersionRequirement {
        return OSVersionRequirement(
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL,
            aboutUpdateURLs: aboutUpdateURLs ?? self.aboutUpdateURLs,
            actionButtonPath: actionButtonPath ?? self.actionButtonPath,
            majorUpgradeAppPath: majorUpgradeAppPath ?? self.majorUpgradeAppPath,
            requiredInstallationDate: requiredInstallationDate ?? self.requiredInstallationDate,
            requiredMinimumOSVersion: requiredMinimumOSVersion ?? self.requiredMinimumOSVersion,
            targetedOSVersionsRule: targetedOSVersionsRule ?? self.targetedOSVersionsRule
        )
    }
}

// MARK: - AboutUpdateURL
struct AboutUpdateURL: Codable {
    var language: String?
    var aboutUpdateURL: String?
    
    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case aboutUpdateURL
    }
}

// MARK: AboutUpdateURL convenience initializers and mutators
extension AboutUpdateURL {
    init(data: Data) throws {
        self = try JSONDecoder().decode(AboutUpdateURL.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    func with(
        language: String? = nil,
        aboutUpdateURL: String? = nil
    ) -> AboutUpdateURL {
        return AboutUpdateURL(
            language: language ?? self.language,
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL
        )
    }
}

// MARK: - UserExperience
struct UserExperience: Codable {
    var allowGracePeriods, allowLaterDeferralButton, allowUserQuitDeferrals: Bool?
    var allowedDeferrals, allowedDeferralsUntilForcedSecondaryQuitButton, approachingRefreshCycle, approachingWindowTime: Int?
    var calendarDeferralUnit: String?
    var elapsedRefreshCycle, gracePeriodInstallDelay, gracePeriodLaunchDelay: Int?
    var gracePeriodPath: String?
    var imminentRefreshCycle, imminentWindowTime, initialRefreshCycle: Int?
    var launchAgentIdentifier: String?
    var loadLaunchAgent: Bool?
    var maxRandomDelayInSeconds: Int?
    var noTimers: Bool?
    var nudgeRefreshCycle: Int?
    var randomDelay: Bool?
}

// MARK: UserExperience convenience initializers and mutators
extension UserExperience {
    init(data: Data) throws {
        self = try JSONDecoder().decode(UserExperience.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    func with(
        allowGracePeriods: Bool? = nil,
        allowLaterDeferralButton: Bool? = nil,
        allowUserQuitDeferrals: Bool? = nil,
        allowedDeferrals: Int? = nil,
        allowedDeferralsUntilForcedSecondaryQuitButton: Int? = nil,
        approachingRefreshCycle: Int? = nil,
        approachingWindowTime: Int? = nil,
        calendarDeferralUnit: String? = nil,
        elapsedRefreshCycle: Int? = nil,
        gracePeriodInstallDelay: Int? = nil,
        gracePeriodLaunchDelay: Int? = nil,
        gracePeriodPath: String? = nil,
        imminentRefreshCycle: Int? = nil,
        imminentWindowTime: Int? = nil,
        initialRefreshCycle: Int? = nil,
        launchAgentIdentifier: String? = nil,
        loadLaunchAgent: Bool? = nil,
        maxRandomDelayInSeconds: Int? = nil,
        noTimers: Bool? = nil,
        nudgeRefreshCycle: Int? = nil,
        randomDelay: Bool? = nil
    ) -> UserExperience {
        return UserExperience(
            allowGracePeriods: allowGracePeriods ?? self.allowGracePeriods,
            allowLaterDeferralButton: allowLaterDeferralButton ?? self.allowLaterDeferralButton,
            allowUserQuitDeferrals: allowUserQuitDeferrals ?? self.allowUserQuitDeferrals,
            allowedDeferrals: allowedDeferrals ?? self.allowedDeferrals,
            allowedDeferralsUntilForcedSecondaryQuitButton: allowedDeferralsUntilForcedSecondaryQuitButton ?? self.allowedDeferralsUntilForcedSecondaryQuitButton,
            approachingRefreshCycle: approachingRefreshCycle ?? self.approachingRefreshCycle,
            approachingWindowTime: approachingWindowTime ?? self.approachingWindowTime,
            calendarDeferralUnit: calendarDeferralUnit ?? self.calendarDeferralUnit,
            elapsedRefreshCycle: elapsedRefreshCycle ?? self.elapsedRefreshCycle,
            gracePeriodInstallDelay: gracePeriodInstallDelay ?? self.gracePeriodInstallDelay,
            gracePeriodLaunchDelay: gracePeriodLaunchDelay ?? self.gracePeriodLaunchDelay,
            gracePeriodPath: gracePeriodPath ?? self.gracePeriodPath,
            imminentRefreshCycle: imminentRefreshCycle ?? self.imminentRefreshCycle,
            imminentWindowTime: imminentWindowTime ?? self.imminentWindowTime,
            initialRefreshCycle: initialRefreshCycle ?? self.initialRefreshCycle,
            launchAgentIdentifier: launchAgentIdentifier ?? self.launchAgentIdentifier,
            loadLaunchAgent: loadLaunchAgent ?? self.loadLaunchAgent,
            maxRandomDelayInSeconds: maxRandomDelayInSeconds ?? self.maxRandomDelayInSeconds,
            noTimers: noTimers ?? self.noTimers,
            nudgeRefreshCycle: nudgeRefreshCycle ?? self.nudgeRefreshCycle,
            randomDelay: randomDelay ?? self.randomDelay
        )
    }
}

// MARK: - UserInterface
struct UserInterface: Codable {
    var actionButtonPath, fallbackLanguage: String?
    var forceFallbackLanguage, forceScreenShotIcon: Bool?
    var iconDarkPath, iconLightPath, screenShotDarkPath, screenShotLightPath: String?
    var showDeferralCount, simpleMode, singleQuitButton: Bool?
    var updateElements: [UpdateElement]?
}

// MARK: UserInterface convenience initializers and mutators
extension UserInterface {
    init(data: Data) throws {
        self = try JSONDecoder().decode(UserInterface.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    func with(
        actionButtonPath: String? = nil,
        fallbackLanguage: String? = nil,
        forceFallbackLanguage: Bool? = nil,
        forceScreenShotIcon: Bool? = nil,
        iconDarkPath: String? = nil,
        iconLightPath: String? = nil,
        screenShotDarkPath: String? = nil,
        screenShotLightPath: String? = nil,
        showDeferralCount: Bool? = nil,
        simpleMode: Bool? = nil,
        singleQuitButton: Bool? = nil,
        updateElements: [UpdateElement]? = nil
    ) -> UserInterface {
        return UserInterface(
            actionButtonPath: actionButtonPath ?? self.actionButtonPath,
            fallbackLanguage: fallbackLanguage ?? self.fallbackLanguage,
            forceFallbackLanguage: forceFallbackLanguage ?? self.forceFallbackLanguage,
            forceScreenShotIcon: forceScreenShotIcon ?? self.forceScreenShotIcon,
            iconDarkPath: iconDarkPath ?? self.iconDarkPath,
            iconLightPath: iconLightPath ?? self.iconLightPath,
            screenShotDarkPath: screenShotDarkPath ?? self.screenShotDarkPath,
            screenShotLightPath: screenShotLightPath ?? self.screenShotLightPath,
            showDeferralCount: showDeferralCount ?? self.showDeferralCount,
            simpleMode: simpleMode ?? self.simpleMode,
            singleQuitButton: singleQuitButton ?? self.singleQuitButton,
            updateElements: updateElements ?? self.updateElements
        )
    }
}

// MARK: - UpdateElement
struct UpdateElement: Codable {
    var language, actionButtonText, customDeferralButtonText, customDeferralDropdownText, informationButtonText: String?
    var mainContentHeader, mainContentNote, mainContentSubHeader, mainContentText, mainHeader: String?
    var oneDayDeferralButtonText, oneHourDeferralButtonText, primaryQuitButtonText, secondaryQuitButtonText, subHeader, screenShotAltText: String?
    
    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case actionButtonText, customDeferralButtonText, customDeferralDropdownText, informationButtonText, mainContentHeader, mainContentNote, mainContentSubHeader, mainContentText, mainHeader, oneDayDeferralButtonText, oneHourDeferralButtonText, primaryQuitButtonText, secondaryQuitButtonText, subHeader, screenShotAltText
    }
}

// MARK: Element convenience initializers and mutators
extension UpdateElement {
    init(data: Data) throws {
        self = try JSONDecoder().decode(UpdateElement.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string."])
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }
    
    func with(
        language: String? = nil,
        actionButtonText: String? = nil,
        customDeferralButtonText: String? = nil,
        customDeferralDropdownText: String? = nil,
        informationButtonText: String? = nil,
        mainContentHeader: String? = nil,
        mainContentNote: String? = nil,
        mainContentSubHeader: String? = nil,
        mainContentText: String? = nil,
        mainHeader: String? = nil,
        oneDayDeferralButtonText: String? = nil,
        oneHourDeferralButtonText: String? = nil,
        primaryQuitButtonText: String? = nil,
        secondaryQuitButtonText: String? = nil,
        subHeader: String? = nil,
        screenShotAltText: String? = nil
    ) -> UpdateElement {
        return UpdateElement(
            language: language ?? self.language,
            actionButtonText: actionButtonText ?? self.actionButtonText,
            customDeferralButtonText: customDeferralButtonText ?? self.customDeferralButtonText,
            customDeferralDropdownText: customDeferralDropdownText ?? self.customDeferralDropdownText,
            informationButtonText: informationButtonText ?? self.informationButtonText,
            mainContentHeader: mainContentHeader ?? self.mainContentHeader,
            mainContentNote: mainContentNote ?? self.mainContentNote,
            mainContentSubHeader: mainContentSubHeader ?? self.mainContentSubHeader,
            mainContentText: mainContentText ?? self.mainContentText,
            mainHeader: mainHeader ?? self.mainHeader,
            oneDayDeferralButtonText: oneDayDeferralButtonText ?? self.oneDayDeferralButtonText,
            oneHourDeferralButtonText: oneHourDeferralButtonText ?? self.oneHourDeferralButtonText,
            primaryQuitButtonText: primaryQuitButtonText ?? self.primaryQuitButtonText,
            secondaryQuitButtonText: secondaryQuitButtonText ?? self.secondaryQuitButtonText,
            subHeader: subHeader ?? self.subHeader,
            screenShotAltText: screenShotAltText ?? self.screenShotAltText
        )
    }
}
