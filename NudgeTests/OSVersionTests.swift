//
//  OSVersionTests.swift
//  NudgeTests
//
//  Created by Victor Vrantchan on 2/5/21.
//

import Foundation
import XCTest
@testable import Nudge

class OSVersionTest: XCTestCase {
    func testCompare() {
        let a = OSVersion(major: 11, minor: 2, patch: 0)
        let b = OSVersion(major: 11, minor: 2, patch: 0)
        let c = OSVersion(major: 11, minor: 3, patch: 0)
        let d = OSVersion(major: 10, minor: 15, patch: 9999)

        XCTAssertEqual(a,b)
        XCTAssertNotEqual(a,c)
        XCTAssertGreaterThan(c,b)
        XCTAssertGreaterThanOrEqual(c,d)
        XCTAssertFalse(a < d, "BigSur is newer than Catalina")
    }

    func testParse() {
        let expected = OSVersion(major: 11, minor: 5, patch: 0)
        guard let actual = try? OSVersion("11.5") else {
            XCTFail("expected OSVersion to not fail parsing '11.5'")
            return
        }

        XCTAssertEqual(expected, actual)
    }
}
