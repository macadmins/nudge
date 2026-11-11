//
//  NudgeTests.swift
//  NudgeTests
//
//  Created by Erik Gomez on 2/2/21.
//

import XCTest
@testable import Nudge

var defaultPreferencesForTests = [:] as [String : Any]

class NudgeTests: XCTestCase {
    private var savedOverrides: [String: Any]?
    func coerceStringToDate(dateString: String) -> Date {
        DateManager().dateFormatterISO8601.date(from: dateString) ?? DateManager().getCurrentDate()
    }

    override func setUp() {
        super.setUp()
        savedOverrides = PrefsWrapper.prefsOverride
        defaultPreferencesForTests = [:]
    }

    override func tearDown() {
        PrefsWrapper.prefsOverride = savedOverrides
        defaultPreferencesForTests = [:]
        super.tearDown()
    }

    func testAllowGracePeriods() {
        defaultPreferencesForTests["allowGracePeriods"] = true
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            true,
            PrefsWrapper.allowGracePeriods
        )
    }

    func testRequiredMinimumOSVersion() {
        defaultPreferencesForTests["requiredMinimumOSVersion"] = "99.99.99"
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            "99.99.99",
            PrefsWrapper.requiredMinimumOSVersion
        )
    }

    func testRequiredInstallationDateDemoMode() {
        defaultPreferencesForTests["requiredInstallationDate"] = Date(timeIntervalSince1970: 0)
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            Date(timeIntervalSince1970: 0),
            PrefsWrapper.requiredInstallationDate
        )
    }

    func testRequiredInstallationDate() {
        let testDate = coerceStringToDate(dateString: "2022-02-28T00:00:00Z")
        defaultPreferencesForTests["requiredInstallationDate"] = testDate
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            testDate,
            PrefsWrapper.requiredInstallationDate
        )
    }

}

// Each test owns its preference suite and restores all shared app configuration.
class GracePeriodPolicyTests: XCTestCase {
    private var savedOverrides: [String: Any]?
    private var savedProfile: [String: Any]?
    private var savedJSON: UserExperience?
    private var savedOSProfile: OSVersionRequirement?
    private var savedOSJSON: OSVersionRequirement?
    private var savedUIProfile: [String: Any]?
    private var savedDeadline = Date()
    private var savedVersion = ""
    private var savedShouldExit = false
    private var marker: URL!
    private var defaults: UserDefaults!
    private var suiteName = ""
    private let creationDate = Date(timeIntervalSince1970: 1_800_000_000)
    private var eventDeadline: Date { creationDate.addingTimeInterval(2 * 86400) }
    private var graceDeadline: Date { creationDate.addingTimeInterval(14 * 86400) }

    override func setUpWithError() throws {
        savedOverrides = PrefsWrapper.prefsOverride
        savedProfile = UserExperienceVariables.userExperienceProfile
        savedJSON = UserExperienceVariables.userExperienceJSON
        savedOSProfile = OSVersionRequirementVariables.osVersionRequirementsProfile
        savedOSJSON = OSVersionRequirementVariables.osVersionRequirementsJSON
        savedUIProfile = UserInterfaceVariables.userInterfaceProfile
        savedDeadline = requiredInstallationDate
        savedVersion = nudgePrimaryState.requiredMinimumOSVersion
        savedShouldExit = nudgePrimaryState.shouldExit
        suiteName = "com.github.macadmins.Nudge.tests." + UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        marker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data().write(to: marker)
        PrefsWrapper.prefsOverride = ["allowGracePeriods": true, "requiredMinimumOSVersion": "latest-minor"]
        UserExperienceVariables.userExperienceProfile = [
            "gracePeriodInstallDelay": 336,
            "gracePeriodLaunchDelay": 0,
            "gracePeriodPath": marker.path
        ]
        UserExperienceVariables.userExperienceJSON = nil
        OSVersionRequirementVariables.osVersionRequirementsProfile = nil
        OSVersionRequirementVariables.osVersionRequirementsJSON = nil
        nudgePrimaryState.requiredMinimumOSVersion = "15.7.9"
        nudgePrimaryState.shouldExit = false
    }

