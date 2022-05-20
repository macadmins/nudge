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
        let msg = "Starting log events"
        loggingLog.debug("\(msg, privacy: .public)")
    }
}

// TODO: com.apple.donotdisturb with isScreenShared seems to cover Zoom, Google Meets via Chrome, QuickTime Player Recording and CMD+SHIFT+5 Recording.
// TODO: This method does not seem to respect Google Meets tab or window sharing, probably because of what Chrome itself does here.
class LogReader {
    func Stream() {
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = ["stream", "--predicate", "(subsystem contains \"com.apple.donotdisturb\" and composedMessage contains \"isScreenShared\") or (subsystem contains \"com.apple.UVCExtension\" and composedMessage contains \"Post PowerLog\" OR eventMessage contains \"Post event kCameraStream\")", "--style", "ndjson"]

        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outHandle, queue: nil)
        {
            notification -> Void in
            let data = outHandle.availableData
            if data.count > 177 {
                do {
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    if let eventMessage : NSString = jsonResult["eventMessage"] as? NSString {
                        if eventMessage.contains("\"VDCAssistant_Power_State\" = On") {
                            nudgePrimaryState.cameraOn = true
                        }
                        if eventMessage.contains("\"VDCAssistant_Power_State\" = Off") {
                            nudgePrimaryState.cameraOn = false
                        }
                        if eventMessage.contains("isScreenShared=1") {
                            nudgePrimaryState.isScreenSharing = true
                        }
                        if eventMessage.contains("isScreenShared=0") {
                            nudgePrimaryState.isScreenSharing = false
                        }
                    }
                } catch {}
                outHandle.waitForDataInBackgroundAndNotify()
            } else {
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
        task.launch()
    }

    func cameraShow() {
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = ["show", "--last", "\(logReferralTime)m", "--predicate", "subsystem contains \"com.apple.UVCExtension\" and composedMessage contains \"Post PowerLog\" OR eventMessage contains \"Post event kCameraStream\"", "--style", "json"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            let msg = "Error returning log show"
            utilsLog.error("\(msg, privacy: .public)")
        }

        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let error = String(decoding: errorData, as: UTF8.self)

        if task.terminationStatus != 0 {
            utilsLog.error("Error returning log show: \(error, privacy: .public)")
        } else {
            do {
                let jsonResult: NSArray = try JSONSerialization.jsonObject(with: outputData, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
                if let lastResult = jsonResult.lastObject as? NSDictionary {
                    if let eventMessage : NSString = lastResult["eventMessage"] as? NSString {
                        if eventMessage.contains("\"VDCAssistant_Power_State\" = On") {
                            nudgePrimaryState.cameraOn = true
                        }
                        if eventMessage.contains("\"VDCAssistant_Power_State\" = Off") {
                            nudgePrimaryState.cameraOn = false
                        }
                    }
                } else {
                    utilsLog.info("No current camera activity")
                }
            } catch {}
        }
    }
    func screenSharingShow() {
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = ["show", "--last", "\(logReferralTime)m", "--predicate", "subsystem contains \"com.apple.donotdisturb\" and composedMessage contains \"isScreenShared\"", "--style", "json"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            let msg = "Error returning log show"
            utilsLog.error("\(msg, privacy: .public)")
        }

        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let error = String(decoding: errorData, as: UTF8.self)

        if task.terminationStatus != 0 {
            utilsLog.error("Error returning log show: \(error, privacy: .public)")
        } else {
            do {
                let jsonResult: NSArray = try JSONSerialization.jsonObject(with: outputData, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
                if let lastResult = jsonResult.lastObject as? NSDictionary {
                    if let eventMessage : NSString = lastResult["eventMessage"] as? NSString {
                        if eventMessage.contains("isScreenShared=1") {
                            nudgePrimaryState.isScreenSharing = true
                        }
                        if eventMessage.contains("isScreenShared=0") {
                            nudgePrimaryState.isScreenSharing = false
                        }
                    }
                } else {
                    utilsLog.info("No current camera activity")
                }
            } catch {}
        }
    }
}
