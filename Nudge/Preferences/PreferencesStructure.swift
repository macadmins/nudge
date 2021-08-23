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

// MARK: NudgePreferences convenience initializers and mutators

extension NudgePreferences {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(NudgePreferences.self, from: data)
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

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - OptionalFeatures
struct OptionalFeatures: Codable {
    var acceptableApplicationBundleIDs: [String]?
    var asyncronousSoftwareUpdate, attemptToFetchMajorUpgrade, enforceMinorUpdates: Bool?
}

// MARK: OptionalFeatures convenience initializers and mutators

extension OptionalFeatures {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(OptionalFeatures.self, from: data)
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
        acceptableApplicationBundleIDs: [String]?? = nil,
        asyncronousSoftwareUpdate: Bool?? = nil,
        attemptToFetchMajorUpgrade: Bool?? = nil,
        enforceMinorUpdates: Bool?? = nil
    ) -> OptionalFeatures {
        return OptionalFeatures(
            acceptableApplicationBundleIDs: acceptableApplicationBundleIDs ?? self.acceptableApplicationBundleIDs,
            asyncronousSoftwareUpdate: asyncronousSoftwareUpdate ?? self.asyncronousSoftwareUpdate,
            attemptToFetchMajorUpgrade: attemptToFetchMajorUpgrade ?? self.attemptToFetchMajorUpgrade,
            enforceMinorUpdates: enforceMinorUpdates ?? self.enforceMinorUpdates
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - OSVersionRequirement
struct OSVersionRequirement: Codable {
    var aboutUpdateURL: String?
    var aboutUpdateURLs: [AboutUpdateURL]?
    var majorUpgradeAppPath: String?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion: String?
    var versionRules: [VersionRule]?
}

// MARK: OSVersionRequirement convenience initializers and mutators

extension OSVersionRequirement {
    init(fromDictionary: [String:AnyObject]) {
        // Thanks again mactroll
        var generatedAboutUpdateURLs = [AboutUpdateURL]()
        if let aboutURLs = fromDictionary["aboutUpdateURLs"] as? [[String:String]] {
            for each in aboutURLs {
                if let language = each["_language"], let url = each["aboutUpdateURL"] {
                    generatedAboutUpdateURLs.append(AboutUpdateURL(language: language, aboutUpdateURL: url))
                }
            }
        }
        // Jamf JSON Schema for mobileconfigurations do not support Date types (JSON does not support it)
        // In order to support this, an admin would need to pass a string and then coerce it into our Date format
        // https://docs.jamf.com/technical-papers/jamf-pro/json-schema/10.26.0/Understanding_the_Structure_of_a_JSON_Schema_Manifest.html
        if fromDictionary["requiredInstallationDate"] is String {
            self.requiredInstallationDate = Utils().coerceStringToDate(dateString: fromDictionary["requiredInstallationDate"] as! String)
        } else {
            self.requiredInstallationDate = fromDictionary["requiredInstallationDate"] as? Date
        }
        self.aboutUpdateURL = fromDictionary["aboutUpdateURL"] as? String
        self.aboutUpdateURLs = generatedAboutUpdateURLs
        self.majorUpgradeAppPath = fromDictionary["majorUpgradeAppPath"] as? String
        self.requiredMinimumOSVersion = fromDictionary["requiredMinimumOSVersion"] as? String
    }

    init(data: Data) throws {
        self = try newJSONDecoder().decode(OSVersionRequirement.self, from: data)
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
        aboutUpdateURL: String?? = nil,
        aboutUpdateURLs: [AboutUpdateURL]?? = nil,
        majorUpgradeAppPath: String?? = nil,
        requiredInstallationDate: Date?? = nil,
        requiredMinimumOSVersion: String?? = nil,
        versionRules: [VersionRule]?? = nil
    ) -> OSVersionRequirement {
        return OSVersionRequirement(
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL,
            aboutUpdateURLs: aboutUpdateURLs ?? self.aboutUpdateURLs,
            majorUpgradeAppPath: majorUpgradeAppPath ?? self.majorUpgradeAppPath,
            requiredInstallationDate: requiredInstallationDate ?? self.requiredInstallationDate,
            requiredMinimumOSVersion: requiredMinimumOSVersion ?? self.requiredMinimumOSVersion,
            versionRules: versionRules ?? self.versionRules
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
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
        self = try newJSONDecoder().decode(AboutUpdateURL.self, from: data)
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
        language: String?? = nil,
        aboutUpdateURL: String?? = nil
    ) -> AboutUpdateURL {
        return AboutUpdateURL(
            language: language ?? self.language,
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - VersionRule
struct VersionRule: Codable {
    var majorUpgradeAppPath: String?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion: String?
    var rule: String?
}

// MARK: VersionRule convenience initializers and mutators

extension VersionRule {
    init(fromDictionary: [String:AnyObject]) {
        var generatedVersionRules = [VersionRule]()
        if let versionRules = fromDictionary["versionRules"] as? [[String:String]] {
            for each in versionRules {
                if let rule = each["rule"], let majorUpgradeAppPath = each["majorUpgradeAppPath"], let requiredInstallationDate = each["requiredInstallationDate"], let requiredMinimumOSVersion = each["requiredMinimumOSVersion"]  {
                    // We have to import the date as a string, now convert it to a Date
                    self.requiredInstallationDate = Utils().coerceStringToDate(dateString: fromDictionary["requiredInstallationDate"] as! String)
                    generatedVersionRules.append(VersionRule(majorUpgradeAppPath: majorUpgradeAppPath, requiredInstallationDate: Utils().coerceStringToDate(dateString: requiredInstallationDate), requiredMinimumOSVersion: requiredMinimumOSVersion, rule: rule))
                }
            }
        }
    }

    init(data: Data) throws {
        self = try newJSONDecoder().decode(VersionRule.self, from: data)
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
        majorUpgradeAppPath: String?? = nil,
        requiredInstallationDate: Date?? = nil,
        requiredMinimumOSVersion: String?? = nil,
        rule: String?? = nil
    ) -> VersionRule {
        return VersionRule(
            majorUpgradeAppPath: majorUpgradeAppPath ?? self.majorUpgradeAppPath,
            requiredInstallationDate: requiredInstallationDate ?? self.requiredInstallationDate,
            requiredMinimumOSVersion: requiredMinimumOSVersion ?? self.requiredMinimumOSVersion,
            rule: rule ?? self.rule
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - UserExperience
struct UserExperience: Codable {
    var allowUserQuitDeferrals: Bool?
    var allowedDeferrals, allowedDeferralsUntilForcedSecondaryQuitButton, approachingRefreshCycle, approachingWindowTime: Int?
    var elapsedRefreshCycle, imminentRefreshCycle, imminentWindowTime, initialRefreshCycle: Int?
    var maxRandomDelayInSeconds: Int?
    var noTimers: Bool?
    var nudgeRefreshCycle: Int?
    var randomDelay: Bool?
}

// MARK: UserExperience convenience initializers and mutators

extension UserExperience {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UserExperience.self, from: data)
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
        allowUserQuitDeferrals: Bool?? = nil,
        allowedDeferrals: Int?? = nil,
        allowedDeferralsUntilForcedSecondaryQuitButton: Int?? = nil,
        approachingRefreshCycle: Int?? = nil,
        approachingWindowTime: Int?? = nil,
        elapsedRefreshCycle: Int?? = nil,
        imminentRefreshCycle: Int?? = nil,
        imminentWindowTime: Int?? = nil,
        initialRefreshCycle: Int?? = nil,
        maxRandomDelayInSeconds: Int?? = nil,
        noTimers: Bool?? = nil,
        nudgeRefreshCycle: Int?? = nil,
        randomDelay: Bool?? = nil
    ) -> UserExperience {
        return UserExperience(
            allowUserQuitDeferrals: allowUserQuitDeferrals ?? self.allowUserQuitDeferrals,
            allowedDeferrals: allowedDeferrals ?? self.allowedDeferrals,
            allowedDeferralsUntilForcedSecondaryQuitButton: allowedDeferralsUntilForcedSecondaryQuitButton ?? self.allowedDeferralsUntilForcedSecondaryQuitButton,
            approachingRefreshCycle: approachingRefreshCycle ?? self.approachingRefreshCycle,
            approachingWindowTime: approachingWindowTime ?? self.approachingWindowTime,
            elapsedRefreshCycle: elapsedRefreshCycle ?? self.elapsedRefreshCycle,
            imminentRefreshCycle: imminentRefreshCycle ?? self.imminentRefreshCycle,
            imminentWindowTime: imminentWindowTime ?? self.imminentWindowTime,
            initialRefreshCycle: initialRefreshCycle ?? self.initialRefreshCycle,
            maxRandomDelayInSeconds: maxRandomDelayInSeconds ?? self.maxRandomDelayInSeconds,
            noTimers: noTimers ?? self.noTimers,
            nudgeRefreshCycle: nudgeRefreshCycle ?? self.nudgeRefreshCycle,
            randomDelay: randomDelay ?? self.randomDelay
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
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
        self = try newJSONDecoder().decode(UserInterface.self, from: data)
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
        actionButtonPath: String?? = nil,
        fallbackLanguage: String?? = nil,
        forceFallbackLanguage: Bool?? = nil,
        forceScreenShotIcon: Bool?? = nil,
        iconDarkPath: String?? = nil,
        iconLightPath: String?? = nil,
        screenShotDarkPath: String?? = nil,
        screenShotLightPath: String?? = nil,
        showDeferralCount: Bool?? = nil,
        simpleMode: Bool?? = nil,
        singleQuitButton: Bool?? = nil,
        updateElements: [UpdateElement]?? = nil
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
            singleQuitButton: singleQuitButton ?? self.simpleMode,
            updateElements: updateElements ?? self.updateElements
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - UpdateElement
struct UpdateElement: Codable {
    var language, actionButtonText, customDeferralButtonText, informationButtonText, mainContentHeader: String?
    var mainContentNote, mainContentSubHeader, mainContentText, mainHeader, oneDayDeferralButtonText: String?
    var oneHourDeferralButtonText, primaryQuitButtonText, secondaryQuitButtonText, subHeader: String?

    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case actionButtonText, customDeferralButtonText, informationButtonText, mainContentHeader, mainContentNote, mainContentSubHeader, mainContentText, mainHeader, oneDayDeferralButtonText, oneHourDeferralButtonText, primaryQuitButtonText, secondaryQuitButtonText, subHeader
    }
}

// MARK: Element convenience initializers and mutators

extension UpdateElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UpdateElement.self, from: data)
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
        language: String?? = nil,
        actionButtonText: String?? = nil,
        customDeferralButtonText: String?? = nil,
        informationButtonText: String?? = nil,
        mainContentHeader: String?? = nil,
        mainContentNote: String?? = nil,
        mainContentSubHeader: String?? = nil,
        mainContentText: String?? = nil,
        mainHeader: String?? = nil,
        oneDayDeferralButtonText: String?? = nil,
        oneHourDeferralButtonText: String?? = nil,
        primaryQuitButtonText: String?? = nil,
        secondaryQuitButtonText: String?? = nil,
        subHeader: String?? = nil
    ) -> UpdateElement {
        return UpdateElement(
            language: language ?? self.language,
            actionButtonText: actionButtonText ?? self.actionButtonText,
            customDeferralButtonText: customDeferralButtonText ?? self.customDeferralButtonText,
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
            subHeader: subHeader ?? self.subHeader
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