    override func tearDownWithError() throws {
        PrefsWrapper.prefsOverride = savedOverrides
        UserExperienceVariables.userExperienceProfile = savedProfile
        UserExperienceVariables.userExperienceJSON = savedJSON
        OSVersionRequirementVariables.osVersionRequirementsProfile = savedOSProfile
        OSVersionRequirementVariables.osVersionRequirementsJSON = savedOSJSON
        UserInterfaceVariables.userInterfaceProfile = savedUIProfile
        requiredInstallationDate = savedDeadline
        nudgePrimaryState.requiredMinimumOSVersion = savedVersion
        nudgePrimaryState.shouldExit = savedShouldExit
        defaults?.removePersistentDomain(forName: suiteName)
        if let marker = marker, FileManager.default.fileExists(atPath: marker.path) {
            try FileManager.default.removeItem(at: marker)
        }
    }

    @discardableResult
    private func launch(age: TimeInterval, deadline: Date? = nil, markerDate: Date? = nil) -> Date {
        // Every real launch begins with the unmodified configuration/SOFA deadline.
        requiredInstallationDate = deadline ?? eventDeadline
        nudgePrimaryState.shouldExit = false
        let result = AppStateManager().gracePeriodLogic(currentDate: creationDate.addingTimeInterval(age), testFileDate: markerDate ?? creationDate, defaults: defaults)
        if !nudgePrimaryState.shouldExit {
            XCTAssertEqual(result, requiredInstallationDate)
        }
        return result
    }

