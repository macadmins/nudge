//
//  PreferenceTests.swift
//  NudgeTests
//
//  Created by groob on 3/5/22.
//

import Foundation
import XCTest

@testable import Nudge

class PreferenceTest: XCTestCase {

  func testTargetVersion() {
    let rule: [String: Any] = [
      "aboutUpdateURL": "https://apple.com",
      "requiredInstallationDate": "2021-07-30T00:00:00Z",
      "requiredMinimumOSVersion": "11.5.2",
      "targetedOSVersions": [
        "11.0",
        "11.0.1",
        "11.1",
        "11.2",
        "11.2.1",
        "11.2.2",
        "11.2.3",
        "11.3",
        "11.3.1",
        "11.4",
        "11.5",
        "11.5.1",
      ],
      "targetedOSVersionsRule": "default",

    ]
    let defaults: UserDefaults = .makeDefaults(requirements: [rule])
    let prefs = Preferences(
      defaults: defaults, systemVersion: OSVersion(major: 11, minor: 2, patch: 0))
    XCTAssertEqual("default", prefs.targetVersion().targetedOSVersionsRule)
  }
}

extension UserDefaults {

  static func makeDefaults(
    requirements: [[String: Any]]
  ) -> UserDefaults {
    let defaults = UserDefaults(suiteName: #file)!
    defaults.removePersistentDomain(forName: #file)

    defaults.set(requirements, forKey: "osVersionRequirements")
    return defaults
  }
}
