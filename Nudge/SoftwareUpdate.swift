//
//  SoftwareUpdate.swift
//  Nudge
//
//  Created by Rory Murdock on 10/2/21.
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
            softwareupdateListLog.error("Error listing software updates, privacy: .public)")
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
        softwareupdateDownloadLog.info("enforceMinorUpdates: \(enforceMinorUpdates), privacy: .public)")

        if !enforceMinorUpdates {
            return
        }

        if Utils().getCPUTypeString() == "Apple Silicon" {
            softwareupdateDownloadLog.info("Apple Silicon devices do not support automated softwareupdate calls. Please use MDM., privacy: .public)")
            return
        }
        
        let softwareupdateList = self.List()
        
        if softwareupdateList.contains("restart") {
            softwareupdateDownloadLog.info("Starting softwareupdate download, privacy: .public)")
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
                softwareupdateDownloadLog.error("Error downloading software updates, privacy: .public)")
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
