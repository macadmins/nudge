//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import CoreMediaIO
import Foundation
import SystemConfiguration
import SwiftUI

extension Color {
    static let accessibleBlue = Color(red: 26 / 255, green: 133 / 255, blue: 255 / 255)
    static let accessibleRed = Color(red: 230 / 255, green: 97 / 255, blue: 0 / 255)
    static let accessibleSecondaryLight = Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255)
    static let accessibleSecondaryDark = Color(red: 150 / 255, green: 150 / 255, blue: 150 / 255)
}

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
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

// https://stackoverflow.com/questions/29985614/how-can-i-change-locale-programmatically-with-swift
// Apple recommends against this, but this is super frustrating since Nudge does dynamic UIs
extension String {
    func localized(desiredLanguage :String) ->String {
        // Try to get the language passed and if it does not exist, use en
        let path = bundle.path(forResource: desiredLanguage, ofType: "lproj") ?? bundle.path(forResource: "en", ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}

var demoModeArgumentPassed = false
var unitTestingArgumentPassed = false

// https://stackoverflow.com/questions/37470201/how-can-i-tell-if-the-camera-is-in-use-by-another-process
// led me to https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm
// Complete credit to https://github.com/ttimpe/camera-usage-detector-mac/blob/845df180f9d19463e8fd382277e2f61d88ca7d5d/CameraUsage/CameraUsageController.swift
// kCMIODevicePropertyDeviceIsRunningSomewhere is the key here
struct Camera {
    var id: CMIOObjectID
    var name: String? {
        get {
            var address:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress(
                mSelector:CMIOObjectPropertySelector(kCMIOObjectPropertyName),
                mScope:CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement:CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))

            var name:CFString? = nil
            let propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            var dataUsed: UInt32 = 0

            let result:OSStatus = CMIOObjectGetPropertyData(self.id, &address, 0, nil, propsize, &dataUsed, &name)
            if (result != 0) {
                return ""
            }

            return name as String?
        }
    }
    var isOn: Bool {
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )

        
        var isUsed = false
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(self.id, &opa, 0, nil, &dataSize)
        if result == OSStatus(kCMIOHardwareNoError) {
            if let data = malloc(Int(dataSize)) {
                result = CMIOObjectGetPropertyData(self.id, &opa, 0, nil, dataSize, &dataUsed, data)
                let on = data.assumingMemoryBound(to: UInt8.self)
                isUsed = on.pointee != 0
            }
        }

        return isUsed
    }
}

var cameras: [Camera]  {
    get {
        var innerArray :[Camera] = []
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
        )

        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize)
        var devices: UnsafeMutableRawPointer?

        repeat {
            if devices != nil {
                free(devices)
                devices = nil
            }

            devices = malloc(Int(dataSize))
            result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, devices)
        } while result == OSStatus(kCMIOHardwareBadPropertySizeError)


        if let devices = devices {
            for offset in stride(from: 0, to: dataSize, by: MemoryLayout<CMIOObjectID>.size) {
                let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: CMIOObjectID.self)
                innerArray.append(Camera(id: current.pointee))
            }
        }

        free(devices)


        return innerArray
    }
    
}

struct Utils {
    func activateNudge() {
        utilsLog.info("\("Activating Nudge", privacy: .public)")
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.

        // load the blur background and send it to the back if we are past the required install date
        if pastRequiredInstallationDate() && aggressiveUserFullScreenExperience {
            Utils().centerNudge()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows[0].makeKeyAndOrderFront(self)
            uiLog.info("\("Enabling blurred background", privacy: .public)")
            nudgePrimaryState.blurredBackground.removeAll()
            for (index, screen) in screens.enumerated() {
                nudgePrimaryState.blurredBackground.append(BlurWindowController())
                loopedScreen = screen
                nudgePrimaryState.blurredBackground[index].close()
                nudgePrimaryState.blurredBackground[index].loadWindow()
                nudgePrimaryState.blurredBackground[index].showWindow(self)
            }
            NSApp.windows[0].level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
            return
        }

        if NSWorkspace.shared.isActiveSpaceFullScreen() && !nudgePrimaryState.afterFirstStateChange {
            uiLog.notice("\("Bypassing activation due to full screen bugs in macOS", privacy: .public)")
            return
        } else {
            if !hideNudge {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows[0].makeKeyAndOrderFront(self)
            } else {
                NSApp.hide(nil)
            }
            hideNudge = false
            return
        }
    }

