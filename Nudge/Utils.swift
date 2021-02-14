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
        print("Re-activating Nudge")
        NSApp.activate(ignoringOtherApps: true)
    }

    func bringNudgeToFront() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }
    
    func createImageData(fileImagePath: String) -> NSImage {
        let urlPath = NSURL(fileURLWithPath: fileImagePath)
        let imageData:NSData = NSData(contentsOf: urlPath as URL)!
        return NSImage(data: imageData as Data)!
    }
    
    func demoModeEnabled() -> Bool {
        return CommandLine.arguments.contains("-demo-mode")
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        return CommandLine.arguments.contains("-force-screenshot-icon")
    }
    
    func fullyUpdated() -> Bool {
        return versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
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
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            return "Apple Silicon"
        }
        return "unknown"
    }
    
    func getCurrentDate() -> Date {
        Date()
    }
    
    func getJSONUrl() -> String {
        // let jsonURL = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        let jsonURL = UserDefaults.standard.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        return jsonURL
    }
    
    func getInitialDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.date(from: "08-06-2020") ?? Date() // <3
    }
    
    func getMajorOSVersion() -> Int {
        return ProcessInfo().operatingSystemVersion.majorVersion
    }
    
    func getMajorRequiredNudgeOSVersion() -> Int {
        let parts = requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        return Int((parts[0]))!
    }
    
    func getMinorOSVersion() -> Int {
        return ProcessInfo().operatingSystemVersion.minorVersion
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
        return ProcessInfo().operatingSystemVersion.patchVersion
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

            return serialNumber
        }
        
        return serialNumber ?? ""
    }
    
    func getSystemConsoleUsername() -> String {
        // https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
        var uid: uid_t = 0
        var gid: gid_t = 0
        return SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
    }
    
    func getTimerController() -> Int {
        let timerCycle = getTimerControllerInt()
        // print("Timer Cycle:", String(timerCycle)) // Easy way to debug the timerController logic
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
        print("User clicked moreInfo button.")
        NSWorkspace.shared.open(url)
    }
    
    func pastRequiredInstallationDate() -> Bool {
        return getCurrentDate() > requiredInstallationDate
    }
    
    func requireDualQuitButtons() -> Bool {
        return (approachingWindowTime / 24) >= getNumberOfDaysBetween()
    }

    func requireMajorUpgrade() -> Bool {
        if requiredMinimumOSVersion == "0.0" {
            return false
        }
        return versionGreaterThanOrEqual(current_version: OSVersion(ProcessInfo().operatingSystemVersion).description, new_version: requiredMinimumOSVersion)
    }
    
    func simpleModeEnabled() -> Bool {
        return CommandLine.arguments.contains("-simple-mode")
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
