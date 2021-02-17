//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import Foundation
import SystemConfiguration

struct Utils {
    func activateNudge() {
        let msg = "Re-activating Nudge"
        utilsLog.info("\(msg, privacy: .public)")
        NSApp.activate(ignoringOtherApps: true)
    }

    func bringNudgeToFront() {
        let msg = "Bringing Nudge to front"
        utilsLog.info("\(msg, privacy: .public)")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }

    func createImageData(fileImagePath: String) -> NSImage {
        utilsLog.info("Creating image path for \(fileImagePath, privacy: .public)")
        let urlPath = NSURL(fileURLWithPath: fileImagePath)
        let imageData:NSData = NSData(contentsOf: urlPath as URL)!
        return NSImage(data: imageData as Data)!
    }

    func demoModeEnabled() -> Bool {
        let demoModeArgumentPassed = CommandLine.arguments.contains("-demo-mode")
        if demoModeArgumentPassed {
            let msg = "-demo-mode argument passed"
            uiLog.info("\(msg, privacy: .public)")
        }
        return demoModeArgumentPassed
    }

    func exitNudge() {
        let msg = "User clicked primaryQuitButton"
        uiLog.info("\(msg, privacy: .public)")
        AppKit.NSApp.terminate(nil)
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let forceScreenShotIconMode = CommandLine.arguments.contains("-force-screenshot-icon")
        if forceScreenShotIconMode {
            let msg = "-force-screenshot-icon argument passed"
            uiLog.info("\(msg, privacy: .public)")
        }
        return forceScreenShotIconMode
    }

    func fullyUpdated() -> Bool {
        let fullyUpdated = versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
        utilsLog.info("Device is fully updated: \(fullyUpdated, privacy: .public)")
        return fullyUpdated
    }

    func getCPUTypeInt() -> Int {
        // https://stackoverflow.com/a/63539782
        var cputype = UInt32(0)
        var size = cputype.byteWidth
        let result = sysctlbyname("hw.cputype", &cputype, &size, nil, 0)
        if result == -1 {
            if (errno == ENOENT){
                return 0
            }
            return -1
        }
        return Int(cputype)
    }

    func getCPUTypeString() -> String {
        // https://stackoverflow.com/a/63539782
        let type: Int = getCPUTypeInt()
        if type == -1 {
            return "error in CPU type"
        }

        let cpu_arch = type & 0xff // mask for architecture bits
        if cpu_arch == cpu_type_t(7){
            let msg = "CPU Type is Intel"
            utilsLog.info("\(msg, privacy: .public)")
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            let msg = "CPU Type is Apple Silicon"
            utilsLog.info("\(msg, privacy: .public)")
            return "Apple Silicon"
        }
        let msg = "Unknown CPU Type"
        utilsLog.info("\(msg, privacy: .public)")
        return "unknown"
    }

    func getCurrentDate() -> Date {
        Date()
    }

    func getJSONUrl() -> String {
        let jsonURL = nudgeDefaults.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        utilsLog.info("JSON url: \(jsonURL, privacy: .public)")
        return jsonURL
    }

