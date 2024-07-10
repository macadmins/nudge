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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        // First attempt with ISO 8601 date format
        do {
            decoder.dateDecodingStrategy = .iso8601
            self = try decoder.decode(NudgePreferences.self, from: data)
            return
        } catch {
        }

        // Second attempt with custom date format
        do {
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            self = try decoder.decode(NudgePreferences.self, from: data)
            return
        } catch {
        }
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
    var acceptableAssertionUsage, acceptableCameraUsage, acceptableUpdatePreparingUsage, acceptableScreenSharingUsage, aggressiveUserExperience, aggressiveUserFullScreenExperience, asynchronousSoftwareUpdate, attemptToBlockApplicationLaunches, attemptToCheckForSupportedDevice, attemptToFetchMajorUpgrade: Bool?
    var blockedApplicationBundleIDs: [String]?
    var customSOFAFeedURL: String?
    var disableNudgeForStandardInstalls, disableSoftwareUpdateWorkflow, enforceMinorUpdates, honorFocusModes, honorCycleTimersOnExit: Bool?
    var refreshSOFAFeedTime: Int?
    var terminateApplicationsOnLaunch, utilizeSOFAFeed: Bool?
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
        acceptableUpdatePreparingUsage: Bool? = nil,
        acceptableScreenSharingUsage: Bool? = nil,
        aggressiveUserExperience: Bool? = nil,
        aggressiveUserFullScreenExperience: Bool? = nil,
        asynchronousSoftwareUpdate: Bool? = nil,
        attemptToBlockApplicationLaunches: Bool? = nil,
        attemptToCheckForSupportedDevice: Bool? = nil,
        attemptToFetchMajorUpgrade: Bool? = nil,
        blockedApplicationBundleIDs: [String]? = nil,
        customSOFAFeedURL: String? = nil,
        disableNudgeForStandardInstalls: Bool? = nil,
        disableSoftwareUpdateWorkflow: Bool? = nil,
        enforceMinorUpdates: Bool? = nil,
        honorFocusModes: Bool? = nil,
        honorCycleTimersOnExit: Bool? = nil,
        refreshSOFAFeedTime: Int? = nil,
        terminateApplicationsOnLaunch: Bool? = nil,
        utilizeSOFAFeed: Bool? = nil
    ) -> OptionalFeatures {
        return OptionalFeatures(
            acceptableApplicationBundleIDs: acceptableApplicationBundleIDs ?? self.acceptableApplicationBundleIDs,
            acceptableAssertionApplicationNames: acceptableAssertionApplicationNames ?? self.acceptableAssertionApplicationNames,
            acceptableAssertionUsage: acceptableAssertionUsage ?? self.acceptableAssertionUsage,
            acceptableCameraUsage: acceptableCameraUsage ?? self.acceptableCameraUsage,
            acceptableUpdatePreparingUsage: acceptableUpdatePreparingUsage ?? self.acceptableUpdatePreparingUsage,
            acceptableScreenSharingUsage: acceptableScreenSharingUsage ?? self.acceptableScreenSharingUsage,
            aggressiveUserExperience: aggressiveUserExperience ?? self.aggressiveUserExperience,
            aggressiveUserFullScreenExperience: aggressiveUserFullScreenExperience ?? self.aggressiveUserFullScreenExperience,
            asynchronousSoftwareUpdate: asynchronousSoftwareUpdate ?? self.asynchronousSoftwareUpdate,
            attemptToBlockApplicationLaunches: attemptToBlockApplicationLaunches ?? self.attemptToBlockApplicationLaunches,
            attemptToCheckForSupportedDevice: attemptToCheckForSupportedDevice ?? self.attemptToCheckForSupportedDevice,
            attemptToFetchMajorUpgrade: attemptToFetchMajorUpgrade ?? self.attemptToFetchMajorUpgrade,
            blockedApplicationBundleIDs: blockedApplicationBundleIDs ?? self.blockedApplicationBundleIDs,
            customSOFAFeedURL: customSOFAFeedURL ?? self.customSOFAFeedURL,
            disableNudgeForStandardInstalls: disableNudgeForStandardInstalls ?? self.disableNudgeForStandardInstalls,
            disableSoftwareUpdateWorkflow: disableSoftwareUpdateWorkflow ?? self.disableSoftwareUpdateWorkflow,
            enforceMinorUpdates: enforceMinorUpdates ?? self.enforceMinorUpdates,
            honorFocusModes: honorFocusModes ?? self.honorFocusModes,
            honorCycleTimersOnExit: honorCycleTimersOnExit ?? self.honorCycleTimersOnExit,
            refreshSOFAFeedTime: refreshSOFAFeedTime ?? self.refreshSOFAFeedTime,
            terminateApplicationsOnLaunch: terminateApplicationsOnLaunch ?? self.terminateApplicationsOnLaunch,
            utilizeSOFAFeed: utilizeSOFAFeed ?? self.utilizeSOFAFeed
        )
    }
}

