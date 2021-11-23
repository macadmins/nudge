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
        softwareupdateDownloadLog.notice("enforceMinorUpdates: \(enforceMinorUpdates, privacy: .public)")

        if Utils().getCPUTypeString() == "Apple Silicon" && Utils().requireMajorUpgrade() == false {
            let msg = "Apple Silicon devices do not support automated softwareupdate downloads for minor updates. Please use MDM."
            softwareupdateListLog.debug("\(msg, privacy: .public)")
            return
        }
        
        if Utils().requireMajorUpgrade() {
            if actionButtonPath != nil {
                return
            }

            if attemptToFetchMajorUpgrade == true {
                if majorUpgradeAppPathExists {
                    let msg = "found major upgrade application - skipping download"
                    softwareupdateListLog.notice("\(msg, privacy: .public)")
                    return
                }

                if majorUpgradeBackupAppPathExists {
                    let msg = "found backup major upgrade application - skipping download"
                    softwareupdateListLog.notice("\(msg, privacy: .public)")
                    return
                }
                
                let msg = "device requires major upgrade - attempting download"
                softwareupdateListLog.notice("\(msg, privacy: .public)")
                let task = Process()
                task.launchPath = "/usr/sbin/softwareupdate"
                task.arguments = ["--fetch-full-installer", "--full-installer-version", requiredMinimumOSVersionNormalized]
                
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
                
                task.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(decoding: outputData, as: UTF8.self)
                let _ = String(decoding: errorData, as: UTF8.self)
                
                if task.terminationStatus != 0 {
                    softwareupdateDownloadLog.error("Error downloading software updates: \(output, privacy: .public)")
                } else {
                    fetchMajorUpgradeSuccessful = true
                    let msg = "softwareupdate successfully downloaded available update application"
                    softwareupdateListLog.notice("\(msg, privacy: .public)")
                    softwareupdateDownloadLog.info("\(output, privacy: .public)")
                }
            } else {
                    let msg = "device requires major upgrade but attemptToFetchMajorUpgrade is False - skipping download"
                    softwareupdateListLog.notice("\(msg, privacy: .public)")
            }
        } else {
            let softwareupdateList = self.List()
            
            if softwareupdateList.contains("restart") {
                let msg = "softwareupdate found available updates requiring a restart - attempting download"
                softwareupdateListLog.notice("\(msg, privacy: .public)")
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
                
                task.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(decoding: outputData, as: UTF8.self)
                let error = String(decoding: errorData, as: UTF8.self)
                
                if task.terminationStatus != 0 {
                    softwareupdateDownloadLog.error("Error downloading software updates: \(error, privacy: .public)")
                } else {
                    let msg = "softwareupdate successfully downloaded available updates"
                    softwareupdateListLog.notice("\(msg, privacy: .public)")
                    softwareupdateDownloadLog.info("\(output, privacy: .public)")
                }
            } else {
                let msg = "softwareupdate did not find any available updates requiring a restart - skipping download"
                softwareupdateListLog.notice("\(msg, privacy: .public)")
            }
        }
    }
}
