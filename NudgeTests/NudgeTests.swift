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
    func coerceStringToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let formattedDate = dateFormatter.date(from: dateString) ?? Utils().getCurrentDate()
        return formattedDate
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

    // Machine is out of date and within requiredInstallationDate
    func testGracePeriodInTheMiddleOfNudgeEvent() {
        defaultPreferencesForTests["allowGracePeriods"] = true
        defaultPreferencesForTests["requiredInstallationDate"] = coerceStringToDate(dateString: "2022-02-01T00:00:00Z")
        defaultPreferencesForTests["requiredMinimumOSVersion"] = "99.99.99"
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            coerceStringToDate(dateString: "2022-02-01T00:00:00Z"),
            Utils().gracePeriodLogic(
                currentDate: coerceStringToDate(dateString: "2022-01-01T00:30:00Z"),
                testFileDate: coerceStringToDate(dateString: "2022-01-01T00:00:00Z")
            )
        )
    }

    // Machine is out of date and outside requiredInstallationDate, but just provisioned
    func testGracePeriodOutsideNudgeEvent() {
        defaultPreferencesForTests["allowGracePeriods"] = true
        defaultPreferencesForTests["requiredInstallationDate"] = coerceStringToDate(dateString: "2022-01-01T00:00:00Z")
        defaultPreferencesForTests["requiredMinimumOSVersion"] = "99.99.99"
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            coerceStringToDate(dateString: "2022-01-03T00:00:00Z"),
            Utils().gracePeriodLogic(
                currentDate: coerceStringToDate(dateString: "2022-01-02T00:30:00Z"),
                testFileDate: coerceStringToDate(dateString: "2022-01-02T00:00:00Z")
            )
        )
    }

    // Machine was provisioned, but the user ignored the grace period.
    // Code reverts back to initial date because UX doesn't matter
    func testGracePeriodUserIgnoringGracePeriod() {
        defaultPreferencesForTests["allowGracePeriods"] = true
        defaultPreferencesForTests["requiredInstallationDate"] = coerceStringToDate(dateString: "2022-01-01T00:00:00Z")
        defaultPreferencesForTests["requiredMinimumOSVersion"] = "99.99.99"
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            coerceStringToDate(dateString: "2022-01-01T00:00:00Z"),
            Utils().gracePeriodLogic(
                currentDate: coerceStringToDate(dateString: "2022-01-03T:00:00Z"),
                testFileDate: coerceStringToDate(dateString: "2022-01-01T00:00:00Z")
            )
        )
    }

    // Machine was provisioned, then sat on a shelf for months and now outside requiredInstallationDate
    // Your service desk should update the machine before handing it off instead to help the user
    func testGracePeriodSittingOnShelfForMonths() {
        defaultPreferencesForTests["allowGracePeriods"] = true
        defaultPreferencesForTests["requiredInstallationDate"] = coerceStringToDate(dateString: "2022-01-01T00:00:00Z")
        defaultPreferencesForTests["requiredMinimumOSVersion"] = "99.99.99"
        PrefsWrapper.prefsOverride = defaultPreferencesForTests
        XCTAssertEqual(
            coerceStringToDate(dateString: "2022-01-01T00:00:00Z"),
            Utils().gracePeriodLogic(
                currentDate: coerceStringToDate(dateString: "2022-06-01T00:00:00Z"),
                testFileDate: coerceStringToDate(dateString: "2021-12-01T00:00:00Z")
            )
        )
    }
}
