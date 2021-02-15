//
//  SoftwareUpdate.swift
//  Nudge
//
//  Created by Rory Murdock on 10/2/21.
//

import Foundation

class SoftwareUpdate {
    func List() {
        if Utils().getCPUTypeString() == "Apple Silicon" {
            softwareupdateLog.info("Apple Silicon devices do not support automated softwareupdate calls. Please use MDM., privacy: .public)")
            return
        }

        softwareupdateLog.info("Finding software updates., privacy: .public)")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
        task.arguments = ["-la"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            print("Error launching VBoxManage")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        
        softwareupdateLog.info("\(output, privacy: .public)")
        softwareupdateLog.error("\(error, privacy: .public)")
    }
    
    func Download() {

        // TODO Only run if
        // If enforceMinorUpdates == true

        if Utils().getCPUTypeString() == "Apple Silicon" {
            softwareupdateLog.info("Apple Silicon devices do not support automated softwareupdate calls. Please use MDM., privacy: .public)")
            return
        }

        softwareupdateLog.info("Starting softwareupdate download, privacy: .public)")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
        task.arguments = ["-da"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            print("Error downloading software updates")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)

        softwareupdateLog.info("\(output, privacy: .public)")
        softwareupdateLog.error("\(error, privacy: .public)")
    }
}
