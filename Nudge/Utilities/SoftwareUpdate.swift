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
        
        let outputPipe = Pipe(), errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
        } catch {
            softwareupdateListLog.error("\("Error listing software updates", privacy: .public)")
        }
        
        task.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile(), errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(decoding: outputData, as: UTF8.self), error = String(decoding: errorData, as: UTF8.self)
        
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
            softwareupdateListLog.debug("\("Apple Silicon devices do not support automated softwareupdate downloads for minor updates. Please use MDM for this functionality.", privacy: .public)")
            return
        }
        
        if Utils().requireMajorUpgrade() {
            if actionButtonPath != nil {
                return
            }
            
            if attemptToFetchMajorUpgrade == true {
                if majorUpgradeAppPathExists {
                    softwareupdateListLog.notice("\("Found major upgrade application - skipping download", privacy: .public)")
                    return
                }
                
                if majorUpgradeBackupAppPathExists {
                    softwareupdateListLog.notice("\("Found backup major upgrade application - skipping download", privacy: .public)")
                    return
                }
                
                softwareupdateListLog.notice("\("Device requires major upgrade - attempting download", privacy: .public)")
                let task = Process()
                task.launchPath = "/usr/sbin/softwareupdate"
                task.arguments = ["--fetch-full-installer", "--full-installer-version", requiredMinimumOSVersion]
                
                let outputPipe = Pipe(), errorPipe = Pipe()
                
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                do {
                    try task.run()
                } catch {
                    softwareupdateListLog.error("\("Error downloading software update", privacy: .public)")
                }
                
                task.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile(), errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(decoding: outputData, as: UTF8.self), _ = String(decoding: errorData, as: UTF8.self)
                
                if task.terminationStatus != 0 {
                    softwareupdateDownloadLog.error("Error downloading software update: \(output, privacy: .public)")
                } else {
                    softwareupdateListLog.notice("\("softwareupdate successfully downloaded available update application - updating application paths", privacy: .public)")
                    softwareupdateDownloadLog.info("\(output, privacy: .public)")
                    fetchMajorUpgradeSuccessful = true
                    majorUpgradeAppPathExists = FileManager.default.fileExists(atPath: majorUpgradeAppPath)
                    majorUpgradeBackupAppPathExists = FileManager.default.fileExists(atPath: Utils().getBackupMajorUpgradeAppPath())
                }
            } else {
                softwareupdateListLog.notice("\("Device requires major upgrade but attemptToFetchMajorUpgrade is False - skipping download", privacy: .public)")
            }
        } else {
            if disableSoftwareUpdateWorkflow {
                softwareupdateListLog.notice("\("Skip running softwareupdate because it's disabled by a preference.", privacy: .public)")
                return
            }
            let softwareupdateList = self.List()
            var updateLabel = ""
            for update in softwareupdateList.components(separatedBy: "\n") {
                if update.contains("Label:") {
                    updateLabel = update.components(separatedBy: ": ")[1]
                }
            }
            
            if softwareupdateList.contains(requiredMinimumOSVersion) && updateLabel.isEmpty == false {
                softwareupdateListLog.notice("softwareupdate found \(updateLabel, privacy: .public) available for download - attempting download")
                let task = Process()
                task.launchPath = "/usr/sbin/softwareupdate"
                task.arguments = ["--download", "\(updateLabel)"]
                
                let outputPipe = Pipe(), errorPipe = Pipe()
                
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                do {
                    try task.run()
                } catch {
                    softwareupdateListLog.error("\("Error downloading software update", privacy: .public)")
                }
                
                task.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile(), errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(decoding: outputData, as: UTF8.self), error = String(decoding: errorData, as: UTF8.self)
                
                if task.terminationStatus != 0 {
                    softwareupdateDownloadLog.error("Error downloading software updates: \(error, privacy: .public)")
                } else {
                    softwareupdateListLog.notice("\("softwareupdate successfully downloaded available update", privacy: .public)")
                    softwareupdateDownloadLog.info("\(output, privacy: .public)")
                }
            } else {
                softwareupdateListLog.notice("softwareupdate did not find \(requiredMinimumOSVersion, privacy: .public) available for download - skipping download attempt")
            }
        }
    }
}