// MARK: - OSVersionRequirement
struct OSVersionRequirement: Codable {
    var aboutUpdateURL: String?
    var aboutUpdateURLs: [AboutUpdateURL]?
    var actionButtonPath: String?
    var activelyExploitedCVEsMajorUpgradeSLA: Int?
    var activelyExploitedCVEsMinorUpdateSLA: Int?
    var majorUpgradeAppPath: String?
    var nonActivelyExploitedCVEsMajorUpgradeSLA: Int?
    var nonActivelyExploitedCVEsMinorUpdateSLA: Int?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion: String?
    var standardMajorUpgradeSLA: Int?
    var standardMinorUpdateSLA: Int?
    var targetedOSVersionsRule: String?
    var unsupportedURL: String?
    var unsupportedURLs: [UnsupportedURL]?
}

// MARK: OSVersionRequirement convenience initializers and mutators
extension OSVersionRequirement {
    init(fromDictionary: [String: AnyObject]) {
        self.aboutUpdateURL = fromDictionary["aboutUpdateURL"] as? String
        self.actionButtonPath = fromDictionary["actionButtonPath"] as? String
        self.activelyExploitedCVEsMajorUpgradeSLA = fromDictionary["activelyExploitedCVEsMajorUpgradeSLA"] as? Int
        self.activelyExploitedCVEsMinorUpdateSLA = fromDictionary["activelyExploitedCVEsMinorUpdateSLA"] as? Int
        self.majorUpgradeAppPath = fromDictionary["majorUpgradeAppPath"] as? String
        self.nonActivelyExploitedCVEsMajorUpgradeSLA = fromDictionary["nonActivelyExploitedCVEsMajorUpgradeSLA"] as? Int
        self.nonActivelyExploitedCVEsMinorUpdateSLA = fromDictionary["nonActivelyExploitedCVEsMinorUpdateSLA"] as? Int
        self.requiredMinimumOSVersion = fromDictionary["requiredMinimumOSVersion"] as? String
        self.standardMajorUpgradeSLA = fromDictionary["standardMajorUpgradeSLA"] as? Int
        self.standardMinorUpdateSLA = fromDictionary["standardMinorUpdateSLA"] as? Int
        self.targetedOSVersionsRule = fromDictionary["targetedOSVersionsRule"] as? String
        self.unsupportedURL = fromDictionary["unsupportedURL"] as? String

        // Handling AboutUpdateURLs and UnsupportedURLs
        if let aboutURLs = fromDictionary["aboutUpdateURLs"] as? [[String: String]] {
            self.aboutUpdateURLs = aboutURLs.compactMap { dict in
                guard let language = dict["_language"], let url = dict["aboutUpdateURL"] else { return nil }
                return AboutUpdateURL(language: language, aboutUpdateURL: url)
            }
        } else {
            self.aboutUpdateURLs = []
        }

        if let unsupportedURLs = fromDictionary["unsupportedURLs"] as? [[String: String]] {
            self.unsupportedURLs = unsupportedURLs.compactMap { dict in
                guard let language = dict["_language"], let url = dict["unsupportedURL"] else { return nil }
                return UnsupportedURL(language: language, unsupportedURL: url)
            }
        } else {
            self.unsupportedURLs = []
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        // First attempt with ISO 8601 date format
        do {
            decoder.dateDecodingStrategy = .iso8601
            self = try decoder.decode(OSVersionRequirement.self, from: data)
            return
        } catch {
        }

        // Second attempt with custom date format
        do {
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            self = try decoder.decode(OSVersionRequirement.self, from: data)
            return
        } catch {
        }
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
        activelyExploitedCVEsMajorUpgradeSLA: Int? = nil,
        activelyExploitedCVEsMinorUpdateSLA: Int? = nil,
        majorUpgradeAppPath: String? = nil,
        nonActivelyExploitedCVEsMajorUpgradeSLA: Int? = nil,
        nonActivelyExploitedCVEsMinorUpdateSLA: Int? = nil,
        requiredInstallationDate: Date? = nil,
        requiredMinimumOSVersion: String? = nil,
        standardMajorUpgradeSLA: Int? = nil,
        standardMinorUpdateSLA: Int? = nil,
        targetedOSVersionsRule: String? = nil,
        unsupportedURL: String? = nil,
        unsupportedURLs: [UnsupportedURL]? = nil
    ) -> OSVersionRequirement {
        return OSVersionRequirement(
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL,
            aboutUpdateURLs: aboutUpdateURLs ?? self.aboutUpdateURLs,
            actionButtonPath: actionButtonPath ?? self.actionButtonPath,
            activelyExploitedCVEsMajorUpgradeSLA: activelyExploitedCVEsMajorUpgradeSLA ?? self.activelyExploitedCVEsMajorUpgradeSLA,
            activelyExploitedCVEsMinorUpdateSLA: activelyExploitedCVEsMinorUpdateSLA ?? self.activelyExploitedCVEsMinorUpdateSLA,
            majorUpgradeAppPath: majorUpgradeAppPath ?? self.majorUpgradeAppPath,
            nonActivelyExploitedCVEsMajorUpgradeSLA: nonActivelyExploitedCVEsMajorUpgradeSLA ?? self.nonActivelyExploitedCVEsMajorUpgradeSLA,
            nonActivelyExploitedCVEsMinorUpdateSLA: nonActivelyExploitedCVEsMinorUpdateSLA ?? self.nonActivelyExploitedCVEsMinorUpdateSLA,
            requiredInstallationDate: requiredInstallationDate ?? self.requiredInstallationDate,
            requiredMinimumOSVersion: requiredMinimumOSVersion ?? self.requiredMinimumOSVersion,
            standardMajorUpgradeSLA: standardMajorUpgradeSLA ?? self.standardMajorUpgradeSLA,
            standardMinorUpdateSLA: standardMinorUpdateSLA ?? self.standardMinorUpdateSLA,
            targetedOSVersionsRule: targetedOSVersionsRule ?? self.targetedOSVersionsRule,
            unsupportedURL: unsupportedURL ?? self.unsupportedURL,
            unsupportedURLs: unsupportedURLs ?? self.unsupportedURLs
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

// MARK: - UnsupportedURL
struct UnsupportedURL: Codable {
    var language: String?
    var unsupportedURL: String?

    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case unsupportedURL
    }
}

// MARK: UnsupportedURL convenience initializers and mutators
extension UnsupportedURL {
    init(data: Data) throws {
        self = try JSONDecoder().decode(UnsupportedURL.self, from: data)
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
        unsupportedURL: String? = nil
    ) -> UnsupportedURL {
        return UnsupportedURL(
            language: language ?? self.language,
            unsupportedURL: unsupportedURL ?? self.unsupportedURL
        )
    }
}

// MARK: - UserExperience
struct UserExperience: Codable {
    var allowGracePeriods, allowLaterDeferralButton, allowMovableWindow, allowUserQuitDeferrals: Bool?
    var allowedDeferrals, allowedDeferralsUntilForcedSecondaryQuitButton, approachingRefreshCycle, approachingWindowTime: Int?
    var calendarDeferralUnit: String?
    var elapsedRefreshCycle, gracePeriodInstallDelay, gracePeriodLaunchDelay: Int?
    var gracePeriodPath: String?
    var imminentRefreshCycle, imminentWindowTime, initialRefreshCycle: Int?
    var launchAgentIdentifier: String?
    var loadLaunchAgent: Bool?
    var maxRandomDelayInSeconds: Int?
    var noTimers: Bool?
    var nudgeEventLaunchDelay: Int?
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
        allowMovableWindow: Bool? = nil,
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
        nudgeEventLaunchDelay: Int? = nil,
        nudgeRefreshCycle: Int? = nil,
        randomDelay: Bool? = nil
    ) -> UserExperience {
        return UserExperience(
            allowGracePeriods: allowGracePeriods ?? self.allowGracePeriods,
            allowLaterDeferralButton: allowLaterDeferralButton ?? self.allowLaterDeferralButton,
            allowMovableWindow: allowMovableWindow ?? self.allowMovableWindow,
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
            nudgeEventLaunchDelay: nudgeEventLaunchDelay ?? self.nudgeEventLaunchDelay,
            nudgeRefreshCycle: nudgeRefreshCycle ?? self.nudgeRefreshCycle,
            randomDelay: randomDelay ?? self.randomDelay
        )
    }
}

// MARK: - UserInterface
struct UserInterface: Codable {
    var actionButtonPath, applicationTerminatedNotificationImagePath, fallbackLanguage: String?
    var forceFallbackLanguage, forceScreenShotIcon: Bool?
    var iconDarkPath, iconLightPath, requiredInstallationDisplayFormat, screenShotDarkPath, screenShotLightPath: String?
    var showActivelyExploitedCVEs, showDeferralCount, showDaysRemainingToUpdate, showRequiredDate, simpleMode, singleQuitButton: Bool?
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
        applicationTerminatedNotificationImagePath: String? = nil,
        fallbackLanguage: String? = nil,
        forceFallbackLanguage: Bool? = nil,
        forceScreenShotIcon: Bool? = nil,
        iconDarkPath: String? = nil,
        iconLightPath: String? = nil,
        requiredInstallationDisplayFormat: String? = nil,
        screenShotDarkPath: String? = nil,
        screenShotLightPath: String? = nil,
        showActivelyExploitedCVEs: Bool? = nil,
        showDeferralCount: Bool? = nil,
        showDaysRemainingToUpdate: Bool? = nil,
        showRequiredDate: Bool? = nil,
        simpleMode: Bool? = nil,
        singleQuitButton: Bool? = nil,
        updateElements: [UpdateElement]? = nil
    ) -> UserInterface {
        return UserInterface(
            actionButtonPath: actionButtonPath ?? self.actionButtonPath,
            applicationTerminatedNotificationImagePath: applicationTerminatedNotificationImagePath ?? self.applicationTerminatedNotificationImagePath,
            fallbackLanguage: fallbackLanguage ?? self.fallbackLanguage,
            forceFallbackLanguage: forceFallbackLanguage ?? self.forceFallbackLanguage,
            forceScreenShotIcon: forceScreenShotIcon ?? self.forceScreenShotIcon,
            iconDarkPath: iconDarkPath ?? self.iconDarkPath,
            iconLightPath: iconLightPath ?? self.iconLightPath,
            requiredInstallationDisplayFormat: requiredInstallationDisplayFormat ?? self.requiredInstallationDisplayFormat,
            screenShotDarkPath: screenShotDarkPath ?? self.screenShotDarkPath,
            screenShotLightPath: screenShotLightPath ?? self.screenShotLightPath,
            showActivelyExploitedCVEs: showActivelyExploitedCVEs ?? self.showActivelyExploitedCVEs,
            showDeferralCount: showDeferralCount ?? self.showDeferralCount,
            showDaysRemainingToUpdate: showDaysRemainingToUpdate ?? self.showDaysRemainingToUpdate,
            showRequiredDate: showRequiredDate ?? self.showRequiredDate,
            simpleMode: simpleMode ?? self.simpleMode,
            singleQuitButton: singleQuitButton ?? self.singleQuitButton,
            updateElements: updateElements ?? self.updateElements
        )
    }
}

// MARK: - UpdateElement
struct UpdateElement: Codable {
    var language, actionButtonText, actionButtonTextUnsupported, applicationTerminatedTitleText, applicationTerminatedBodyText, customDeferralButtonText, customDeferralDropdownText: String?
    var informationButtonText, mainContentHeader, mainContentHeaderUnsupported, mainContentNote, mainContentNoteUnsupported: String?
    var mainContentSubHeader, mainContentSubHeaderUnsupported, mainContentText, mainContentTextUnsupported, mainHeader, mainHeaderUnsupported: String?
    var oneDayDeferralButtonText, oneHourDeferralButtonText, primaryQuitButtonText, screenShotAltText, secondaryQuitButtonText, subHeader, subHeaderUnsupported: String?

    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case actionButtonText, actionButtonTextUnsupported, applicationTerminatedTitleText, applicationTerminatedBodyText, customDeferralButtonText, customDeferralDropdownText, informationButtonText, mainContentHeader, mainContentHeaderUnsupported, mainContentNote, mainContentNoteUnsupported, mainContentSubHeader, mainContentSubHeaderUnsupported, mainContentText, mainContentTextUnsupported, mainHeader, mainHeaderUnsupported, oneDayDeferralButtonText, oneHourDeferralButtonText, primaryQuitButtonText, screenShotAltText, secondaryQuitButtonText, subHeader, subHeaderUnsupported
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
        actionButtonTextUnsupported: String? = nil,
        applicationTerminatedTitleText: String? = nil,
        applicationTerminatedBodyText: String? = nil,
        customDeferralButtonText: String? = nil,
        customDeferralDropdownText: String? = nil,
        informationButtonText: String? = nil,
        mainContentHeader: String? = nil,
        mainContentHeaderUnsupported: String? = nil,
        mainContentNote: String? = nil,
        mainContentNoteUnsupported: String? = nil,
        mainContentSubHeader: String? = nil,
        mainContentSubHeaderUnsupported: String? = nil,
        mainContentText: String? = nil,
        mainContentTextUnsupported: String? = nil,
        mainHeader: String? = nil,
        mainHeaderUnsupported: String? = nil,
        oneDayDeferralButtonText: String? = nil,
        oneHourDeferralButtonText: String? = nil,
        primaryQuitButtonText: String? = nil,
        screenShotAltText: String? = nil,
        secondaryQuitButtonText: String? = nil,
        subHeader: String? = nil,
        subHeaderUnsupported: String? = nil
    ) -> UpdateElement {
        return UpdateElement(
            language: language ?? self.language,
            actionButtonText: actionButtonText ?? self.actionButtonText,
            actionButtonTextUnsupported: actionButtonTextUnsupported ?? self.actionButtonTextUnsupported,
            applicationTerminatedTitleText: applicationTerminatedTitleText ?? self.applicationTerminatedTitleText,
            applicationTerminatedBodyText: applicationTerminatedBodyText ?? self.applicationTerminatedBodyText,
            customDeferralButtonText: customDeferralButtonText ?? self.customDeferralButtonText,
            customDeferralDropdownText: customDeferralDropdownText ?? self.customDeferralDropdownText,
            informationButtonText: informationButtonText ?? self.informationButtonText,
            mainContentHeader: mainContentHeader ?? self.mainContentHeader,
            mainContentHeaderUnsupported: mainContentHeaderUnsupported ?? self.mainContentHeaderUnsupported,
            mainContentNote: mainContentNote ?? self.mainContentNote,
            mainContentNoteUnsupported: mainContentNoteUnsupported ?? self.mainContentNoteUnsupported,
            mainContentSubHeader: mainContentSubHeader ?? self.mainContentSubHeader,
            mainContentSubHeaderUnsupported: mainContentSubHeaderUnsupported ?? self.mainContentSubHeaderUnsupported,
            mainContentText: mainContentText ?? self.mainContentText,
            mainContentTextUnsupported: mainContentTextUnsupported ?? self.mainContentTextUnsupported,
            mainHeader: mainHeader ?? self.mainHeader,
            mainHeaderUnsupported: mainHeaderUnsupported ?? self.mainHeaderUnsupported,
            oneDayDeferralButtonText: oneDayDeferralButtonText ?? self.oneDayDeferralButtonText,
            oneHourDeferralButtonText: oneHourDeferralButtonText ?? self.oneHourDeferralButtonText,
            primaryQuitButtonText: primaryQuitButtonText ?? self.primaryQuitButtonText,
            screenShotAltText: screenShotAltText ?? self.screenShotAltText,
            secondaryQuitButtonText: secondaryQuitButtonText ?? self.secondaryQuitButtonText,
            subHeader: subHeader ?? self.subHeader,
            subHeaderUnsupported: subHeaderUnsupported ?? self.subHeaderUnsupported
        )
    }
}