    func testFirstEventExtendsFutureDeadlineFromMarker() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
    }

    func testFirstEventAtDeadlineStillReceivesGrace() {
        XCTAssertEqual(launch(age: 2 * 86400), graceDeadline)
    }

    func testFirstEventOverdueUsesMarkerRatherThanLaunchTime() {
        XCTAssertEqual(launch(age: 3 * 86400), graceDeadline)
    }

    func testDeadlinePersistsAcrossRelaunchAndExpiry() throws {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        for age in [14 * 86400 - 1, 14 * 86400, 14 * 86400 + 1, 30 * 86400] {
            XCTAssertEqual(launch(age: Double(age)), graceDeadline)
        }
    }

    func testLaterOriginalDeadlineIsNeverShortened() {
        let laterDeadline = creationDate.addingTimeInterval(30 * 86400)
        XCTAssertEqual(launch(age: 0, deadline: laterDeadline), laterDeadline)
        XCTAssertEqual(launch(age: 31 * 86400, deadline: laterDeadline), laterDeadline)
    }

    func testFirstLaunchBeforeExpiryQualifies() {
        XCTAssertEqual(launch(age: 14 * 86400 - 1), graceDeadline)
    }

    func testFirstLaunchAtExpiryDoesNotQualifyLater() {
        XCTAssertEqual(launch(age: 14 * 86400), eventDeadline)
        XCTAssertEqual(launch(age: 14 * 86400 + 1), eventDeadline)
    }

    func testFirstLaunchMonthsAfterProvisioningDoesNotQualify() {
        XCTAssertEqual(launch(age: 90 * 86400), eventDeadline)
    }

    func testTighterDeadlineForSameVersionEndsGracePermanently() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        let tighterDeadline = creationDate.addingTimeInterval(86400)
        XCTAssertEqual(launch(age: 3600, deadline: tighterDeadline), tighterDeadline)
        XCTAssertEqual(launch(age: 7200, deadline: tighterDeadline), tighterDeadline)
        XCTAssertEqual(launch(age: 10800), eventDeadline) // Reverting does not resurrect grace.
    }

    func testResolvedSOFAVersionChangeEndsGrace() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        nudgePrimaryState.requiredMinimumOSVersion = "15.7.10"
        XCTAssertEqual(launch(age: 3600), eventDeadline)
    }

    func testSLAChangeEndsGraceEvenWithSameEffectiveDeadline() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        OSVersionRequirementVariables.osVersionRequirementsProfile = OSVersionRequirement(standardMinorUpdateSLA: 7)
        XCTAssertEqual(launch(age: 3600), eventDeadline)
    }

    func testConfiguredDeadlineChangeEndsGraceEvenWithSameEffectiveDeadline() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        PrefsWrapper.prefsOverride?["requiredInstallationDate"] = eventDeadline
        XCTAssertEqual(launch(age: 3600), eventDeadline)
    }

    func testTextAndAppearanceChangesKeepGrace() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        UserInterfaceVariables.userInterfaceProfile = ["simpleMode": true, "updateElements": [["mainContentText": "New text"]]]
        UserExperienceVariables.userExperienceProfile?["randomDelay"] = false
        XCTAssertEqual(launch(age: 3600), graceDeadline)
    }

    func testGraceSettingChangeEndsGrace() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        UserExperienceVariables.userExperienceProfile?["gracePeriodInstallDelay"] = 500
        XCTAssertEqual(launch(age: 3600), eventDeadline)
    }

    func testDisablingAndReenablingDoesNotRestartGrace() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = false
        XCTAssertEqual(launch(age: 3600), eventDeadline)
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = true
        XCTAssertEqual(launch(age: 7200), eventDeadline)
    }

    func testLaunchGraceRecordsEventBeforeExiting() {
        UserExperienceVariables.userExperienceProfile?["gracePeriodLaunchDelay"] = 1
        launch(age: 3599)
        XCTAssertTrue(nudgePrimaryState.shouldExit)
        for age in [3600, 3601, 15 * 86400] {
            XCTAssertEqual(launch(age: Double(age)), graceDeadline.addingTimeInterval(3600))
            XCTAssertFalse(nudgePrimaryState.shouldExit)
        }
    }

    func testChangedEventDuringLaunchGraceDoesNotGetInstallationGrace() {
        UserExperienceVariables.userExperienceProfile?["gracePeriodLaunchDelay"] = 1
        launch(age: 60)
        XCTAssertTrue(nudgePrimaryState.shouldExit)
        nudgePrimaryState.requiredMinimumOSVersion = "15.7.10"
        XCTAssertEqual(launch(age: 3600), eventDeadline)
    }

    func testNewMarkerStartsNewDeployment() {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        nudgePrimaryState.requiredMinimumOSVersion = "15.7.10"
        XCTAssertEqual(launch(age: 3600), eventDeadline)
        let newCreation = creationDate.addingTimeInterval(7200)
        XCTAssertEqual(launch(age: 7200, markerDate: newCreation), newCreation.addingTimeInterval(14 * 86400))
    }

    func testKnownEarlierVersionCannotReceiveFirstEventGraceOnUpgrade() {
        defaults.set("15.7.8", forKey: "requiredMinimumOSVersion")
        XCTAssertEqual(launch(age: 0), eventDeadline)
    }

    func testMissingMarkerKeepsSOFADeadline() throws {
        try FileManager.default.removeItem(at: marker)
        XCTAssertEqual(launch(age: 0), eventDeadline)
    }

    func testInitiallyDisabledEventCannotGainGraceAfterConfigurationChange() {
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = false
        XCTAssertEqual(launch(age: 0), eventDeadline)
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = true
        let tighterDeadline = creationDate.addingTimeInterval(86400)
        XCTAssertEqual(launch(age: 3600, deadline: tighterDeadline), tighterDeadline)
        XCTAssertEqual(launch(age: 7200), eventDeadline)
    }

    func testMissingMarkerKeepsRecordedDeadlineAfterExpiry() throws {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        try FileManager.default.removeItem(at: marker)
        XCTAssertEqual(launch(age: 15 * 86400), graceDeadline)
    }

    func testChangedEventWhileMarkerUnavailableCannotReviveGrace() throws {
        XCTAssertEqual(launch(age: 0), graceDeadline)
        let movedMarker = marker.appendingPathExtension("moved")
        try FileManager.default.moveItem(at: marker, to: movedMarker)
        defer { try? FileManager.default.removeItem(at: movedMarker) }
        let tighterDeadline = creationDate.addingTimeInterval(86400)
        XCTAssertEqual(launch(age: 3600, deadline: tighterDeadline), tighterDeadline)
        try FileManager.default.moveItem(at: movedMarker, to: marker)
        XCTAssertEqual(launch(age: 7200), eventDeadline)
    }

    func testUnconfiguredLaunchDoesNotConsumeFirstEvent() {
        nudgePrimaryState.requiredMinimumOSVersion = "0.0"
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = false
        XCTAssertEqual(launch(age: 0), eventDeadline)
        nudgePrimaryState.requiredMinimumOSVersion = "15.7.9"
        PrefsWrapper.prefsOverride?["allowGracePeriods"] = true
        XCTAssertEqual(launch(age: 3600), graceDeadline)
    }

    func testCorruptSavedStateDoesNotGrantFreshGrace() {
        defaults.set(Data("invalid".utf8), forKey: "firstRunGracePeriodState")
        XCTAssertEqual(launch(age: 0), eventDeadline)
    }
}

