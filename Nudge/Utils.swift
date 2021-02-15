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
        Log.info(message: "Re-activating Nudge")
        NSApp.activate(ignoringOtherApps: true)
    }

    func bringNudgeToFront() {
        Log.info(message: "Bringing nudge to front")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }
    
    func createImageData(fileImagePath: String) -> NSImage {
        Log.info(message: "Creating image path for fileImagePath")
        let urlPath = NSURL(fileURLWithPath: fileImagePath)
        let imageData:NSData = NSData(contentsOf: urlPath as URL)!
        return NSImage(data: imageData as Data)!
    }
    
    func demoModeEnabled() -> Bool {
        let demoModeEnable = CommandLine.arguments.contains("-demo-mode")
        Log.info(message: "ARG: Demo mode enabled command line argument: \(demoModeEnable)")
        return demoModeEnable
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let forceScreenShotIconMode = CommandLine.arguments.contains("-force-screenshot-icon")
        Log.info(message: "ARG: Force screenshot icon mode: \(forceScreenShotIconMode)")
        return forceScreenShotIconMode
    }
    
    func fullyUpdated() -> Bool {
        let fullyUpdated = versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
        Log.info(message: "Device is fulled updated: \(fullyUpdated)")
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
            Log.info(message: "CPU Type is Intel")
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            Log.info(message: "CPU Type is Apple Silicon")
            return "Apple Silicon"
        }
        Log.warning(message: "Unknown CPU Type")
        return "unknown"
    }
    
    func getCurrentDate() -> Date {
        Date()
    }
    
    func getJSONUrl() -> String {
        // let jsonURL = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        let jsonURL = UserDefaults.standard.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        Log.info(message: "JSON url: \(jsonURL)")
        return jsonURL
    }
    
    func getInitialDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.date(from: "08-06-2020") ?? Date() // <3
    }
    
    func getMajorOSVersion() -> Int {
        let MajorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        Log.info(message: "OS Version: \(MajorOSVersion)")
        return MajorOSVersion
    }
    
    func getMajorRequiredNudgeOSVersion() -> Int {
        let parts = requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        Log.info(message: "Major required OS version: \(Int((parts[0]))!)")
        return Int((parts[0]))!
    }
    
    func getMinorOSVersion() -> Int {
        let MinorOSVersion = ProcessInfo().operatingSystemVersion.minorVersion
        Log.info(message: "Minor OS Version: \(MinorOSVersion)")
        return MinorOSVersion
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
        Log.info(message: "Patch OS Version: \(PatchOSVersion)")
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

            Log.info(message: "Serial is \(serialNumber)")
            return serialNumber
        }
        
        return serialNumber ?? ""
    }
    
    func getSystemConsoleUsername() -> String {
        // https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
        var uid: uid_t = 0
        var gid: gid_t = 0
        let SystemConsoleUsername = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
        Log.info(message: "System console username: \(SystemConsoleUsername)")
        return SystemConsoleUsername
    }
    
    func getTimerController() -> Int {
        let timerCycle = getTimerControllerInt()
        // print("Timer Cycle:", String(timerCycle)) // Easy way to debug the timerController logic
        Log.info(message: "Timer cycle: \(timerCycle)")
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
        Log.info(message: "User clicked moreInfo button.")
        NSWorkspace.shared.open(url)
    }
    
    func pastRequiredInstallationDate() -> Bool {
        let pastRequiredInstallationDate = getCurrentDate() > requiredInstallationDate
        Log.info(message: "Installation date has passed: \(pastRequiredInstallationDate)")
        return pastRequiredInstallationDate
    }
    
    func requireDualQuitButtons() -> Bool {
        let requireDualQuitButtons = (approachingWindowTime / 24) >= getNumberOfDaysBetween()
        Log.info(message: "Require dual quit buttons: \(requireDualQuitButtons)")
        return requireDualQuitButtons
    }

    func requireMajorUpgrade() -> Bool {
        if requiredMinimumOSVersion == "0.0" {
            Log.info(message: "Required major update: false")
            return false
        }
        let requireMajorUpdate = versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
        Log.info(message: "Require major update: \(requireMajorUpdate)")
        return requireMajorUpdate
    }
    
    func simpleModeEnabled() -> Bool {
        let simpleModeEnabled = CommandLine.arguments.contains("-simple-mode")
        Log.info(message: "Simple mode enabled: \(simpleModeEnabled)")
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