    func allow1HourDeferral() -> Bool {
        if demoModeEnabled() {
            return true
        }
        let allow1HourDeferralButton = getNumberOfHoursRemaining() > 0
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allow1HourDeferralButton: \(allow1HourDeferralButton, privacy: .public)")
        }
        return allow1HourDeferralButton
    }

    func allow24HourDeferral() -> Bool {
        if demoModeEnabled() {
            return true
        }
        let allow24HourDeferralButton = getNumberOfHoursRemaining() > imminentWindowTime
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allow24HourDeferralButton: \(allow24HourDeferralButton, privacy: .public)")
        }
        return allow24HourDeferralButton
    }

    func allowCustomDeferral() -> Bool {
        if demoModeEnabled() {
            return true
        }
        let allowCustomDeferralButton = getNumberOfHoursRemaining() > approachingWindowTime
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allowCustomDeferralButton: \(allowCustomDeferralButton, privacy: .public)")
        }
        return allowCustomDeferralButton
    }

    func bundleModeEnabled() -> Bool {
        let bundleModeArgumentPassed = CommandLine.arguments.contains("-bundle-mode")
        if !nudgeLogState.hasLoggedBundleMode {
            if bundleModeArgumentPassed {
                nudgeLogState.hasLoggedBundleMode = true
                uiLog.debug("\("-bundle-mode argument passed", privacy: .public)")
            }
        }
        return bundleModeArgumentPassed
    }

    func centerNudge() {
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.
        NSApp.windows[0].center()
    }

    func coerceStringToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter.date(from: dateString) ?? Utils().getCurrentDate()
    }

    func createImageData(fileImagePath: String) -> NSImage {
        utilsLog.debug("Creating image path for \(fileImagePath, privacy: .public)")
        let urlPath = NSURL(fileURLWithPath: fileImagePath)
        var imageData = NSData()
        do {
            imageData = try NSData(contentsOf: urlPath as URL)
        } catch {
            uiLog.error("Error accessing file \(fileImagePath). Incorrect permissions")
            let errorImageConfig = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)
            return NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil)!.withSymbolConfiguration(errorImageConfig)!
        }
        return NSImage(data: imageData as Data)!
    }

    func debugUIModeEnabled() -> Bool {
        let debugUIModeArgumentPassed = CommandLine.arguments.contains("-debug-ui-mode")
        if !nudgeLogState.afterFirstRun {
            if debugUIModeArgumentPassed {
                uiLog.debug("\("-debug-ui-mode argument passed", privacy: .public)")
            }
        }
        return debugUIModeArgumentPassed
    }

    func demoModeEnabled() -> Bool {
        demoModeArgumentPassed = CommandLine.arguments.contains("-demo-mode")
        if !nudgeLogState.hasLoggedDemoMode {
            if demoModeArgumentPassed {
                nudgeLogState.hasLoggedDemoMode = true
                uiLog.debug("\("-demo-mode argument passed", privacy: .public)")
            }
        }
        return demoModeArgumentPassed
    }

    func unitTestingEnabled() -> Bool {
        unitTestingArgumentPassed = CommandLine.arguments.contains("-unit-testing")
        if !nudgeLogState.hasLoggedUnitTestingMode {
            if demoModeArgumentPassed {
                nudgeLogState.hasLoggedUnitTestingMode = true
                uiLog.debug("\("-unit-testing argument passed", privacy: .public)")
            }
        }
        return unitTestingArgumentPassed
    }

    func exitNudge(shouldReallyHide: Bool = true) {
        if hideInsteadOfQuit && shouldReallyHide {
            uiLog.notice("\("Nudge is hiding due to condition met", privacy: .public)")
            NSApp.hide(nil)
            return
        } else {
            uiLog.notice("\("Nudge is terminating due to condition met", privacy: .public)")
            nudgePrimaryState.shouldExit = true
            exit(0)
        }
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let forceScreenShotIconMode = CommandLine.arguments.contains("-force-screenshot-icon")
        if !nudgeLogState.hasLoggedScreenshotIconMode {
            if forceScreenShotIconMode {
                nudgeLogState.hasLoggedScreenshotIconMode = true
                uiLog.debug("\("-force-screenshot-icon argument passed", privacy: .public)")
            }
        }
        return forceScreenShotIconMode
    }

    func fullyUpdated() -> Bool {
        let fullyUpdated = versionGreaterThanOrEqual(currentVersion: currentOSVersion, newVersion: requiredMinimumOSVersion)
        if fullyUpdated {
            utilsLog.notice("\("Current operating system (\(currentOSVersion)) is greater than or equal to required operating system (\(requiredMinimumOSVersion))", privacy: .public)")
            return true
        } else {
            return false
        }
    }

    func getBackupMajorUpgradeAppPath() -> String {
        if getMajorRequiredNudgeOSVersion() == 12 {
            return "/Applications/Install macOS Monterey.app"
        } else if getMajorRequiredNudgeOSVersion() == 13 {
            return "/Applications/Install macOS Ventura.app"
        } else { // TODO: Update this for next year with another else if
            return "/Applications/Install macOS Monterey.app"
        }
    }
    
    func getCompanyLogoPath(darkMode: Bool) -> String {
        if darkMode {
            return iconDarkPath
        } else {
            return iconLightPath
        }
    }

    func getConfigurationAsJSON() -> Data {
        let nudgeJSONConfig = try? newJSONEncoder().encode(nudgeJSONPreferences)
        if ((nudgeJSONConfig) != nil) {
            if let json = try? JSONSerialization.jsonObject(with: newJSONEncoder().encode(nudgeJSONPreferences), options: .mutableContainers),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                return jsonData
            }
        }
        return Data.init()
    }

    func getConfigurationAsProfile() -> Data {
        var nudgeProfileConfig = [String:Any]()
        nudgeProfileConfig["optionalFeatures"] = nudgeDefaults.dictionary(forKey: "optionalFeatures") as? [String:AnyObject]
        nudgeProfileConfig["osVersionRequirements"] = nudgeDefaults.array(forKey: "osVersionRequirements") as? [[String:AnyObject]]
        nudgeProfileConfig["userExperience"] = nudgeDefaults.dictionary(forKey: "userExperience") as? [String:AnyObject]
        nudgeProfileConfig["userInterface"] = nudgeDefaults.dictionary(forKey: "userInterface") as? [String:AnyObject]
        if !nudgeProfileConfig.isEmpty {
            do {
                let plistData = try PropertyListSerialization.data(fromPropertyList: nudgeProfileConfig, format: .xml, options: 0)
                let xmlPlistData = try XMLDocument.init(data: plistData, options: .nodePreserveAll)
                let prettyXMLData = xmlPlistData.xmlData(options: .nodePrettyPrint)
                return prettyXMLData
            } catch {
                print("issue with profile data!")
            }
        }
        return Data.init()
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
            utilsLog.debug("\("CPU Type is Intel", privacy: .public)")
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            utilsLog.debug("\("CPU Type is Apple Silicon", privacy: .public)")
            return "Apple Silicon"
        }
        utilsLog.debug("\("Unknown CPU Type", privacy: .public)")
        return "unknown"
    }

    func getCurrentDate() -> Date {
        // Date fixing stuff for non Gregorian calendars
        let dateFormatterCurrent = DateFormatter()
        let dateFormatterISO8601 = DateFormatter()
        let dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatterCurrent.dateFormat = dateFormat

        dateFormatterISO8601.dateFormat = dateFormat
        dateFormatterISO8601.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterISO8601.calendar = Calendar(identifier: .iso8601)
        dateFormatterISO8601.timeZone = TimeZone(identifier: "UTC")
        switch Calendar.current.identifier {
        case .buddhist, .japanese:
            return dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
        case .gregorian, .coptic, .ethiopicAmeteMihret, .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura, .persian :
            return dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
        case .chinese, .republicOfChina: // TODO: These are untested
            return dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
        case .ethiopicAmeteAlem: // TODO: Need to figure out
            return Date()
        @unknown default:
            return Date()
        }
    }

    func getHardwareUUID() -> String {
        if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
                return "DC3F0981-D881-408F-BED7-8D6F1DEE8176"
        }
        var hardwareUUID: String? {
            let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            guard platformExpert > 0 else {
                return nil
            }

            guard let hardwareUUID = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }

            IOObjectRelease(platformExpert)

            utilsLog.debug("Hardware UUID: \(hardwareUUID, privacy: .public)")
            return hardwareUUID
        }

        return hardwareUUID ?? ""
    }

    func getJSONUrl() -> String {
        let jsonURL = nudgeDefaults.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        utilsLog.debug("JSON url: \(jsonURL, privacy: .public)")
        return jsonURL
    }

    func getFormattedDate(date: Date? = nil) -> Date {
        var endDate = Date()
        // Date fixing stuff for non Gregorian calendars
        let dateFormatterCurrent = DateFormatter()
        let dateFormatterISO8601 = DateFormatter()
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatterCurrent.dateFormat = dateFormat

        dateFormatterISO8601.dateFormat = dateFormat
        dateFormatterISO8601.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterISO8601.calendar = Calendar(identifier: .iso8601)
        dateFormatterISO8601.timeZone = TimeZone(identifier: "UTC")
        var initialDate = dateFormatterISO8601.date(from: "2020-08-06T00:00:00Z") ?? Date() // <3
        if date != nil {
            initialDate = date!
        }
        
        switch Calendar.current.identifier {
        case .gregorian, .buddhist, .iso8601, .japanese:
            endDate = initialDate
        case .coptic, .ethiopicAmeteMihret, .hebrew, .indian, .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura, .persian :
            endDate =  dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: initialDate)) ?? Date()
        case .chinese, .republicOfChina: // TODO: These are untested
            endDate =  dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: initialDate)) ?? Date()
        case .ethiopicAmeteAlem: // TODO: Need to figure out
            break
        @unknown default:
            break
        }
        return endDate
    }

    func getMajorOSVersion() -> Int {
        let MajorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        if !nudgeLogState.hasLoggedMajorOSVersion {
            nudgeLogState.hasLoggedMajorOSVersion = true
            utilsLog.info("OS Version: \(MajorOSVersion, privacy: .public)")
        }
        return MajorOSVersion
    }

    func getMajorRequiredNudgeOSVersion() -> Int {
        let parts = requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        let majorRequiredNudgeOSVersion = Int((parts[0]))!
        if !nudgeLogState.hasLoggedMajorRequiredOSVersion {
            nudgeLogState.hasLoggedMajorRequiredOSVersion = true
            utilsLog.info("Major required OS version: \(majorRequiredNudgeOSVersion, privacy: .public)")
        }
        return majorRequiredNudgeOSVersion
    }

    func getMinorOSVersion() -> Int {
        let MinorOSVersion = ProcessInfo().operatingSystemVersion.minorVersion
        utilsLog.info("Minor OS Version: \(MinorOSVersion, privacy: .public)")
        return MinorOSVersion
    }

    func getNudgeJSONPreferences() -> NudgePreferences? {
        let url = Utils().getJSONUrl()
        if bundleModeEnabled() {
            if let url = bundle.url(forResource: "com.github.macadmins.Nudge.tester", withExtension: "json") {
                if let data = try? Data(contentsOf: url) {
                    do {
                        let decodedData = try NudgePreferences(data: data)
                        return decodedData
                    } catch {
                        prefsJSONLog.error("\(error.localizedDescription, privacy: .public)")
                        return nil
                    }
                }
            }
        }
        
        if url.contains("https://") || url.contains("http://") {
            if let json_url = URL(string: url) {
                if let data = try? Data(contentsOf: json_url) {
                    do {
                        let decodedData = try NudgePreferences(data: data)
                        return decodedData
                    } catch {
                        prefsJSONLog.error("\(error.localizedDescription, privacy: .public)")
                        return nil
                    }
                }
            }
        }
        
        guard let fileURL = URL(string: url) else {
            prefsJSONLog.error("\("Could not find on-disk json", privacy: .public)")
            return nil
        }
        
        if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
            return nil
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let content = try Data(contentsOf: fileURL)
                let decodedData = try NudgePreferences(data: content)
                return decodedData
                
            } catch let error {
                prefsJSONLog.error("\(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
        return nil
    }
    
    func getNudgeVersion() -> String {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    func getNumberOfDaysBetween() -> Int {
        if Utils().demoModeEnabled() {
            return 0
        }
       let currentCal = Calendar.current
       let fromDate = currentCal.startOfDay(for: getCurrentDate())
       let toDate = currentCal.startOfDay(for: requiredInstallationDate)
       let numberOfDays = currentCal.dateComponents([.day], from: fromDate, to: toDate)
       return numberOfDays.day!
    }

    func getNumberOfHoursRemaining(currentDate: Date = Utils().getCurrentDate()) -> Int {
        if Utils().demoModeEnabled() {
            return 24
        }
        if unitTestingEnabled() {
            return Int(PrefsWrapper.requiredInstallationDate.timeIntervalSince(currentDate) / 3600 )
        }
        return Int(requiredInstallationDate.timeIntervalSince(currentDate) / 3600 )
    }

    func getPatchOSVersion() -> Int {
        let PatchOSVersion = ProcessInfo().operatingSystemVersion.patchVersion
        utilsLog.info("Patch OS Version: \(PatchOSVersion, privacy: .public)")
        return PatchOSVersion
    }
    
    func getScreenShotPath(darkMode: Bool) -> String {
        if darkMode {
            return screenShotDarkPath
        } else {
            return screenShotLightPath
        }
    }

    func getSerialNumber() -> String {
        if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
                return "C00000000000"
        }
        // https://ourcodeworld.com/articles/read/1113/how-to-retrieve-the-serial-number-of-a-mac-with-swift
        var serialNumber: String? {
            let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            guard platformExpert > 0 else {
                return nil
            }

            guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }

            IOObjectRelease(platformExpert)

            utilsLog.debug("Serial Number: \(serialNumber, privacy: .public)")
            return serialNumber
        }

        return serialNumber ?? ""
    }
    
    func getSigningInfo() -> String? {
        // Adapted from https://github.com/ProfileCreator/ProfileCreator/blob/master/ProfileCreator/ProfileCreator/Extensions/ExtensionBundle.swift
        var osStatus = noErr
        var codeRef: SecStaticCode?

        osStatus = SecStaticCodeCreateWithPath(bundle.bundleURL as CFURL, [], &codeRef)
        guard osStatus == noErr, let code = codeRef else {
            print("Failed to create static code with path: \(bundle.bundleURL.path)")
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                print(osStatusError as String)
            }
            return nil
        }

        let flags: SecCSFlags = SecCSFlags(rawValue: kSecCSSigningInformation)
        var codeInfoRef: CFDictionary?

        osStatus = SecCodeCopySigningInformation(code, flags, &codeInfoRef)
        guard osStatus == noErr, let codeInfo = codeInfoRef as? [String: Any] else {
            // print("Failed to copy code signing information.")
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                print(osStatusError as String)
            }
            return nil
        }

        guard let teamIdentifier = codeInfo[kSecCodeInfoTeamIdentifier as String] as? String else {
            // print("Found no entry for \(kSecCodeInfoTeamIdentifier) in code signing info dictionary.")
            return nil
        }
        
        guard let certificates = codeInfo["certificates"] as? NSArray else {
            // print("Could not signing convert certificates into an array - Returning teamIdentifier")
            return teamIdentifier
        }
        
        guard let signingCertificateSummary = SecCertificateCopySubjectSummary(certificates[0] as! SecCertificate) as? String else {
            // print("Could not return initial certificate summary - Returning teamIdentifier")
            return teamIdentifier
        }

        return signingCertificateSummary
    }

    func getSystemConsoleUsername() -> String {
        // https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
        var uid: uid_t = 0
        var gid: gid_t = 0
        let SystemConsoleUsername = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
        utilsLog.debug("System console username: \(SystemConsoleUsername, privacy: .public)")
        return SystemConsoleUsername
    }

    func getTimerController() -> Int {
        let timerCycle = getTimerControllerInt()
        if timerCycle != nudgePrimaryState.timerCycle {
            uiLog.info("timerCycle: \(timerCycle, privacy: .public)")
            nudgePrimaryState.timerCycle = timerCycle
        }
        return timerCycle
    }

    func getTimerControllerInt() -> Int {
        if 0 >= getNumberOfHoursRemaining() {
            return elapsedRefreshCycle
        } else if imminentWindowTime >= getNumberOfHoursRemaining() {
            return imminentRefreshCycle
        } else if approachingWindowTime >= getNumberOfHoursRemaining() {
            return approachingRefreshCycle
        } else {
            return initialRefreshCycle
        }
    }

    func gracePeriodLogic(currentDate: Date = Utils().getCurrentDate(), testFileDate: Date? = nil) -> Date {
        if (allowGracePeriods || PrefsWrapper.allowGracePeriods) && !demoModeEnabled() {
            if FileManager.default.fileExists(atPath: gracePeriodPath) || unitTestingEnabled() {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: gracePeriodPath) as [FileAttributeKey: Any],
                   var gracePeriodPathCreationDate = attributes[FileAttributeKey.creationDate] as? Date {
                    if testFileDate != nil {
                        gracePeriodPathCreationDate = testFileDate!
                    }
                    let gracePeriodPathCreationTimeInHours = Int(currentDate.timeIntervalSince(gracePeriodPathCreationDate) / 3600)
                    let combinedGracePeriod = gracePeriodInstallDelay + gracePeriodLaunchDelay
                    uiLog.info("\("allowGracePeriods is set to true", privacy: .public)")
                    if (currentDate > PrefsWrapper.requiredInstallationDate) || combinedGracePeriod > getNumberOfHoursRemaining(currentDate: currentDate) {
                        // Exit Scenario
                        if gracePeriodLaunchDelay > gracePeriodPathCreationTimeInHours {
                            uiLog.info("\("Device within gracePeriodLaunchDelay, exiting Nudge", privacy: .public)")
                            nudgePrimaryState.shouldExit = true
                        }

                        // Launch Scenario
                        if gracePeriodInstallDelay > gracePeriodPathCreationTimeInHours {
                            requiredInstallationDate = gracePeriodPathCreationDate.addingTimeInterval(Double(combinedGracePeriod) * 3600)
                            uiLog.notice("Device permitted for gracePeriods - setting date to: \(requiredInstallationDate.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss'Z'"), privacy: .public)")
                            return requiredInstallationDate
                        }
                    }
                } else {
                    uiLog.error("\("allowGracePeriods is set to true, but gracePeriodPath creation date logic failed - bypassing allowGracePeriods logic", privacy: .public)")
                }
            } else {
               uiLog.error("\("allowGracePeriods is set to true, but gracePeriodPath was not found - bypassing allowGracePeriods logic", privacy: .public)")
           }
        }
        return PrefsWrapper.requiredInstallationDate
    }

    func logUserDeferrals(resetCount: Bool = false) {
        if Utils().demoModeEnabled() {
            nudgePrimaryState.userDeferrals = 0
            return
        }
        if resetCount {
            nudgePrimaryState.userDeferrals = 0
            nudgeDefaults.set(nudgePrimaryState.userDeferrals, forKey: "userDeferrals")
        } else {
            nudgeDefaults.set(nudgePrimaryState.userDeferrals, forKey: "userDeferrals")
        }
        
    }

    func logUserQuitDeferrals(resetCount: Bool = false) {
        if Utils().demoModeEnabled() {
            nudgePrimaryState.userQuitDeferrals = 0
            return
        }
        if resetCount {
            nudgePrimaryState.userQuitDeferrals = 0
            nudgeDefaults.set(nudgePrimaryState.userQuitDeferrals, forKey: "userQuitDeferrals")
        } else {
            nudgeDefaults.set(nudgePrimaryState.userQuitDeferrals, forKey: "userQuitDeferrals")
        }
    }

    func logUserSessionDeferrals(resetCount: Bool = false) {
        if Utils().demoModeEnabled() {
            nudgePrimaryState.userSessionDeferrals = 0
            return
        }
        if resetCount {
            nudgePrimaryState.userSessionDeferrals = 0
            nudgeDefaults.set(nudgePrimaryState.userSessionDeferrals, forKey: "userSessionDeferrals")
        } else {
            nudgeDefaults.set(nudgePrimaryState.userSessionDeferrals, forKey: "userSessionDeferrals")
        }
        
    }

    func logRequiredMinimumOSVersion() {
        nudgeDefaults.set(requiredMinimumOSVersion, forKey: "requiredMinimumOSVersion")
    }

    func newNudgeEvent() -> Bool {
        versionGreaterThan(currentVersion: requiredMinimumOSVersion, newVersion: nudgePrimaryState.userRequiredMinimumOSVersion)
    }

    func openMoreInfo() {
        guard let url = URL(string: aboutUpdateURL) else {
            return
        }
        uiLog.notice("\("User clicked moreInfo button", privacy: .public)")
        NSWorkspace.shared.open(url)
    }

    func pastRequiredInstallationDate() -> Bool {
        var pastRequiredInstallationDate = getCurrentDate() > requiredInstallationDate
        if demoModeEnabled() {
            pastRequiredInstallationDate = false
        }
        if !nudgeLogState.hasLoggedPastRequiredInstallationDate {
            nudgeLogState.hasLoggedPastRequiredInstallationDate = true
            utilsLog.notice("Device pastRequiredInstallationDate: \(pastRequiredInstallationDate, privacy: .public)")
        }
        return pastRequiredInstallationDate
    }

    func requireDualQuitButtons() -> Bool {
        if demoModeEnabled() {
            return true
        }
        if singleQuitButton {
            uiLog.info("Single quit button configured")
            return false
        }
        let requireDualQuitButtons = (approachingWindowTime / 24) >= getNumberOfDaysBetween()
        if !nudgePrimaryState.hasLoggedRequireDualQuitButtons {
            nudgePrimaryState.hasLoggedRequireDualQuitButtons = true
            uiLog.info("Device requireDualQuitButtons: \(requireDualQuitButtons, privacy: .public)")
        }
        return requireDualQuitButtons
    }

    func requireMajorUpgrade() -> Bool {
        let requireMajorUpdate = versionGreaterThan(currentVersion: String(getMajorRequiredNudgeOSVersion()), newVersion: String(getMajorOSVersion()))
        if !nudgeLogState.hasLoggedRequireMajorUgprade {
            nudgeLogState.hasLoggedRequireMajorUgprade = true
            utilsLog.info("Device requireMajorUpgrade: \(requireMajorUpdate, privacy: .public)")
        }
        return requireMajorUpdate
    }

    func setDeferralTime(deferralTime: Date) {
        if demoModeEnabled() {
            return
        }
        nudgeDefaults.set(deferralTime, forKey: "deferRunUntil")
    }
    
    func showEasterEgg() -> Bool {
        let components = Calendar.current.dateComponents([.day, .month], from: Utils().getCurrentDate())
        return (components.month == 8 && components.day == 6)
    }

    func simpleModeEnabled() -> Bool {
        let simpleModeEnabled = CommandLine.arguments.contains("-simple-mode")
        if !nudgeLogState.hasLoggedSimpleMode {
            if simpleModeEnabled {
                nudgeLogState.hasLoggedSimpleMode = true
                uiLog.debug("\("-simple-mode argument passed", privacy: .public)")
            }
        }
        return simpleModeEnabled
    }

    func updateDevice(userClicked: Bool = true) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        var url = String()
        if actionButtonPath != nil {
            if !actionButtonPath!.isEmpty {
                url = actionButtonPath!
            } else {
                prefsProfileLog.error("\("actionButtonPath contains empty string - actionButton will be unable to trigger any action.", privacy: .public)")
                return
            }
        } else if requireMajorUpgrade() {
            if majorUpgradeAppPathExists {
                url = majorUpgradeAppPath
            } else if majorUpgradeBackupAppPathExists {
                url = getBackupMajorUpgradeAppPath()
            } else { // Backup if all of these checks fail
                url = "/System/Library/CoreServices/Software Update.app"
            }
        } else {
            url = "/System/Library/CoreServices/Software Update.app"
            // NSWorkspace.shared.open(URL(fileURLWithPath: "x-apple.systempreferences:com.apple.preferences.softwareupdate?client=softwareupdateapp"))
        }
        
        if url.contains("://") {
            if userClicked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    NSWorkspace.shared.openApplication(at: URL(string: url)!, configuration: configuration)
                })
            } else {
                NSWorkspace.shared.openApplication(at: URL(string: url)!, configuration: configuration)
            }
        } else if url.contains("/bin/bash") || url.contains("/bin/sh") || url.contains("/bin/zsh") {
            let cmds = url.components(separatedBy: " ")
            let task = Process()
            task.launchPath = cmds.first!
            task.arguments = [cmds.last!]

            if userClicked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    do {
                        try task.run()
                    } catch {
                        uiLog.error("\("Error running script", privacy: .public)")
                    }
                })
            } else {
                do {
                    try task.run()
                } catch {
                    uiLog.error("\("Error running script", privacy: .public)")
                }
            }
        } else {
            if userClicked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: url), configuration: configuration)
                })
            } else {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: url), configuration: configuration)
            }
        }
        
        if userClicked {
            uiLog.notice("\("User clicked updateDevice", privacy: .public)")
            // turn off blur and allow windows to come above Nudge
            if Utils().pastRequiredInstallationDate() && aggressiveUserFullScreenExperience {
                if nudgePrimaryState.blurredBackground.count > 0 {
                    for (index, _) in screens.enumerated() {
                        nudgePrimaryState.blurredBackground[index].close()
                    }
                }
                NSApp.windows[0].level = .normal
            }
        } else {
            uiLog.notice("\("Synthetically clicked updateDevice due to allowedDeferral count", privacy: .public)")
        }
    }

    func userInitiatedExit() {
        uiLog.notice("\("User clicked primaryQuitButton", privacy: .public)")
        nudgePrimaryState.shouldExit = true
        if hideInsteadOfQuit {
            NSApp.hide(nil)
        } else {
            exit(0)
        }
    }

    func userInitiatedDeviceInfo() {
        uiLog.notice("\("User clicked deviceInfo", privacy: .public)")
    }

    func versionArgumentPassed() -> Bool {
        let versionArgumentPassed = CommandLine.arguments.contains("-version")
        if versionArgumentPassed {
            uiLog.debug("\("-version argument passed", privacy: .public)")
        }
        return versionArgumentPassed
    }

    func versionEqual(currentVersion: String, newVersion: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return currentVersion.compare(newVersion, options: .numeric) == .orderedSame
    }

    func versionGreaterThan(currentVersion: String, newVersion: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return currentVersion.compare(newVersion, options: .numeric) == .orderedDescending
    }

    func versionGreaterThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return currentVersion.compare(newVersion, options: .numeric) != .orderedAscending
    }

    func versionLessThan(currentVersion: String, newVersion: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return currentVersion.compare(newVersion, options: .numeric) == .orderedAscending
    }

    func versionLessThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
        // Adapted from https://stackoverflow.com/a/25453654
        return currentVersion.compare(newVersion, options: .numeric) != .orderedDescending
    }
}

func memoize<Input: Hashable, Output>(_ function: @escaping (Input) -> Output) -> (Input) -> Output {
    var storage = [Input: Output]()

    return { input in
        if let cached = storage[input] {
            return cached
        }

        let result = function(input)
        storage[input] = result
        return result
    }
}

func recursiveMemoize<Input: Hashable, Output>(_ function: @escaping ((Input) -> Output, Input) -> Output) -> (Input) -> Output {
    var storage = [Input: Output]()
    var memo: ((Input) -> Output)!

    memo = { input in
        if let cached = storage[input] {
            return cached
        }

        let result = function(memo, input)
        storage[input] = result
        return result
    }
    return memo
}
