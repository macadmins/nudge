//
//  Logger.swift
//  Nudge
//
//  Created by Rory Murdock on 10/2/21.
//

import Foundation
import os

let bundleID = Bundle.main.bundleIdentifier

func getLibraryDirectory() -> URL {
    let paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
    let LibraryDirectory = paths[0]
    return LibraryDirectory
}

class NudgeLogger {

    // Get the default filemanager
    let fileManager = FileManager.default

    let logdirectory = getLibraryDirectory().appendingPathComponent("Logs/Nudge/")
    let logfile = getLibraryDirectory().appendingPathComponent("Logs/Nudge/Nudge.log")

    // Create date formatter
    let formatter = DateFormatter()

    var logToSystem = false

    init() {

        os_log("Starting", type: .info)

        var isDir : ObjCBool = false

        // Note, have to remove file:// from url for filemanager
        if fileManager.fileExists(atPath: logdirectory.absoluteString.replacingOccurrences(of: "file://", with: ""), isDirectory:&isDir) {
            os_log("Log dir %s exists", type: .info, logdirectory.absoluteString)
        } else {
            // Directory doesn't exist, create it
            os_log("Log dir %s does not exist, creating it", type: .error, logdirectory.absoluteString)

            do
            {
                // Create Nudge directory
                try fileManager.createDirectory(atPath: logdirectory.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                // Can't create the directory, log to built-in logger instead
                os_log("Unable to create directory %s", type: .error, error.debugDescription)
                logToSystem = true
            }

        }
        
        if fileManager.fileExists(atPath: logfile.absoluteString.replacingOccurrences(of: "file://", with: "")){
            os_log("Log file %s exists", type: .error, logfile.absoluteString.replacingOccurrences(of: "file://", with: ""))
        } else {
            os_log("Creating file %s", type: .info, logfile.absoluteString.replacingOccurrences(of: "file://", with: ""))
            fileManager.createFile(atPath: logfile.absoluteString.replacingOccurrences(of: "file://", with: ""), contents: nil)
        }

        // Configure date style
        formatter.timeStyle = .medium
        formatter.dateStyle = .long

        // Logging should be started now
        writeToLog(message:"Nudge launched", logLevel:"Info")
    }

    func writeToLog(message:String, logLevel:String) {

        if !logToSystem {
            do {
                // https://medium.com/@vhart/read-write-and-delete-file-handling-from-xcode-playground-abf57e445b4
                // Add Time, Log Level, and add a new line at the end
                // let message = String(format: "%s\t%s\t%s\n", self.formatter.string(from: Date()), logLevel, message)
                let message = self.formatter.string(from: Date()) + "\t" + logLevel + "\t\t" + message + "\n"

                let fileUpdater = try FileHandle(forUpdating: logfile)
                fileUpdater.seekToEndOfFile()
                fileUpdater.write(message.data(using: .utf8)!)
                fileUpdater.closeFile() // Is closing the file all the time efficent

            } catch {
                // Can't write to the file
                os_log("Unable to write to %s log: %s", type: .error, logfile.absoluteString, error.localizedDescription)

                // Start logging to the built-in logger instead
                logToSystem = true
            }

        } else {
            // Can't log to file, use built-in logger
            if logLevel == "Error" {
                os_log("%s", type: .error, message)
            } else if logLevel == "Debug" {
                os_log("%s", type: .debug, message)
            } else if logLevel == "Warning" {
                os_log("%s", type: .error, message) // TODO Find a way to log as warning
            } else {
                // Write anything else to info
                os_log("%s", type: .info, message)
            }
        }
    }

    func error(message:String) {
        writeToLog(message:message, logLevel:"Error")
    }

    func warning(message:String) {
        writeToLog(message:message, logLevel:"Warning")
    }


    func info(message:String) {
        writeToLog(message:message, logLevel:"Info")
    }

    func debug(message:String) {
        writeToLog(message:message, logLevel:"Debug")
    }
}

// Lets it be used throughout Nudge via Log.info etc.
let Log = NudgeLogger()
