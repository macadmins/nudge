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
        // For Greg Neagle
        let local_url = "file:///Library/Preferences/com.github.macadmins.Nudge.json"

        guard let fileURL = URL(string: local_url) else {
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
    var allowedDeferrals, allowedDeferralsUntilForcedSecondaryQuitButton: Int?
    var attemptToFetchMajorUpgrade, enforceMinorUpdates: Bool?
    var iconDarkPath, iconLightPath: String?
    var informationButtonPath: String?
    var maxRandomDelayInSeconds: Int?
    var mdmFeatures: MdmFeatures?
    var noTimers, randomDelay: Bool?
    var screenShotDarkPath, screenShotLightPath: String?
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
        allowedDeferrals: Int?? = nil,
        allowedDeferralsUntilForcedSecondaryQuitButton: Int?? = nil,
        attemptToFetchMajorUpgrade: Bool?? = nil,
        enforceMinorUpdates: Bool?? = nil,
        iconDarkPath: String?? = nil,
        iconLightPath: String?? = nil,
        informationButtonPath: String?? = nil,
        maxRandomDelayInSeconds: Int?? = nil,
        mdmFeatures: MdmFeatures?? = nil,
        noTimers: Bool?? = nil,
        randomDelay: Bool?? = nil,
        screenShotDarkPath: String?? = nil,
        screenShotLightPath: String?? = nil
    ) -> OptionalFeatures {
        return OptionalFeatures(
            allowedDeferrals: allowedDeferrals ?? self.allowedDeferrals,
            allowedDeferralsUntilForcedSecondaryQuitButton: allowedDeferralsUntilForcedSecondaryQuitButton ?? self.allowedDeferralsUntilForcedSecondaryQuitButton,
            attemptToFetchMajorUpgrade: attemptToFetchMajorUpgrade ?? self.attemptToFetchMajorUpgrade,
            enforceMinorUpdates: enforceMinorUpdates ?? self.enforceMinorUpdates,
            iconDarkPath: iconDarkPath ?? self.iconDarkPath,
            iconLightPath: iconLightPath ?? self.iconLightPath,
            informationButtonPath: informationButtonPath ?? self.informationButtonPath,
            maxRandomDelayInSeconds: maxRandomDelayInSeconds ?? self.maxRandomDelayInSeconds,
            mdmFeatures: mdmFeatures ?? self.mdmFeatures,
            noTimers: noTimers ?? self.noTimers,
            randomDelay: randomDelay ?? self.randomDelay,
            screenShotDarkPath: screenShotDarkPath ?? self.screenShotDarkPath,
            screenShotLightPath: screenShotLightPath ?? self.screenShotLightPath
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - MdmFeatures
struct MdmFeatures: Codable {
    var alwaysShowManulEnrollment: Bool?
    var depScreenShotPath: String?
    var disableManualEnrollmentForDEP, enforceMDMInstallation: Bool?
    var mdmInformationButtonPath, manualEnrollmentPath: String?
    var mdmProfileIdentifier: String?
    var mdmRequiredInstallationDate: Date?
    var uamdmScreenShotPath: String?
}

// MARK: MdmFeatures convenience initializers and mutators

extension MdmFeatures {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MdmFeatures.self, from: data)
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
        mdmInformationButtonPath: String?? = nil,
        manualEnrollmentPath: String?? = nil,
        mdmProfileIdentifier: String?? = nil,
        mdmRequiredInstallationDate: Date?? = nil,
        uamdmScreenShotPath: String?? = nil
    ) -> MdmFeatures {
        return MdmFeatures(
            alwaysShowManulEnrollment: alwaysShowManulEnrollment ?? self.alwaysShowManulEnrollment,
            depScreenShotPath: depScreenShotPath ?? self.depScreenShotPath,
            disableManualEnrollmentForDEP: disableManualEnrollmentForDEP ?? self.disableManualEnrollmentForDEP,
            enforceMDMInstallation: enforceMDMInstallation ?? self.enforceMDMInstallation,
            mdmInformationButtonPath: mdmInformationButtonPath ?? self.mdmInformationButtonPath,
            manualEnrollmentPath: manualEnrollmentPath ?? self.manualEnrollmentPath,
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
    var majorUpgradeAppPath: String?
    var requiredInstallationDate: Date?
    var requiredMinimumOSVersion: String?
    var targetedOSVersions: [String]?
}

// MARK: OSVersionRequirement convenience initializers and mutators

extension OSVersionRequirement {
    enum Keys: String {
        case majorUpgradeAppPath,
             requiredInstallationDate,
             requiredMinimumOSVersion,
             targetedOSVersions
    }
    
//    init(_ dict: [String: Any]) throws {
//        self.majorUpgradeAppPath = try dict.nudgeDefault(Keys.majorUpgradeAppPath.rawValue)
//        self.requiredInstallationDate = try dict.nudgeDefault(Keys.requiredInstallationDate.rawValue)
//        self.requiredMinimumOSVersion = try dict.nudgeDefault(Keys.requiredMinimumOSVersion.rawValue)
//        self.targetedOSVersions = try dict.nudgeDefault(Keys.targetedOSVersions.rawValue)
//    }
    
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
        majorUpgradeAppPath: String?? = nil,
        requiredInstallationDate: Date?? = nil,
        requiredMinimumOSVersion: String?? = nil,
        targetedOSVersions: [String]?? = nil
    ) -> OSVersionRequirement {
        return OSVersionRequirement(
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
    var approachingRefreshCycle, approachingWindowTime, elapsedRefreshCycle, imminentRefeshCycle: Int?
    var imminentWindowTime, initialRefreshCycle, nudgeRefreshCycle: Int?
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
        approachingRefreshCycle: Int?? = nil,
        approachingWindowTime: Int?? = nil,
        elapsedRefreshCycle: Int?? = nil,
        imminentRefeshCycle: Int?? = nil,
        imminentWindowTime: Int?? = nil,
        initialRefreshCycle: Int?? = nil,
        nudgeRefreshCycle: Int?? = nil
    ) -> UserExperience {
        return UserExperience(
            approachingRefreshCycle: approachingRefreshCycle ?? self.approachingRefreshCycle,
            approachingWindowTime: approachingWindowTime ?? self.approachingWindowTime,
            elapsedRefreshCycle: elapsedRefreshCycle ?? self.elapsedRefreshCycle,
            imminentRefeshCycle: imminentRefeshCycle ?? self.imminentRefeshCycle,
            imminentWindowTime: imminentWindowTime ?? self.imminentWindowTime,
            initialRefreshCycle: initialRefreshCycle ?? self.initialRefreshCycle,
            nudgeRefreshCycle: nudgeRefreshCycle ?? self.nudgeRefreshCycle
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
    var mdmElements: MdmElements?
    var updateElements: UpdateElements?
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
        mdmElements: MdmElements?? = nil,
        updateElements: UpdateElements?? = nil
    ) -> UserInterface {
        return UserInterface(
            mdmElements: mdmElements ?? self.mdmElements,
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

// MARK: - MdmElements
struct MdmElements: Codable {
    var actionButtonManualText, actionButtonText, actionButtonUAMDMText, informationButtonText: String?
    var lowerHeader, lowerHeaderDEPFailure, lowerHeaderManual, lowerHeaderUAMDMFailure: String?
    var lowerSubHeader, lowerSubHeaderDEPFailure, lowerSubHeaderManual, lowerSubHeaderUAMDMFailure: String?
    var mainContentHeader, mainContentText, mainContentUAMDMText, mainHeader: String?
    var primaryQuitButtonText, secondaryQuitButtonText, subHeader: String?
}

// MARK: MdmElements convenience initializers and mutators

extension MdmElements {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MdmElements.self, from: data)
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
        actionButtonManualText: String?? = nil,
        actionButtonText: String?? = nil,
        actionButtonUAMDMText: String?? = nil,
        informationButtonText: String?? = nil,
        lowerHeader: String?? = nil,
        lowerHeaderDEPFailure: String?? = nil,
        lowerHeaderManual: String?? = nil,
        lowerHeaderUAMDMFailure: String?? = nil,
        lowerSubHeader: String?? = nil,
        lowerSubHeaderDEPFailure: String?? = nil,
        lowerSubHeaderManual: String?? = nil,
        lowerSubHeaderUAMDMFailure: String?? = nil,
        mainContentHeader: String?? = nil,
        mainContentText: String?? = nil,
        mainContentUAMDMText: String?? = nil,
        mainHeader: String?? = nil,
        primaryQuitButtonText: String?? = nil,
        secondaryQuitButtonText: String?? = nil,
        subHeader: String?? = nil
    ) -> MdmElements {
        return MdmElements(
            actionButtonManualText: actionButtonManualText ?? self.actionButtonManualText,
            actionButtonText: actionButtonText ?? self.actionButtonText,
            actionButtonUAMDMText: actionButtonUAMDMText ?? self.actionButtonUAMDMText,
            informationButtonText: informationButtonText ?? self.informationButtonText,
            lowerHeader: lowerHeader ?? self.lowerHeader,
            lowerHeaderDEPFailure: lowerHeaderDEPFailure ?? self.lowerHeaderDEPFailure,
            lowerHeaderManual: lowerHeaderManual ?? self.lowerHeaderManual,
            lowerHeaderUAMDMFailure: lowerHeaderUAMDMFailure ?? self.lowerHeaderUAMDMFailure,
            lowerSubHeader: lowerSubHeader ?? self.lowerSubHeader,
            lowerSubHeaderDEPFailure: lowerSubHeaderDEPFailure ?? self.lowerSubHeaderDEPFailure,
            lowerSubHeaderManual: lowerSubHeaderManual ?? self.lowerSubHeaderManual,
            lowerSubHeaderUAMDMFailure: lowerSubHeaderUAMDMFailure ?? self.lowerSubHeaderUAMDMFailure,
            mainContentHeader: mainContentHeader ?? self.mainContentHeader,
            mainContentText: mainContentText ?? self.mainContentText,
            mainContentUAMDMText: mainContentUAMDMText ?? self.mainContentUAMDMText,
            mainHeader: mainHeader ?? self.mainHeader,
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

// MARK: - UpdateElements
struct UpdateElements: Codable {
    var actionButtonText, informationButtonText, lowerHeader, lowerSubHeader: String?
    var mainContentHeader, mainContentText, mainHeader, primaryQuitButtonText: String?
    var secondaryQuitButtonText, subHeader: String?
}

// MARK: UpdateElements convenience initializers and mutators

extension UpdateElements {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UpdateElements.self, from: data)
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
        actionButtonText: String?? = nil,
        informationButtonText: String?? = nil,
        lowerHeader: String?? = nil,
        lowerSubHeader: String?? = nil,
        mainContentHeader: String?? = nil,
        mainContentText: String?? = nil,
        mainHeader: String?? = nil,
        primaryQuitButtonText: String?? = nil,
        secondaryQuitButtonText: String?? = nil,
        subHeader: String?? = nil
    ) -> UpdateElements {
        return UpdateElements(
            actionButtonText: actionButtonText ?? self.actionButtonText,
            informationButtonText: informationButtonText ?? self.informationButtonText,
            lowerHeader: lowerHeader ?? self.lowerHeader,
            lowerSubHeader: lowerSubHeader ?? self.lowerSubHeader,
            mainContentHeader: mainContentHeader ?? self.mainContentHeader,
            mainContentText: mainContentText ?? self.mainContentText,
            mainHeader: mainHeader ?? self.mainHeader,
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
