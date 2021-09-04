//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import Foundation
import SystemConfiguration
import SwiftUI

// https://stackoverflow.com/questions/29985614/how-can-i-change-locale-programmatically-with-swift
// Apple recommends against this, but this is super frustrating since Nudge does dynamic UIs
extension String {
    func localized(desiredLanguage :String) ->String {
        // Try to get the language passed and if it does not exist, use en
        let path = Bundle.main.path(forResource: desiredLanguage, ofType: "lproj") ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}

extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}

struct Utils {
    func activateNudge() {
        var msg = "Re-activating Nudge"
        if demoModeEnabled() {
            msg = "Activating Nudge"
        }
        utilsLog.info("\(msg, privacy: .public)")
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows[0].makeKeyAndOrderFront(self)
    }

    func allow1HourDeferral() -> Bool {
        if demoModeEnabled() {
            return true
        }
        let allow1HourDeferralButton = getNumberOfHoursBetween() > 0
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
        let allow24HourDeferralButton = getNumberOfHoursBetween() > imminentWindowTime
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
        let allowCustomDeferralButton = getNumberOfHoursBetween() > approachingWindowTime
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allowCustomDeferralButton: \(allowCustomDeferralButton, privacy: .public)")
        }
        return allowCustomDeferralButton
    }

    func centerNudge() {
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.
        NSApp.windows[0].center()
    }

    func coerceStringToDate(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    func pathIsFileOrURL(path: String) -> Bool {
        //var returnValue : Bool = false
        if FileManager.default.fileExists(atPath: path) {
            return true
        }
        if path.hasPrefix("http") {
            // check that the URL resource is available
            utilsLog.debug("Checking Availability for \(path, privacy: .public)")
            var request = URLRequest(url: URL(string: path)!)
            request.httpMethod = "HEAD"
            
            let (_, response, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
            
            if let httpResponse = response as? HTTPURLResponse, error == nil {
                utilsLog.debug("Status Code \(httpResponse.statusCode, privacy: .public)")
                if httpResponse.statusCode == 200 {
                    return true
                }
            }
        }
        return false
    }
    
    func createImageData(fileImagePath: String, imgWidth: CGFloat? = .infinity, imgHeight: CGFloat? = .infinity, returnErrorImage: Bool = true) -> NSImage {
        // accept image as local file path or as URL and return NSImage
        // can pass in width and height as optional values otherwise return the image as is.
        
        utilsLog.debug("Creating image path for \(fileImagePath, privacy: .public)")
        
        // need to declare literal empty string first otherwise the runtime whinges about an NSURL instance with an empty URL string. I know!
        var urlPath = URL(string: "")
        var imageData = Data()
        var image = NSImage()
        
        let errorImageConfig = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)
        var errorImage = NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil)!.withSymbolConfiguration(errorImageConfig)!
        if !returnErrorImage {
            errorImage = NSImage()
        }
        
        // checking for anything starting with http
        // which means we create the image from URL directly not as fileURL
        if fileImagePath.hasPrefix("http") {
            //return errorImage
            urlPath = URL(string: fileImagePath)!
        } else {
            urlPath = URL(fileURLWithPath: fileImagePath)
        }
        
        // wrap everything in a try block. If the URL or filepath is unreadable then return a default image
        do {
            imageData = try Data(contentsOf: urlPath! as URL)
        } catch {
            uiLog.error("Error accessing file \(fileImagePath, privacy: .public). Resource not available")
            return errorImage
        }
        
        // We have our image data - time to process it and return with specified dimensions
        image = NSImage(data: imageData as Data) ?? errorImage
        
        if let rep = NSImage(data: imageData as Data)?
            .bestRepresentation(for: NSRect(x: 0, y: 0, width: imgWidth!, height: imgHeight!), context: nil, hints: nil) {
            image.size = rep.size
            image.addRepresentation(rep)
        }
        return image
    }

    func debugUIModeEnabled() -> Bool {
        let debugUIModeArgumentPassed = CommandLine.arguments.contains("-debug-ui-mode")
        if !nudgeLogState.afterFirstRun {
            if debugUIModeArgumentPassed {
                let msg = "-debug-ui-mode argument passed"
                uiLog.debug("\(msg, privacy: .public)")
            }
        }
        return debugUIModeArgumentPassed
    }

    func demoModeEnabled() -> Bool {
        let demoModeArgumentPassed = CommandLine.arguments.contains("-demo-mode")
        if !nudgeLogState.hasLoggedDemoMode {
            if demoModeArgumentPassed {
                nudgeLogState.hasLoggedDemoMode = true
                let msg = "-demo-mode argument passed"
                uiLog.debug("\(msg, privacy: .public)")
            }
        }
        return demoModeArgumentPassed
    }

    func exitNudge() {
        let msg = "Nudge is terminating due to condition met"
        uiLog.notice("\(msg, privacy: .public)")
        nudgePrimaryState.shouldExit = true
        exit(0)
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let forceScreenShotIconMode = CommandLine.arguments.contains("-force-screenshot-icon")
        if !nudgeLogState.hasLoggedScreenshotIconMode {
            if forceScreenShotIconMode {
                nudgeLogState.hasLoggedScreenshotIconMode = true
                let msg = "-force-screenshot-icon argument passed"
                uiLog.debug("\(msg, privacy: .public)")
            }
        }
        return forceScreenShotIconMode
    }

    func fullyUpdated() -> Bool {
        let fullyUpdated = versionGreaterThanOrEqual(currentVersion: currentOSVersion, newVersion: requiredMinimumOSVersion)
        if fullyUpdated {
            let msg = "Current operating system (\(currentOSVersion)) is greater than or equal to required operating system (\(requiredMinimumOSVersion))"
            utilsLog.notice("\(msg, privacy: .public)")
            return true
        } else {
            return false
        }
    }
    
    func getCompanyLogoPath(darkMode: Bool) -> String {
        if darkMode {
            return iconDarkPath
        } else {
            return iconLightPath
        }
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
            utilsLog.debug("\(msg, privacy: .public)")
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            let msg = "CPU Type is Apple Silicon"
            utilsLog.debug("\(msg, privacy: .public)")
            return "Apple Silicon"
        }
        let msg = "Unknown CPU Type"
        utilsLog.debug("\(msg, privacy: .public)")
        return "unknown"
    }

    func getCurrentDate() -> Date {
        Date()
    }

    func getJSONUrl() -> String {
        let jsonURL = nudgeDefaults.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        utilsLog.debug("JSON url: \(jsonURL, privacy: .public)")
        return jsonURL
    }

    func getInitialDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.date(from: "08-06-2020") ?? Date() // <3
    }

    func getMajorOSVersion() -> Int {
        let MajorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        if !nudgePrimaryState.hasLoggedMajorOSVersion {
            nudgePrimaryState.hasLoggedMajorOSVersion = true
            utilsLog.info("OS Version: \(MajorOSVersion, privacy: .public)")
        }
        return MajorOSVersion
    }

    func getMajorRequiredNudgeOSVersion() -> Int {
        let parts = requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        let majorRequiredNudgeOSVersion = Int((parts[0]))!
        if !nudgePrimaryState.hasLoggedMajorRequiredOSVersion {
            nudgePrimaryState.hasLoggedMajorRequiredOSVersion = true
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
            let msg = "Could not find on-disk json"
            prefsJSONLog.error("\(msg, privacy: .public)")
            return nil
        }
        
        if Utils().demoModeEnabled() {
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
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
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

    func getNumberOfHoursBetween() -> Int {
        return Int(requiredInstallationDate.timeIntervalSince(getCurrentDate()) / 3600 )
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

            utilsLog.debug("Serial Number: \(serialNumber, privacy: .public)")
            return serialNumber
        }

        return serialNumber ?? ""
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
            utilsLog.info("Timer cycle: \(timerCycle, privacy: .public)")
            nudgePrimaryState.timerCycle = timerCycle
        }
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

    func logUserDeferrals(resetCount: Bool = false) {
        if Utils().demoModeEnabled() {
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
        let msg = "User clicked moreInfo button"
        uiLog.notice("\(msg, privacy: .public)")
        NSWorkspace.shared.open(url)
    }

    func pastRequiredInstallationDate() -> Bool {
        if demoModeEnabled() {
            return false
        }
        let pastRequiredInstallationDate = getCurrentDate() > requiredInstallationDate
        if !nudgePrimaryState.hasLoggedPastRequiredInstallationDate {
            nudgePrimaryState.hasLoggedPastRequiredInstallationDate = true
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
        if !nudgePrimaryState.hasLoggedRequireMajorUgprade {
            nudgePrimaryState.hasLoggedRequireMajorUgprade = true
            utilsLog.info("Device requireMajorUpgrade: \(requireMajorUpdate, privacy: .public)")
        }
        return requireMajorUpdate
    }

    func simpleModeEnabled() -> Bool {
        let simpleModeEnabled = CommandLine.arguments.contains("-simple-mode")
        if !nudgeLogState.hasLoggedSimpleMode {
            if simpleModeEnabled {
                nudgeLogState.hasLoggedSimpleMode = true
                let msg = "-simple-mode argument passed"
                uiLog.debug("\(msg, privacy: .public)")
            }
        }
        return simpleModeEnabled
    }

    func unsafeSoftwareUpdate() -> Bool {
        let runningUnsafeSoftwareUpdateOSVersion = versionLessThan(currentVersion: currentOSVersion, newVersion: "11.4")
        if runningUnsafeSoftwareUpdateOSVersion {
            return true
        } else {
            return false
        }
    }

    func updateDevice(userClicked: Bool = true) {
        if userClicked {
            let msg = "User clicked updateDevice"
            uiLog.notice("\(msg, privacy: .public)")
        } else {
            let msg = "Synthetically clicked updateDevice due to allowedDeferral count"
            uiLog.notice("\(msg, privacy: .public)")
        }
        if actionButtonPath != nil {
            if !actionButtonPath!.isEmpty {
                NSWorkspace.shared.open(URL(string: actionButtonPath!)!)
            } else {
                let msg = "actionButtonPath contains empty string - actionButton will be unable to trigger any action."
                prefsProfileLog.warning("\(msg, privacy: .public)")
            }
        } else if requireMajorUpgrade() && majorUpgradeAppPathExists {
            NSWorkspace.shared.open(URL(fileURLWithPath: majorUpgradeAppPath))
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"))
            // NSWorkspace.shared.open(URL(fileURLWithPath: "x-apple.systempreferences:com.apple.preferences.softwareupdate?client=softwareupdateapp"))
        }
    }

    func userInitiatedExit() {
        let msg = "User clicked primaryQuitButton"
        uiLog.notice("\(msg, privacy: .public)")
        nudgePrimaryState.shouldExit = true
        exit(0)
    }

    func userInitiatedDeviceInfo() {
        let msg = "User clicked deviceInfo"
        uiLog.notice("\(msg, privacy: .public)")
    }

    func versionArgumentPassed() -> Bool {
        let versionArgumentPassed = CommandLine.arguments.contains("-version")
        if versionArgumentPassed {
            let msg = "-version argument passed"
            uiLog.debug("\(msg, privacy: .public)")
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

extension FixedWidthInteger {
    // https://stackoverflow.com/a/63539782
    var byteWidth:Int {
        return self.bitWidth/UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth/UInt8.bitWidth
    }
}