    func getInitialDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.date(from: "08-06-2020") ?? Date() // <3
    }

    func getMajorOSVersion() -> Int {
        let MajorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        utilsLog.info("OS Version: \(MajorOSVersion, privacy: .public)")
        return MajorOSVersion
    }

    func getMajorRequiredNudgeOSVersion() -> Int {
        let parts = requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        let majorRequiredNudgeOSVersion = Int((parts[0]))!
        utilsLog.info("Major required OS version: \(majorRequiredNudgeOSVersion, privacy: .public)")
        return majorRequiredNudgeOSVersion
    }

    func getMinorOSVersion() -> Int {
        let MinorOSVersion = ProcessInfo().operatingSystemVersion.minorVersion
        utilsLog.info("Minor OS Version: \(MinorOSVersion, privacy: .public)")
        return MinorOSVersion
    }
    
    func getNudgeVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
    
    func versionArgumentPassed() -> Bool {
        let versionArgumentPassed = CommandLine.arguments.contains("-version")
        if versionArgumentPassed {
            let msg = "-version argument passed"
            uiLog.info("\(msg, privacy: .public)")
        }
        return versionArgumentPassed
    }

    func getNumberOfDaysBetween() -> Int {
       let currentCal = Calendar.current
       let fromDate = currentCal.startOfDay(for: getCurrentDate())
       let toDate = currentCal.startOfDay(for: requiredInstallationDate)
       let numberOfDays = currentCal.dateComponents([.day], from: fromDate, to: toDate)
       return numberOfDays.day!
    }

    func getNumberOfHoursBetween() -> Int {
        return Int(requiredInstallationDate.timeIntervalSince(getCurrentDate()) / 3600 )
    }

    func getPatchOSVersion() -> Int {
        let PatchOSVersion = ProcessInfo().operatingSystemVersion.patchVersion
        utilsLog.info("Patch OS Version: \(PatchOSVersion, privacy: .public)")
        return PatchOSVersion
    }

    func getSerialNumber() -> String {
        if Utils().demoModeEnabled() {
                return "C00000000000"
        }
        // https://ourcodeworld.com/articles/read/1113/how-to-retrieve-the-serial-number-of-a-mac-with-swift
        var serialNumber: String? {
            let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )

            guard platformExpert > 0 else {
                return nil
            }

            guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }

            IOObjectRelease(platformExpert)

            utilsLog.info("Serial Number: \(serialNumber, privacy: .public)")
            return serialNumber
        }

        return serialNumber ?? ""
    }

    func getSystemConsoleUsername() -> String {
        // https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
        var uid: uid_t = 0
        var gid: gid_t = 0
        let SystemConsoleUsername = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
        utilsLog.info("System console username: \(SystemConsoleUsername, privacy: .public)")
        return SystemConsoleUsername
    }

    func getTimerController() -> Int {
        let timerCycle = getTimerControllerInt()
        // print("Timer Cycle:", String(timerCycle)) // Easy way to debug the timerController logic
        utilsLog.info("Timer cycle: \(timerCycle, privacy: .public)")
        return timerCycle
    }

    func getTimerControllerInt() -> Int {
        if 0 >= getNumberOfHoursBetween() {
            return elapsedRefreshCycle
        } else if imminentWindowTime >= getNumberOfHoursBetween() {
            return imminentRefreshCycle
        } else if approachingWindowTime >= getNumberOfHoursBetween() {
            return approachingRefreshCycle
        } else {
            return initialRefreshCycle
        }
    }

    func openMoreInfo() {
        guard let url = URL(string: aboutUpdateURL) else {
            return
        }
        let msg = "User clicked moreInfo button"
        uiLog.info("\(msg, privacy: .public)")
        NSWorkspace.shared.open(url)
    }

    func pastRequiredInstallationDate() -> Bool {
        let pastRequiredInstallationDate = getCurrentDate() > requiredInstallationDate
        utilsLog.info("Device pastRequiredInstallationDate: \(pastRequiredInstallationDate, privacy: .public)")
        return pastRequiredInstallationDate
    }

    func requireDualQuitButtons() -> Bool {
        let requireDualQuitButtons = (approachingWindowTime / 24) >= getNumberOfDaysBetween()
        uiLog.info("Device requireDualQuitButtons: \(requireDualQuitButtons, privacy: .public)")
        return requireDualQuitButtons
    }

    func requireMajorUpgrade() -> Bool {
        if requiredMinimumOSVersion == "0.0" {
            let msg = "Device requireMajorUpgrade: false"
            utilsLog.info("\(msg, privacy: .public)")
            return false
        }
        let requireMajorUpdate = versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
        utilsLog.info("Device requireMajorUpgrade: \(requireMajorUpdate, privacy: .public)")
        return requireMajorUpdate
    }

    func simpleModeEnabled() -> Bool {
        let simpleModeEnabled = CommandLine.arguments.contains("-simple-mode")
        if simpleModeEnabled {
            let msg = "-simple-mode argument passed"
            uiLog.info("\(msg, privacy: .public)")
        }
        return simpleModeEnabled
    }

    func updateDevice() {
        if requireMajorUpgrade() {
            NSWorkspace.shared.open(URL(fileURLWithPath: majorUpgradeAppPath))
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"))
            // NSWorkspace.shared.open(URL(fileURLWithPath: "x-apple.systempreferences:com.apple.preferences.softwareupdate?client=softwareupdateapp"))
        }
    }

    func versionEqual(current_version: String, new_version: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return current_version.compare(new_version, options: .numeric) == .orderedSame
    }

    func versionGreaterThan(current_version: String, new_version: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return current_version.compare(new_version, options: .numeric) == .orderedDescending
    }

    func versionGreaterThanOrEqual(current_version: String, new_version: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return current_version.compare(new_version, options: .numeric) != .orderedAscending
    }

    func versionLessThan(current_version: String, new_version: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return current_version.compare(new_version, options: .numeric) == .orderedAscending
    }

    func versionLessThanOrEqual(current_version: String, new_version: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return current_version.compare(new_version, options: .numeric) != .orderedDescending
    }
}

extension FixedWidthInteger {
    // https://stackoverflow.com/a/63539782
    var byteWidth:Int {
        return self.bitWidth/UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth/UInt8.bitWidth
    }
}
