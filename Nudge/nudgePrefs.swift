//
//  nudgePrefs.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import Foundation

// TODO: use CFPreferences to get mdm/mobileconfig logic and prioritize over json
struct nudgePrefs{
    func loadNudgePrefs() -> NudgePreferences? {
        let url = Utils().getJSONUrl()

        if url.contains("https://") || url.contains("http://") {
            if let json_url = URL(string: url) {
                if let data = try? Data(contentsOf: json_url) {
                    do {
                        let decodedData = try NudgePreferences(data: data)
                        return decodedData
                    } catch {
                        print(error)
                        return nil
                    }
                }
            }
        }

        guard let fileURL = URL(string: url) else {
            print("Could not find on-disk json")
            return nil
        }
        
        if Utils().demoModeEnabled() {
            return nil
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let content = try Data(contentsOf: fileURL)
                let decodedData = try NudgePreferences(data: content)
                return decodedData

            } catch let error {
                print(error)
                return nil
            }
        }
        return nil
    }
}

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
    var attemptToFetchMajorUpgrade, enableUMAD: Bool?
    var umadFeatures: UmadFeatures?
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
        attemptToFetchMajorUpgrade: Bool?? = nil,
        enableUMAD: Bool?? = nil,
        umadFeatures: UmadFeatures?? = nil
    ) -> OptionalFeatures {
        return OptionalFeatures(
            attemptToFetchMajorUpgrade: attemptToFetchMajorUpgrade ?? self.attemptToFetchMajorUpgrade,
            enableUMAD: enableUMAD ?? self.enableUMAD,
            umadFeatures: umadFeatures ?? self.umadFeatures
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - UmadFeatures
struct UmadFeatures: Codable {
    var alwaysShowManulEnrollment: Bool?
    var depScreenShotPath: String?
    var disableManualEnrollmentForDEP, enforceMDMInstallation: Bool?
    var manualEnrollmentPath, mdmInformationButtonPath: String?
    var mdmProfileIdentifier: String?
    var mdmRequiredInstallationDate: Date?
    var uamdmScreenShotPath: String?
}

// MARK: UmadFeatures convenience initializers and mutators

extension UmadFeatures {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UmadFeatures.self, from: data)
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
        alwaysShowManulEnrollment: Bool?? = nil,
        depScreenShotPath: String?? = nil,
        disableManualEnrollmentForDEP: Bool?? = nil,
        enforceMDMInstallation: Bool?? = nil,
        manualEnrollmentPath: String?? = nil,
        mdmInformationButtonPath: String?? = nil,
        mdmProfileIdentifier: String?? = nil,
        mdmRequiredInstallationDate: Date?? = nil,
        uamdmScreenShotPath: String?? = nil
    ) -> UmadFeatures {
        return UmadFeatures(
            alwaysShowManulEnrollment: alwaysShowManulEnrollment ?? self.alwaysShowManulEnrollment,
            depScreenShotPath: depScreenShotPath ?? self.depScreenShotPath,
            disableManualEnrollmentForDEP: disableManualEnrollmentForDEP ?? self.disableManualEnrollmentForDEP,
            enforceMDMInstallation: enforceMDMInstallation ?? self.enforceMDMInstallation,
            manualEnrollmentPath: manualEnrollmentPath ?? self.manualEnrollmentPath,
            mdmInformationButtonPath: mdmInformationButtonPath ?? self.mdmInformationButtonPath,
            mdmProfileIdentifier: mdmProfileIdentifier ?? self.mdmProfileIdentifier,
            mdmRequiredInstallationDate: mdmRequiredInstallationDate ?? self.mdmRequiredInstallationDate,
            uamdmScreenShotPath: uamdmScreenShotPath ?? self.uamdmScreenShotPath
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
    var majorUpgradeAppPath: String?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion: String?
    var targetedOSVersions: [String]?
}

// MARK: OSVersionRequirement convenience initializers and mutators

extension OSVersionRequirement {
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
        majorUpgradeAppPath: String?? = nil,
        requiredInstallationDate: Date?? = nil,
        requiredMinimumOSVersion: String?? = nil,
        targetedOSVersions: [String]?? = nil
    ) -> OSVersionRequirement {
        return OSVersionRequirement(
            aboutUpdateURL: aboutUpdateURL ?? self.aboutUpdateURL,
            majorUpgradeAppPath: majorUpgradeAppPath ?? self.majorUpgradeAppPath,
            requiredInstallationDate: requiredInstallationDate ?? self.requiredInstallationDate,
            requiredMinimumOSVersion: requiredMinimumOSVersion ?? self.requiredMinimumOSVersion,
            targetedOSVersions: targetedOSVersions ?? self.targetedOSVersions
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
    var allowedDeferrals, allowedDeferralsUntilForcedSecondaryQuitButton, approachingRefreshCycle, approachingWindowTime: Int?
    var elapsedRefreshCycle, imminentRefeshCycle, imminentWindowTime, initialRefreshCycle: Int?
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
        allowedDeferrals: Int?? = nil,
        allowedDeferralsUntilForcedSecondaryQuitButton: Int?? = nil,
        approachingRefreshCycle: Int?? = nil,
        approachingWindowTime: Int?? = nil,
        elapsedRefreshCycle: Int?? = nil,
        imminentRefeshCycle: Int?? = nil,
        imminentWindowTime: Int?? = nil,
        initialRefreshCycle: Int?? = nil,
        maxRandomDelayInSeconds: Int?? = nil,
        noTimers: Bool?? = nil,
        nudgeRefreshCycle: Int?? = nil,
        randomDelay: Bool?? = nil
    ) -> UserExperience {
        return UserExperience(
            allowedDeferrals: allowedDeferrals ?? self.allowedDeferrals,
            allowedDeferralsUntilForcedSecondaryQuitButton: allowedDeferralsUntilForcedSecondaryQuitButton ?? self.allowedDeferralsUntilForcedSecondaryQuitButton,
            approachingRefreshCycle: approachingRefreshCycle ?? self.approachingRefreshCycle,
            approachingWindowTime: approachingWindowTime ?? self.approachingWindowTime,
            elapsedRefreshCycle: elapsedRefreshCycle ?? self.elapsedRefreshCycle,
            imminentRefeshCycle: imminentRefeshCycle ?? self.imminentRefeshCycle,
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
    var forceScreenShotIcon: Bool?
    var iconDarkPath, iconLightPath, screenShotDarkPath, screenShotLightPath: String?
    var simpleMode: Bool?
    var umadElements, updateElements: [Element]?
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
        forceScreenShotIcon: Bool?? = nil,
        iconDarkPath: String?? = nil,
        iconLightPath: String?? = nil,
        screenShotDarkPath: String?? = nil,
        screenShotLightPath: String?? = nil,
        simpleMode: Bool?? = nil,
        umadElements: [Element]?? = nil,
        updateElements: [Element]?? = nil
    ) -> UserInterface {
        return UserInterface(
            forceScreenShotIcon: forceScreenShotIcon ?? self.forceScreenShotIcon,
            iconDarkPath: iconDarkPath ?? self.iconDarkPath,
            iconLightPath: iconLightPath ?? self.iconLightPath,
            screenShotDarkPath: screenShotDarkPath ?? self.screenShotDarkPath,
            screenShotLightPath: screenShotLightPath ?? self.screenShotLightPath,
            simpleMode: simpleMode ?? self.simpleMode,
            umadElements: umadElements ?? self.umadElements,
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

// MARK: - Element
struct Element: Codable {
    var language, actionButtonManualText, actionButtonText, actionButtonUAMDMText: String?
    var informationButtonText, mainContentHeader, mainContentNote, mainContentText: String?
    var mainContentUAMDMText, mainHeader, primaryQuitButtonText, secondaryQuitButtonText: String?
    var subHeader, mainContentSubHeader: String?

    enum CodingKeys: String, CodingKey {
        case language = "_language"
        case actionButtonManualText, actionButtonText, actionButtonUAMDMText, informationButtonText, mainContentHeader, mainContentNote, mainContentText, mainContentUAMDMText, mainHeader, primaryQuitButtonText, secondaryQuitButtonText, subHeader, mainContentSubHeader
    }
}

// MARK: Element convenience initializers and mutators

extension Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Element.self, from: data)
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
        actionButtonManualText: String?? = nil,
        actionButtonText: String?? = nil,
        actionButtonUAMDMText: String?? = nil,
        informationButtonText: String?? = nil,
        mainContentHeader: String?? = nil,
        mainContentNote: String?? = nil,
        mainContentText: String?? = nil,
        mainContentUAMDMText: String?? = nil,
        mainHeader: String?? = nil,
        primaryQuitButtonText: String?? = nil,
        secondaryQuitButtonText: String?? = nil,
        subHeader: String?? = nil,
        mainContentSubHeader: String?? = nil
    ) -> Element {
        return Element(
            language: language ?? self.language,
            actionButtonManualText: actionButtonManualText ?? self.actionButtonManualText,
            actionButtonText: actionButtonText ?? self.actionButtonText,
            actionButtonUAMDMText: actionButtonUAMDMText ?? self.actionButtonUAMDMText,
            informationButtonText: informationButtonText ?? self.informationButtonText,
            mainContentHeader: mainContentHeader ?? self.mainContentHeader,
            mainContentNote: mainContentNote ?? self.mainContentNote,
            mainContentText: mainContentText ?? self.mainContentText,
            mainContentUAMDMText: mainContentUAMDMText ?? self.mainContentUAMDMText,
            mainHeader: mainHeader ?? self.mainHeader,
            primaryQuitButtonText: primaryQuitButtonText ?? self.primaryQuitButtonText,
            secondaryQuitButtonText: secondaryQuitButtonText ?? self.secondaryQuitButtonText,
            subHeader: subHeader ?? self.subHeader,
            mainContentSubHeader: mainContentSubHeader ?? self.mainContentSubHeader
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