class DisplayManagerTests: XCTestCase {
    private let builtIn: CGDirectDisplayID = 1
    private let external: CGDirectDisplayID = 2
    private let builtInOnly = CGRect(x: 0, y: 0, width: 1496, height: 967)
    private let externalOnly = CGRect(x: 0, y: 0, width: 2560, height: 1440)
    private let externalRightOfBuiltIn = CGRect(x: 1496, y: 0, width: 2560, height: 1440)

    private func configuration(_ displays: [(id: CGDirectDisplayID, bounds: CGRect)]) -> DisplayManager.Configuration {
        DisplayManager.Configuration(displays: displays)
    }

    func testUnchangedDisplaysDoNotRestart() {
        XCTAssertEqual(configuration([(builtIn, builtInOnly)]), configuration([(builtIn, builtInOnly)]))
    }

    func testDisplayReportingOrderDoesNotRestart() {
        XCTAssertEqual(
            configuration([(builtIn, builtInOnly), (external, externalRightOfBuiltIn)]),
            configuration([(external, externalRightOfBuiltIn), (builtIn, builtInOnly)])
        )
    }

    func testDockingWithLidClosedRestarts() {
        // Launched undocked on the built-in display, woke docked with only the external display.
        XCTAssertNotEqual(configuration([(builtIn, builtInOnly)]), configuration([(external, externalOnly)]))
    }

    func testAddedDisplayRestarts() {
        XCTAssertNotEqual(
            configuration([(builtIn, builtInOnly)]),
            configuration([(builtIn, builtInOnly), (external, externalRightOfBuiltIn)])
        )
    }

    func testRemovedDisplayRestarts() {
        XCTAssertNotEqual(
            configuration([(builtIn, builtInOnly), (external, externalRightOfBuiltIn)]),
            configuration([(builtIn, builtInOnly)])
        )
    }

    func testResolutionChangeRestarts() {
        XCTAssertNotEqual(
            configuration([(external, externalOnly)]),
            configuration([(external, CGRect(x: 0, y: 0, width: 1600, height: 900))])
        )
    }

    func testArrangementChangeRestarts() {
        XCTAssertNotEqual(
            configuration([(builtIn, builtInOnly), (external, externalRightOfBuiltIn)]),
            configuration([(builtIn, builtInOnly), (external, CGRect(x: -2560, y: 0, width: 2560, height: 1440))])
        )
    }

    func testRelaunchArgumentsAppendDisableRandomDelay() {
        let arguments = ["/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge", "-json-url", "https://example.com/nudge.json"]
        XCTAssertEqual(DisplayManager().relaunchArguments(from: arguments), arguments + ["-disable-random-delay"])
    }

    func testRelaunchArgumentsDoNotDuplicateDisableRandomDelay() {
        let arguments = ["/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge", "-disable-random-delay", "-json-url", "https://example.com/nudge.json"]
        XCTAssertEqual(DisplayManager().relaunchArguments(from: arguments), arguments)
    }
}
