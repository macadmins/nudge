//
//  Logger.swift
//  Nudge
//
//  Created by Rory Murdock on 2/10/21.
//

import Foundation
import os

// TODO: Remove all .public calls from logs

// Logger Manager
struct LogManager {
    static private let bundleID = Bundle.main.bundleIdentifier ?? "com.github.macadmins.Nudge"

    static func createLogger(category: String) -> Logger {
        return Logger(subsystem: bundleID, category: category)
    }
}

// Usage of Logger Manager
let utilsLog = LogManager.createLogger(category: "utilities")
let osLog = LogManager.createLogger(category: "operating-system")
let loggingLog = LogManager.createLogger(category: "logging")
let prefsProfileLog = LogManager.createLogger(category: "preferences-profile")
let prefsJSONLog = LogManager.createLogger(category: "preferences-json")
let uiLog = LogManager.createLogger(category: "user-interface")
let softwareupdateListLog = LogManager.createLogger(category: "softwareupdate-list")
let softwareupdateDownloadLog = LogManager.createLogger(category: "softwareupdate-download")

// Log State
class LogState {
    var afterFirstLaunch = false
    var afterFirstRun = false
    var hasLoggedBundleMode = false
    var hasLoggedDemoMode = false
    var hasLoggedMajorOSVersion = false
    var hasLoggedMajorRequiredOSVersion = false
    var hasLoggedPastRequiredInstallationDate = false
    var hasLoggedRequireMajorUgprade = false
    var hasLoggedScreenshotIconMode = false
    var hasLoggedSimpleMode = false
    var hasLoggedUnitTestingMode = false
}

// NudgeLogger
class NudgeLogger {
    init() {
        loggingLog.debug("Starting log events")
    }
}
