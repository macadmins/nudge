//
//  Logger.swift
//  Nudge
//
//  Created by Rory Murdock on 2/10/21.
//

import Foundation
import os

let bundleID = Bundle.main.bundleIdentifier ?? "com.github.macadmins.Nudge"
let utilsLog = Logger(subsystem: bundleID, category: "utilities")
let osLog = Logger(subsystem: bundleID, category: "operating-system")
let loggingLog = Logger(subsystem: bundleID, category: "logging")
let prefsProfileLog = Logger(subsystem: bundleID, category: "preferences-profile")
let prefsJSONLog = Logger(subsystem: bundleID, category: "preferences-json")
let uiLog = Logger(subsystem: bundleID, category: "user-interface")
let softwareupdateListLog = Logger(subsystem: bundleID, category: "softwareupdate-list")
let softwareupdateDownloadLog = Logger(subsystem: bundleID, category: "softwareupdate-download")

class NudgeLogger {
    init() {
        loggingLog.debug("\("Starting log events", privacy: .public)")
    }
}
