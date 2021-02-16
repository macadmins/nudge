//
//  SoftwareUpdate.swift
//  Nudge
//
//  Created by Rory Murdock on 2/10/21.
//

import Foundation

class SoftwareUpdate {
    func List() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/softwareupdate"
        task.arguments = ["--list", "--all"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            let msg = "Error listing software updates"
            softwareupdateListLog.error("\(msg, privacy: .public)")
        }
        
        task.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        
        if task.terminationStatus != 0 {
            softwareupdateListLog.error("Error listing software updates: \(error, privacy: .public)")
            return error
        } else {
            softwareupdateListLog.info("\(output, privacy: .public)")
            return output
        }
        
    }
    
    func Download() {
        
        softwareupdateDownloadLog.info("enforceMinorUpdates: \(enforceMinorUpdates, privacy: .public)")

        if Utils().getCPUTypeString() == "Apple Silicon" {
            let msg = "Apple Silicon devices do not support automated softwareupdate calls. Please use MDM."
            softwareupdateListLog.info("\(msg, privacy: .public)")
            return
        }
        
        let softwareupdateList = self.List()
        
        if softwareupdateList.contains("restart") {
            let msg = "Starting softwareupdate download"
            softwareupdateListLog.info("\(msg, privacy: .public)")
            let task = Process()
            task.launchPath = "/usr/sbin/softwareupdate"
            task.arguments = ["--download", "--all"]

            let outputPipe = Pipe()
            let errorPipe = Pipe()

            task.standardOutput = outputPipe
            task.standardError = errorPipe

            do {
                try task.run()
            } catch {
                let msg = "Error downloading software updates"
                softwareupdateListLog.error("\(msg, privacy: .public)")
            }

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(decoding: outputData, as: UTF8.self)
            let error = String(decoding: errorData, as: UTF8.self)

            softwareupdateDownloadLog.info("\(output, privacy: .public)")
            softwareupdateDownloadLog.error("\(error, privacy: .public)")
        }
    }
}
