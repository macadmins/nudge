//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import CoreMediaIO
import Foundation
import Intents
import IOKit
#if canImport(ServiceManagement)
import ServiceManagement
#endif
import SwiftUI
import SystemConfiguration

struct AppStateManager {
    func activateNudge() {
        if OptionalFeatureVariables.honorFocusModes {
            LogManager.info("honorFocusModes is configured - checking focus status. Warning: This feature may be unstable.", logger: utilsLog)
            if isFocusModeEnabled() {
                LogManager.info("Device has focus modes set - bypassing activation event", logger: utilsLog)
                return
            }
        }
        LogManager.info("Activating Nudge", logger: utilsLog)
        nudgePrimaryState.lastRefreshTime = DateManager().getCurrentDate()
        guard let mainWindow = NSApp.windows.first else { return }
        LoggerUtilities().logUserSessionDeferrals()
        LoggerUtilities().logUserQuitDeferrals()
        LoggerUtilities().logUserDeferrals()

        // When the window is allowed to be moved, all of the other controls no longer force centering, so we need to force centering when re-activating.
        if UserExperienceVariables.allowMovableWindow {
            UIUtilities().centerNudge()
        }

        if DateManager().pastRequiredInstallationDate() && OptionalFeatureVariables.aggressiveUserFullScreenExperience {
            UIUtilities().centerNudge()
            NSApp.activate(ignoringOtherApps: true)
            mainWindow.makeKeyAndOrderFront(nil)
            applyBackgroundBlur(to: mainWindow)
            return
        }

        if NSWorkspace.shared.isActiveSpaceFullScreen() && !nudgePrimaryState.afterFirstStateChange {
            LogManager.notice("Bypassing activation due to full screen bugs in macOS", logger: uiLog)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }

    func allow1HourDeferral() -> Bool {
        return isDeferralAllowed(threshold: 0, logMessage: "Device allow1HourDeferralButton")
    }

    func allow24HourDeferral() -> Bool {
        return isDeferralAllowed(threshold: UserExperienceVariables.imminentWindowTime, logMessage: "Device allow24HourDeferralButton")
    }

    func allowCustomDeferral() -> Bool {
        return isDeferralAllowed(threshold: UserExperienceVariables.approachingWindowTime, logMessage: "Device allowCustomDeferralButton")
    }

    private func applyBackgroundBlur(to window: NSWindow) {
        // Figure out all the screens upon Nudge launching
        UIConstants.screens.forEach { screen in
            loopedScreen = screen
        }
        // load the blur background and send it to the back if we are past the required install date
        if nudgePrimaryState.backgroundBlur.isEmpty {
            LogManager.info("Enabling blurred background", logger: uiLog)
            UIConstants.screens.forEach { screen in
                let blurWindowController = BackgroundBlurWindowController()
                blurWindowController.loadWindow()
                blurWindowController.showWindow(nil)
                loopedScreen = screen
                nudgePrimaryState.backgroundBlur.append(blurWindowController)
            }
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
        } else {
            LogManager.info("Background blur currently set", logger: uiLog)
        }
    }

    private func calculateNewRequiredInstallationDateIfNeeded(currentDate: Date, gracePeriodPathCreationDate: Date) -> Date {
        let gracePeriodInstallDelay = UserExperienceVariables.gracePeriodInstallDelay
        let gracePeriodLaunchDelay = UserExperienceVariables.gracePeriodLaunchDelay
        let gracePeriodPath = UserExperienceVariables.gracePeriodPath
        let gracePeriodPathCreationTimeInHours = Int(currentDate.timeIntervalSince(gracePeriodPathCreationDate) / 3600)
        let gracePeriodsDelay = gracePeriodInstallDelay + gracePeriodLaunchDelay
        let originalRequiredInstallationDate = requiredInstallationDate

        // Bail Nudge if within gracePeriodLaunchDelay
        if gracePeriodLaunchDelay > gracePeriodPathCreationTimeInHours {
            LogManager.info("gracePeriodPath (\(gracePeriodPath)) within gracePeriodLaunchDelay (\(gracePeriodLaunchDelay)) - File age is \(gracePeriodPathCreationTimeInHours) hours", logger: uiLog)
            nudgePrimaryState.shouldExit = true
            return currentDate
        } else {
            LogManager.info("gracePeriodPath (\(gracePeriodPath)) outside of gracePeriodLaunchDelay (\(gracePeriodLaunchDelay)) - File age is \(gracePeriodPathCreationTimeInHours) hours", logger: uiLog)
        }

        if gracePeriodInstallDelay > gracePeriodPathCreationTimeInHours {
            if currentDate > originalRequiredInstallationDate {
                requiredInstallationDate = currentDate.addingTimeInterval(Double(gracePeriodsDelay) * 3600)
                LogManager.info("Device permitted for gracePeriodInstallDelay - setting date from: \(originalRequiredInstallationDate) to: \(requiredInstallationDate)", logger: uiLog)
                return requiredInstallationDate
            }
        } else {
            LogManager.info("gracePeriodPath (\(gracePeriodPath)) outside of gracePeriodInstallDelay (\(gracePeriodInstallDelay)) - File age is \(gracePeriodPathCreationTimeInHours) hours", logger: uiLog)
        }
        return PrefsWrapper.requiredInstallationDate
    }

    func exitNudge() {
        LogManager.notice("Nudge is terminating due to condition met", logger: uiLog)
        nudgePrimaryState.shouldExit = true
        exit(0)
    }

    func getCreationDateForPath(_ path: String, testFileDate: Date?) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)

            // Check if the file size is 0
            if let fileSize = attributes[.size] as? Int, fileSize == 0 {
                // If file size is 0 and testFileDate is provided, use testFileDate
                if let testDate = testFileDate {
                    return testDate
                } else {
                    // Fallback to the creation date from the file attributes if testFileDate is nil
                    return attributes[.creationDate] as? Date ?? DateManager().coerceStringToDate(dateString: "2020-08-06T00:00:00Z")
                }
            }

            // Return the creation date from the file attributes if the file size is not 0
            return attributes[.creationDate] as? Date ?? DateManager().coerceStringToDate(dateString: "2020-08-06T00:00:00Z")

        } catch {
            print("Error retrieving file attributes: \(error)")
            return DateManager().coerceStringToDate(dateString: "2020-08-06T00:00:00Z")
        }
    }


    func getModifiedDateForPath(_ path: String, testFileDate: Date?) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        if attributes?[.size] as? Int == 0  && testFileDate == nil {
            return DateManager().coerceStringToDate(dateString: "2020-08-06T00:00:00Z")
        }
        let creationDate = attributes?[.modificationDate] as? Date
        return testFileDate ?? creationDate
    }

    // Adapted from https://github.com/ProfileCreator/ProfileCreator/blob/master/ProfileCreator/ProfileCreator/Extensions/ExtensionBundle.swift
    func getSigningInfo() -> String? {
        var osStatus = noErr
        var codeRef: SecStaticCode?

        osStatus = SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &codeRef)
        guard osStatus == noErr, let code = codeRef else {
            LogManager.error("Failed to create static code: \(SecCopyErrorMessageString(osStatus, nil) as String? ?? "")", logger: utilsLog)
            return nil
        }

        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        var codeInfoRef: CFDictionary?
        osStatus = SecCodeCopySigningInformation(code, flags, &codeInfoRef)
        guard osStatus == noErr, let codeInfo = codeInfoRef as? [String: Any] else {
            LogManager.error("Failed to copy code signing information: \(SecCopyErrorMessageString(osStatus, nil) as String? ?? "")", logger: utilsLog)
            return nil
        }

        guard let teamIdentifier = codeInfo[kSecCodeInfoTeamIdentifier as String] as? String else {
            LogManager.error("No entry for team identifier in code signing info", logger: utilsLog)
            return nil
        }

        guard let certificates = codeInfo[kSecCodeInfoCertificates as String] as? [SecCertificate],
                let firstCertificate = certificates.first,
              let signingCertificateSummary = SecCertificateCopySubjectSummary(firstCertificate) as String? else {
            LogManager.error("Failed to get certificate summary - returning teamIdentifier", logger: utilsLog)
            return teamIdentifier
        }

        return signingCertificateSummary
    }

    func gracePeriodLogic(currentDate: Date? = nil, testFileDate: Date? = nil) -> Date {
        let computedCurrentDate = currentDate == nil ? Date() : currentDate!
        guard UserExperienceVariables.allowGracePeriods || PrefsWrapper.allowGracePeriods,
              !CommandLineUtilities().demoModeEnabled() else {
            return PrefsWrapper.requiredInstallationDate
        }

        let gracePeriodPath = UserExperienceVariables.gracePeriodPath
        guard FileManager.default.fileExists(atPath: gracePeriodPath) || CommandLineUtilities().unitTestingEnabled(),
              let gracePeriodPathCreationDate = getCreationDateForPath(gracePeriodPath, testFileDate: testFileDate) else {
            LogManager.error("Grace period path \(UserExperienceVariables.gracePeriodPath) not found or unable to get creation date - bypassing allowGracePeriods logic", logger: uiLog)
            return PrefsWrapper.requiredInstallationDate
        }

        return calculateNewRequiredInstallationDateIfNeeded(currentDate: computedCurrentDate, gracePeriodPathCreationDate: gracePeriodPathCreationDate)
    }

    func delayNudgeEventLogic(currentDate: Date = DateManager().getCurrentDate(), testFileDate: Date? = nil) -> Date {
        let isMajorUpgradeRequired = AppStateManager().requireMajorUpgrade()
        let launchDelay = isMajorUpgradeRequired ? UserExperienceVariables.nudgeMajorUpgradeEventLaunchDelay : UserExperienceVariables.nudgeMinorUpdateEventLaunchDelay
        
        if launchDelay == 0 {
            return PrefsWrapper.requiredInstallationDate
        }

        if releaseDate.addingTimeInterval(TimeInterval(launchDelay * 86400)) > currentDate {
            let eventType = isMajorUpgradeRequired ? "nudgeMajorUpgradeEventLaunchDelay" : "nudgeMinorUpdateEventLaunchDelay"
            LogManager.info("Device within \(eventType)", logger: uiLog)
            nudgePrimaryState.shouldExit = true
            return currentDate
        } else {
            let eventType = isMajorUpgradeRequired ? "nudgeMajorUpgradeEventLaunchDelay" : "nudgeMinorUpdateEventLaunchDelay"
            LogManager.info("Device outside \(eventType)", logger: uiLog)
            return PrefsWrapper.requiredInstallationDate
        }
    }

    private func isDeferralAllowed(threshold: Int, logMessage: String) -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        let hoursRemaining = DateManager().getNumberOfHoursRemaining()
        let isAllowed = hoursRemaining > threshold
        if !nudgeLogState.afterFirstRun {
            LogManager.info("\(logMessage): \(isAllowed)", logger: uiLog)
        }
        return isAllowed
    }

    func isFocusModeEnabled() -> Bool {
        let appID = "com.apple.controlcenter" as CFString
        let key = "NSStatusItem Visible FocusModes" as CFString
        let userName = kCFPreferencesCurrentUser
        let hostName = kCFPreferencesAnyHost

        if let value = CFPreferencesCopyAppValue(key, appID) as? Bool {
            return value
        } else {
            LogManager.info("Key '\(key)' not found in preferences", logger: uiLog)
            return false
        }

        //
        //            // Request the current focus status
        //            // TODO: This will break Nudge unless you have NSFocusStatusUsageDescription in the Info.plist
        //            INFocusStatusCenter.default.requestAuthorization { status in
        //                if status == .authorized {
        //                    if INFocusStatusCenter.default.focusStatus.isFocused == true {
        //                        LogManager.info("Device has focus modes set - bypassing activation event", logger: utilsLog)
        //                        return
        //                    }
        //                } else {
        //                    LogManager.info("Focus status authorization not granted", logger: utilsLog)
        //                }
        //            }
    }

    private func logOnce(_ message: String, state: inout Bool) {
        if !state {
            LogManager.info("\(message)", logger: uiLog)
            state = true
        }
    }

    func requireDualQuitButtons() -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        if UserInterfaceVariables.singleQuitButton {
            logOnce("Single quit button configured", state: &nudgePrimaryState.hasLoggedRequireDualQuitButtons)
            return false
        }
        let requireDualButtons = (UserExperienceVariables.approachingWindowTime / 24) >= DateManager().getNumberOfDaysBetween()
        logOnce("Device requireDualQuitButtons: \(requireDualButtons)", state: &nudgePrimaryState.hasLoggedRequireDualQuitButtons)
        return requireDualButtons
    }

    func requireMajorUpgrade() -> Bool {
        let majorRequiredVersion = VersionManager.getMajorRequiredNudgeOSVersion()
        let currentMajorVersion = VersionManager.getMajorOSVersion()
        let requireMajorUpdate = VersionManager.versionGreaterThan(currentVersion: String(majorRequiredVersion), newVersion: String(currentMajorVersion))
        logOnce("Device requireMajorUpgrade: \(requireMajorUpdate)", state: &nudgeLogState.hasLoggedRequireMajorUgprade)
        return requireMajorUpdate
    }
}

// https://stackoverflow.com/questions/37470201/how-can-i-tell-if-the-camera-is-in-use-by-another-process
// led me to https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm
// Complete credit to https://github.com/ttimpe/camera-usage-detector-mac/blob/845df180f9d19463e8fd382277e2f61d88ca7d5d/CameraUsage/CameraUsageController.swift
// kCMIODevicePropertyDeviceIsRunningSomewhere is the key here
struct CameraManager {
    var id: CMIOObjectID

    var isOn: Bool {
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard))

        var isUsed = false
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(id, &opa, 0, nil, &dataSize)
        guard result == kCMIOHardwareNoError, let data = malloc(Int(dataSize)) else { return false }

        result = CMIOObjectGetPropertyData(id, &opa, 0, nil, dataSize, &dataUsed, data)
        if result == kCMIOHardwareNoError {
            let on = data.assumingMemoryBound(to: UInt8.self)
            isUsed = on.pointee != 0
        }
        free(data)

        return isUsed
    }

    var name: String? {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))

        var nameCFString: CFString?
        let propsize = UInt32(MemoryLayout<UnsafeMutablePointer<CFString?>>.size)
        var dataUsed = UInt32(0)
        var result: OSStatus = 0

        withUnsafeMutablePointer(to: &nameCFString) { namePtr in
            result = CMIOObjectGetPropertyData(id, &address, 0, nil, propsize, &dataUsed, namePtr)
        }

        guard result == 0 else { return "" }
        return nameCFString as String?
    }
}

struct CameraUtilities {
    func getCameras() -> [CameraManager] {
        var innerArray: [CameraManager] = []
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))

        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize)
        guard result == kCMIOHardwareNoError, let devices = malloc(Int(dataSize)) else { return [] }

        result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, devices)
        guard result == kCMIOHardwareNoError else {
            free(devices)
            return []
        }

        for offset in stride(from: 0, to: Int(dataSize), by: MemoryLayout<CMIOObjectID>.size) {
            let current = devices.advanced(by: offset).assumingMemoryBound(to: CMIOObjectID.self)
            innerArray.append(CameraManager(id: current.pointee))
        }

        free(devices)
        return innerArray
    }
}

import Foundation

struct CommandLineUtilities {
    let arguments: [String] = CommandLine.arguments

    // Existing argument checks
    func bundleModeJSONEnabled() -> Bool {
        return checkAndLogArgument("-bundle-mode-json", logStateKey: &nudgeLogState.hasLoggedBundleMode)
    }

    func bundleModeProfileEnabled() -> Bool {
        return checkAndLogArgument("-bundle-mode-profile", logStateKey: &nudgeLogState.hasLoggedBundleMode)
    }

    func customSOFAFeedURLOption() -> String? {
        return valueForArgument("-custom-sofa-feed-url")
    }

    func debugUIModeEnabled() -> Bool {
        return checkAndLogArgument("-debug-ui-mode", logStateKey: &nudgeLogState.afterFirstRun)
    }

    func demoModeEnabled() -> Bool {
        return checkAndLogArgument("-demo-mode", logStateKey: &nudgeLogState.hasLoggedDemoMode)
    }

    func disableRandomDelayArgumentPassed() -> Bool {
        return arguments.contains("-disable-random-delay")
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        return checkAndLogArgument("-force-screenshot-icon", logStateKey: &nudgeLogState.hasLoggedScreenshotIconMode)
    }

    func registerSMAppArgumentPassed() -> Bool {
        return arguments.contains("--register")
    }

    func simpleModeEnabled() -> Bool {
        return checkAndLogArgument("-simple-mode", logStateKey: &nudgeLogState.hasLoggedSimpleMode)
    }

    func unitTestingEnabled() -> Bool {
        return checkAndLogArgument("-unit-testing", logStateKey: &nudgeLogState.hasLoggedUnitTestingMode)
    }

    func unregisterSMAppArgumentPassed() -> Bool {
        return arguments.contains("--unregister")
    }

    func versionArgumentPassed() -> Bool {
        let argumentPassed = arguments.contains("-version")
        if argumentPassed {
            LogManager.debug("-version argument passed", logger: uiLog)
        }
        return argumentPassed
    }

    func simulateDate() -> String? {
        return valueForArgument("-simulate-date")
    }

    func simulateHardwareID() -> String? {
        return valueForArgument("-simulate-hardware-id")
    }

    func simulateOSVersion() -> String? {
        return valueForArgument("-simulate-os-version")
    }

    private func checkAndLogArgument(_ argument: String, logStateKey: inout Bool) -> Bool {
        let argumentPassed = arguments.contains(argument)
        if argumentPassed && !logStateKey {
            LogManager.debug("\(argument) argument passed", logger: uiLog)
            logStateKey = true
        }
        return argumentPassed
    }

    // Helper function to get value for argument
    private func valueForArgument(_ argument: String) -> String? {
        if let index = arguments.firstIndex(of: argument), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        return nil
    }
}


struct ConfigurationManager {
    private func determineTimerCycle(basedOn secondsRemaining: Int) -> Int {
        switch secondsRemaining {
            case ...0:
                return UserExperienceVariables.elapsedRefreshCycle
            case ...(UserExperienceVariables.imminentWindowTime * 3600):
                return UserExperienceVariables.imminentRefreshCycle
            case ...(UserExperienceVariables.approachingWindowTime * 3600):
                return UserExperienceVariables.approachingRefreshCycle
            default:
                return UserExperienceVariables.initialRefreshCycle
        }
    }

    func getConfigurationAsJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601  // Use ISO 8601 date format

        guard let nudgeJSONConfig = try? encoder.encode(Globals.nudgeJSONPreferences),
              let json = try? JSONSerialization.jsonObject(with: nudgeJSONConfig),
              let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            LogManager.error("Failed to serialize JSON configuration", logger: uiLog)
            return Data()
        }
        return jsonData
    }

    func getConfigurationAsProfile() -> Data {
        var nudgeProfileConfig = [String: Any]()
        if CommandLineUtilities().bundleModeJSONEnabled() {
            return Data()
        }
        if CommandLineUtilities().bundleModeProfileEnabled(), let bundleUrl = Globals.bundle.url(forResource: "com.github.macadmins.Nudge.tester", withExtension: "plist") {
            LogManager.debug("Profile url: \(bundleUrl)", logger: utilsLog)
            guard let data = try? Data(contentsOf: bundleUrl) else {
                LogManager.error("Failed to load profile data from URL.", logger: uiLog)
                return Data()
            }
            do {
                let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                if let dictionary = plist as? [String: AnyObject] {
                    nudgeProfileConfig = dictionary
                } else {
                    LogManager.error("Plist is not a dictionary.", logger: uiLog)
                    return Data()
                }
            } catch {
                LogManager.error("Error reading plist: \(error)", logger: uiLog)
                return Data()
            }
        } else {
            nudgeProfileConfig["optionalFeatures"] = Globals.nudgeDefaults.dictionary(forKey: "optionalFeatures")
            nudgeProfileConfig["osVersionRequirements"] = Globals.nudgeDefaults.array(forKey: "osVersionRequirements")
            nudgeProfileConfig["userExperience"] = Globals.nudgeDefaults.dictionary(forKey: "userExperience")
            nudgeProfileConfig["userInterface"] = Globals.nudgeDefaults.dictionary(forKey: "userInterface")
        }

        guard !nudgeProfileConfig.isEmpty,
              let plistData = try? PropertyListSerialization.data(fromPropertyList: nudgeProfileConfig, format: .xml, options: 0),
              let xmlPlistData = try? XMLDocument(data: plistData, options: .nodePreserveAll) else {
            LogManager.error("Failed to serialize profile configuration", logger: uiLog)
            return Data()
        }

        return xmlPlistData.xmlData(options: .nodePrettyPrint)
    }

    func getTimerController() -> Int {
        let secondsRemaining = DateManager().getNumberOfSecondsRemaining()
        let timerCycle = determineTimerCycle(basedOn: secondsRemaining)

        if timerCycle != nudgePrimaryState.timerCycle {
            LogManager.info("timerCycle: \(timerCycle)", logger: uiLog)
            nudgePrimaryState.timerCycle = timerCycle
        }
        return timerCycle
    }
}

struct DateManager {
    let dateFormatterISO8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    let dateFormatterLocalTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    func coerceDateToString(date: Date, formatterString: String, locale: Locale? = nil) -> String {
        if formatterString == "MM/dd/yyyy" {
            // Use the specified locale or the current locale if none is provided
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateFormatter.locale = locale ?? Locale.current
            return dateFormatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = formatterString
            formatter.locale = locale ?? Locale.current
            return formatter.string(from: date)
        }
    }

    func coerceStringToDate(dateString: String) -> Date {
        if dateString.contains("Z") {
            dateFormatterISO8601.date(from: dateString) ?? getCurrentDate()
        } else {
            dateFormatterLocalTime.date(from: dateString) ?? getCurrentDate()
        }
    }

    func convertToUserCalendar(date: Date) -> Date {
        let userCalendar = Calendar.current

        // Get date components in the user's calendar
        let components = userCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        // Create a new Date object in the user's calendar
        if let userCalendarDate = userCalendar.date(from: components) {
            return userCalendarDate
        } else {
            return date
        }
    }

    func getCurrentDate() -> Date {
        let dateFormatterISO8601 = ISO8601DateFormatter()

        if (CommandLineUtilities().simulateDate() != nil) {
            // Try to parse the provided ISO8601 string
            if let date = dateFormatterISO8601.date(from: CommandLineUtilities().simulateDate()!) {
                if !nudgeLogState.hasLoggedSimulatedDate {
                    LogManager.notice("Simulated Date set via -simulated-date, returning \(CommandLineUtilities().simulateDate()!)", logger: uiLog)
                    nudgeLogState.hasLoggedSimulatedDate = true
                }
                return date
            } else {
                if !nudgeLogState.hasLoggedSimulatedDate {
                    LogManager.error("Failed to parse -simulated-date, returning current date.", logger: uiLog)
                    nudgeLogState.hasLoggedSimulatedDate = true
                }
                return Date()
            }
        } else {
            // If no string is provided, return the current date based on calendar
            switch Calendar.current.identifier {
            case .buddhist, .japanese, .gregorian, .coptic, .ethiopicAmeteMihret, .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura, .persian:
                return dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
            default:
                return Date()
            }
        }
    }

    func getFormattedDate(date: Date? = nil) -> Date {
        let initialDate = dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: date ?? Date())) ?? Date()
        switch Calendar.current.identifier {
            case .gregorian:
                return initialDate
            default:
                return convertToUserCalendar(date: initialDate)
        }
    }


    func getNumberOfDaysBetween() -> Int {
        guard !CommandLineUtilities().demoModeEnabled() else { return 0 }
        let fromDate = Calendar.current.startOfDay(for: getCurrentDate())
        let toDate = Calendar.current.startOfDay(for: requiredInstallationDate)
        return Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day ?? 0
    }

    func getNumberOfHoursRemaining(currentDate: Date = DateManager().getCurrentDate()) -> Int {
        guard !CommandLineUtilities().demoModeEnabled() else { return 24 }
        let interval = CommandLineUtilities().unitTestingEnabled() ? PrefsWrapper.requiredInstallationDate : requiredInstallationDate
        return Int(interval.timeIntervalSince(currentDate) / 3600)
    }

    func getNumberOfSecondsRemaining(currentDate: Date = DateManager().getCurrentDate()) -> Int {
        guard !CommandLineUtilities().demoModeEnabled() else { return 24 * 3600 }
        let interval = CommandLineUtilities().unitTestingEnabled() ? PrefsWrapper.requiredInstallationDate : requiredInstallationDate
        return Int(interval.timeIntervalSince(currentDate))
    }

    func pastRequiredInstallationDate() -> Bool {
        let isPast = getCurrentDate() > requiredInstallationDate
        if !CommandLineUtilities().demoModeEnabled() && !nudgeLogState.hasLoggedPastRequiredInstallationDate {
            nudgeLogState.hasLoggedPastRequiredInstallationDate = true
            LogManager.info("Device pastRequiredInstallationDate: \(isPast)", logger: utilsLog)
        }
        return isPast
    }
}

struct DeviceManager {
    func getCPUTypeInt() -> Int {
        // https://stackoverflow.com/a/63539782
        var cputype = cpu_type_t()
        var size = MemoryLayout.size(ofValue: cputype)
        let result = sysctlbyname("hw.cputype", &cputype, &size, nil, 0)
        return result == -1 ? -1 : Int(cputype)
    }

    func getBridgeModelID() -> String {
        let (output, error, exitCode) = SubProcessUtilities().runProcess(launchPath: "/usr/libexec/remotectl", arguments: ["get-property", "localbridge", "HWModel"])

        if exitCode != 0 {
            LogManager.error("Error assessing DeviceID: \(error)", logger: softwareupdateDeviceLog)
            return ""
        } else {
            LogManager.info("SoftwareUpdateDeviceID: \(output)", logger: softwareupdateDeviceLog)
            return output
        }
    }

    func getCPUTypeString() -> String {
        // https://stackoverflow.com/a/63539782
        let type = getCPUTypeInt()
        guard type != -1 else {
            return "error in CPU type"
        }

        let cpuArch = type & 0xff // Mask for architecture bits

        switch cpuArch {
            case Int(CPU_TYPE_X86) /* Intel */:
                LogManager.debug("CPU Type: Intel", logger: utilsLog)
                return "Intel"
            case Int(CPU_TYPE_ARM) /* Apple Silicon */:
                LogManager.debug("CPU Type: Apple Silicon", logger: utilsLog)
                return "Apple Silicon"
            default:
                LogManager.debug("CPU Type: Unknown", logger: utilsLog)
                return "unknown"
        }
    }

    func getHardwareModel() -> String {
        getSysctlValue(for: "hw.model") ?? ""
    }
    
    func getVirtualMachineStatus() -> Bool {
        if getSysctlValue(for: "kern.hv_vmm_present") == "1" {
            return true
        }
        return false
    }

    func getHardwareModelIDs() -> [String] {
        var boardID = getIORegInfo(serviceTarget: "board-id") ?? "Unknown"
        let bridgeID = getBridgeModelID()
        let hardwareModelID = getIORegInfo(serviceTarget: "target-sub-type") ?? "Unknown"
        let gestaltModelStringID = getKeyResultFromGestalt("HWModelStr")
        
        if getVirtualMachineStatus() && getCPUTypeString() == "Intel" {
            boardID = "VMM-x86_64"
        }

        LogManager.debug("Hardware Board ID: \(boardID)", logger: utilsLog)
        LogManager.debug("Hardware Bridge ID: \(bridgeID)", logger: utilsLog)
        LogManager.debug("Hardware Model ID: \(hardwareModelID)", logger: utilsLog)
        LogManager.debug("Gestalt Hardware Model ID: \(gestaltModelStringID)", logger: utilsLog)

        if (CommandLineUtilities().simulateHardwareID() != nil) {
            return [CommandLineUtilities().simulateHardwareID()!, CommandLineUtilities().simulateHardwareID()!, CommandLineUtilities().simulateHardwareID()!, CommandLineUtilities().simulateHardwareID()!]
        }

        return [boardID.trimmingCharacters(in: .whitespacesAndNewlines), bridgeID.trimmingCharacters(in: .whitespacesAndNewlines), hardwareModelID.trimmingCharacters(in: .whitespacesAndNewlines), gestaltModelStringID.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    func getHardwareUUID() -> String {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return "DC3F0981-D881-408F-BED7-8D6F1DEE8176"
        }
        return getPropertyFromPlatformExpert(key: String(kIOPlatformUUIDKey)) ?? ""
    }

    func getIORegInfo(serviceTarget: String) -> String? {
        let service: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        defer {
            IOObjectRelease(service)
        }

        guard service != 0 else {
            LogManager.error("Failed to fetch IOPlatformExpertDevice service.", logger: utilsLog)
            return nil
        }

        guard let property = IORegistryEntryCreateCFProperty(service, serviceTarget as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            LogManager.error("Failed to fetch \(serviceTarget) property.", logger: utilsLog)
            return nil
        }

        //        print(CFGetTypeID(property))
        //        print(CFStringGetTypeID())
        //        if let propertyDescription = CFCopyTypeIDDescription(CFGetTypeID(property)) {
        //            print("Property type is:", propertyDescription)
        //        }

        // Check if the property is of type CFData
        if CFGetTypeID(property) == CFDataGetTypeID(), let data = property as? Data {
            // Attempt to convert the data to a string
            if let serviceTargetProperty = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0")) {
                LogManager.debug("\(serviceTarget): \(String(describing: serviceTargetProperty))", logger: utilsLog)
                return serviceTargetProperty
            }
            return nil
        } else {
            LogManager.error("Failed to check \(serviceTarget) property.", logger: utilsLog)
            return nil
        }
    }

    func getKeyResultFromGestalt(_ keyname: String) -> String {
        let handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW)
        guard handle != nil else {
            return "Unknown"
        }
        defer {
            dlclose(handle)
        }
        
        let symbol = dlsym(handle, "MGGetStringAnswer")
        guard symbol != nil else {
            return "Unknown"
        }
        
        let function = unsafeBitCast(symbol, to: (@convention(c) (String) -> String?).self)
        
        guard let result = function(keyname) else {
            return "Unknown"
        }
        
        return result
    }

    func getPatchOSVersion() -> Int {
        let PatchOSVersion = ProcessInfo().operatingSystemVersion.patchVersion
        LogManager.info("Patch OS Version: \(PatchOSVersion)", logger: utilsLog)
        return PatchOSVersion
    }

    private func getPropertyFromPlatformExpert(key: String) -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }

        guard platformExpert > 0,
              let property = IORegistryEntryCreateCFProperty(platformExpert, key as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String else {
            return nil
        }
        return property.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getSerialNumber() -> String {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return "C00000000000"
        }
        return getPropertyFromPlatformExpert(key: String(kIOPlatformSerialNumberKey)) ?? ""
    }

    func getSysctlValue(for key: String) -> String? {
        var size: size_t = 0
        sysctlbyname(key, nil, &size, nil, 0)
        var value = [CChar](repeating: 0, count: size)
        sysctlbyname(key, &value, &size, nil, 0)
        return String(cString: value)
    }

    func getSystemConsoleUsername() -> String {
        var uid: uid_t = 0
        var gid: gid_t = 0
        let username = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
        LogManager.debug("System console username: \(username)", logger: utilsLog)
        return username
    }
}

struct ImageManager {
    private func createErrorImage() -> NSImage {
        let errorImageConfig = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)
        return NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)?.withSymbolConfiguration(errorImageConfig) ?? NSImage()
    }

    func createImageBase64(base64String: String) -> NSImage {
        let base64Prefix = "data:image/png;base64,"
        let cleanBase64String = base64String.hasPrefix(base64Prefix) ? String(base64String.dropFirst(base64Prefix.count)) : base64String

        guard let imageData = Data(base64Encoded: cleanBase64String, options: .ignoreUnknownCharacters) else {
            LogManager.error("Failed to decode base64 string to data", logger: uiLog)
            return createErrorImage()
        }

        guard let image = NSImage(data: imageData) else {
            LogManager.error("Failed to create image from decoded data", logger: uiLog)
            return createErrorImage()
        }

        return image
    }

    func createImageData(fileImagePath: String) -> NSImage {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: fileImagePath)) else {
            LogManager.error("Error accessing file \(fileImagePath). Incorrect permissions", logger: uiLog)
            return createErrorImage()
        }
        return NSImage(data: imageData) ?? createErrorImage()
    }

    func getCompanyLogoPath(colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? UserInterfaceVariables.iconDarkPath : UserInterfaceVariables.iconLightPath
    }

    func getCorrectImage(path: String, type: String) -> NSImage {
        if path.starts(with: "data:") {
            return createImageBase64(base64String: path)
        } else if FileManager.default.fileExists(atPath: path) {
            return createImageData(fileImagePath: path)
        } else {
            return type == "ScreenShot" ? NSImage(named: "CompanyScreenshotIcon") ?? NSImage() : NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil) ?? NSImage()
        }
    }

    func getScreenShotPath(colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? UserInterfaceVariables.screenShotDarkPath : UserInterfaceVariables.screenShotLightPath
    }
}

struct LoggerUtilities {
    func logRequiredMinimumOSVersion() {
        if !requiredMinimumOSVersionNil() {
            Globals.nudgeDefaults.set(nudgePrimaryState.requiredMinimumOSVersion, forKey: "requiredMinimumOSVersion")
        }
    }

    func logUserDeferrals(resetCount: Bool = false) {
        if !requiredMinimumOSVersionNil() {
            updateDeferralCount(&nudgePrimaryState.userDeferrals, resetCount: resetCount, key: "userDeferrals")
        }
    }

    func logUserQuitDeferrals(resetCount: Bool = false) {
        if !requiredMinimumOSVersionNil() {
            updateDeferralCount(&nudgePrimaryState.userQuitDeferrals, resetCount: resetCount, key: "userQuitDeferrals")
        }
    }

    func logUserSessionDeferrals(resetCount: Bool = false) {
        if !requiredMinimumOSVersionNil() {
            updateDeferralCount(&nudgePrimaryState.userSessionDeferrals, resetCount: resetCount, key: "userSessionDeferrals")
        }
    }

    private func requiredMinimumOSVersionNil() -> Bool {
        return PrefsWrapper.requiredMinimumOSVersion == "0.0"
    }

    func printTimeInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval) / (24 * 3600)
        let hours = (Int(interval) % (24 * 3600)) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        return "\(days) days, \(hours) hours, \(minutes) minutes, \(seconds) seconds"
    }

    private func updateDeferralCount(_ count: inout Int, resetCount: Bool, key: String) {
        if CommandLineUtilities().demoModeEnabled() {
            count = 0
            return
        }
        if resetCount {
            count = 0
        }
        Globals.nudgeDefaults.set(count, forKey: key)
    }

    func userInitiatedDeviceInfo() {
        LogManager.notice("User clicked deviceInfo", logger: uiLog)
    }
}

struct MemoizationManager {
    /// Memoizes a given function to optimize performance by caching its results.
    /// - Parameter function: The function to be memoized.
    /// - Returns: A memoized version of the given function.
    func memoize<Input: Hashable, Output>(_ function: @escaping (Input) -> Output) -> (Input) -> Output {
        var storage = [Input: Output]()
        let lock = NSLock()

        return { input in
            lock.lock()
            defer { lock.unlock() }

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
        let lock = NSLock()
        var memo: ((Input) -> Output)!

        memo = { input in
            lock.lock()
            defer { lock.unlock() }

            if let cached = storage[input] {
                return cached
            }

            let result = function(memo, input)
            storage[input] = result
            return result
        }
        return memo
    }
}

struct NetworkFileManager {
    private func decodeNudgePreferences(from url: URL) -> NudgePreferences? {
        guard let data = try? Data(contentsOf: url) else {
            if Globals.configProfile.isEmpty {
                LogManager.error("Failed to load data from URL: \(url)", logger: prefsProfileLog)
            }
            return nil
        }

        do {
            return try NudgePreferences(data: data)
        } catch {
            LogManager.error("Decoding error: \(error.localizedDescription)", logger: prefsJSONLog)
            return nil
        }
    }

    func getGDMFAssets() -> GDMFAssetInfo? {
        // Define the URL you want to pin to
        if let url = URL(string: "https://gdmf.apple.com/v2/pmv") {
            // Call the pin method
            // Async Method
            //            GDMFPinnedSSL.shared.pinAsync(url: url) { data, response, error in
            //                if let error = error {
            //                    print("Error: \(error.localizedDescription)")
            //                } else if let data = data {
            //                    do {
            //                        let assetInfo = try GDMFAssetInfo(data: data)
            //                        return assetInfo
            //                    } catch {
            //                        print("Failed to decode JSON: \(error.localizedDescription)")
            //                    }
            //                } else {
            //                    print("Unknown error")
            //                }
            //            }
            // Sync Method
            let gdmfData = GDMFPinnedSSL.shared.pinSync(url: url)
            if (gdmfData.error == nil) {
                do {
                    let assetInfo = try GDMFAssetInfo(data: gdmfData.data!)
                    return assetInfo
                } catch {
                    LogManager.error("Failed to decode gdmf JSON: \(error.localizedDescription)", logger: utilsLog)
                }
            } else {
                LogManager.error("Failed to fetch gdmf JSON: \(gdmfData.error!.localizedDescription)", logger: utilsLog)
            }
        } else {
            LogManager.error("Failed to decode gdmf JSON URL string", logger: utilsLog)
        }
        return nil
    }

    func getSOFAAssets() -> MacOSDataFeed? {
        if !OptionalFeatureVariables.utilizeSOFAFeed {
            return nil
        }
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent(Globals.bundleID)
        let sofaFile = "sofa-macos_data_feed.json"
        let sofaPath = appDirectory.appendingPathComponent(sofaFile)
        var sofaJSONExists = fileManager.fileExists(atPath: sofaPath.path)

        // Force delete if bad
        if sofaJSONExists {
            if isFileEmpty(atPath: sofaPath.path) {
                do {
                    try fileManager.removeItem(atPath: sofaPath.path)
                    sofaJSONExists = false
                } catch {
                    LogManager.error("Error deleting file: \(error.localizedDescription)", logger: sofaLog)
                }
            }
        }

        if sofaJSONExists {
            let sofaPathCreationDate = AppStateManager().getModifiedDateForPath(sofaPath.path, testFileDate: nil)
            // Use Cache as it is within time interval
            if TimeInterval(OptionalFeatureVariables.refreshSOFAFeedTime) >= Date().timeIntervalSince(sofaPathCreationDate!) {
                LogManager.info("Utilizing previously cached SOFA json", logger: sofaLog)
                do {
                    let sofaData = try Data(contentsOf: sofaPath)
                    let assetInfo = try MacOSDataFeed(data: sofaData)
                    return assetInfo
                } catch {
                    LogManager.error("Failed to decode previously cached local sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                    LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                    // Attempt to redownload and reprocess the file
                    return redownloadAndReprocessSOFA(url: URL(string: OptionalFeatureVariables.customSOFAFeedURL)!)
                }
            } else {
                LogManager.info("Previously cached SOFA json has expired", logger: sofaLog)
            }
        } else {
            // Ensure the Application Support directory exists
            if !fileManager.fileExists(atPath: appDirectory.path) {
                do {
                    try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    LogManager.error("Failed to create Nudge's Application Support directory: \(error.localizedDescription)", logger: utilsLog)
                }
            }
        }

        if let url = URL(string: OptionalFeatureVariables.customSOFAFeedURL) {
            let sofaData = SOFA().URLSync(url: url)
            if let responseCode = sofaData.responseCode {
                if responseCode == 304 && sofaJSONExists {
                    LogManager.info("Utilizing previously cached SOFA json due to Etag not changing", logger: sofaLog)
                    do {
                        let sofaData = try Data(contentsOf: sofaPath)
                        let assetInfo = try MacOSDataFeed(data: sofaData)
                        return assetInfo
                    } catch {
                        LogManager.error("Failed to decode previously cached (Etag) local sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                        LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                        // Attempt to redownload and reprocess the file
                        return redownloadAndReprocessSOFA(url: url)
                    }
                } else {
                    do {
                        if let data = sofaData.data {
                            if fileManager.fileExists(atPath: appDirectory.path) {
                                try data.write(to: sofaPath)
                            }
                            let assetInfo = try MacOSDataFeed(data: data)
                            Globals.nudgeDefaults.set(sofaData.eTag, forKey: "LastEtag")
                            return assetInfo
                        } else {
                            LogManager.error("Failed to fetch sofa JSON: No data received.", logger: sofaLog)
                            return redownloadAndReprocessSOFA(url: url)
                        }
                    } catch {
                        do {
                            try fileManager.removeItem(atPath: sofaPath.path)
                            sofaJSONExists = false
                        } catch {
                            LogManager.error("Error deleting file: \(error.localizedDescription)", logger: sofaLog)
                        }
                        LogManager.error("Failed to decode sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                        LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                        // Attempt to redownload and reprocess the file
                        return redownloadAndReprocessSOFA(url: url)
                    }
                }
            } else {
                if sofaData.responseCode == nil {
                    LogManager.error("Failed to fetch sofa JSON: Device likely has no network connectivity.", logger: sofaLog)
                } else {
                    LogManager.error("Failed to fetch sofa JSON: \(sofaData.error!.localizedDescription)", logger: sofaLog)
                }
            }
        } else {
            LogManager.error("Failed to decode sofa JSON URL string", logger: sofaLog)
        }
        return nil
    }

    func getBackupMajorUpgradeAppPath() -> String {
        switch VersionManager.getMajorRequiredNudgeOSVersion() {
            case 12:
                return "/Applications/Install macOS Monterey.app"
            case 13:
                return "/Applications/Install macOS Ventura.app"
            case 14:
                return "/Applications/Install macOS Sonoma.app"
            case 15:
                return "/Applications/Install macOS Sequoia.app"
            default:
                return "/System/Library/CoreServices/Software Update.app"
        }
    }

    func getJSONUrl() -> String {
        Globals.nudgeDefaults.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
    }

    func getNudgeJSONPreferences() -> NudgePreferences? {
        let url = getJSONUrl()

        if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
            return nil
        }

        if CommandLineUtilities().bundleModeJSONEnabled(), let bundleUrl = Globals.bundle.url(forResource: "com.github.macadmins.Nudge.tester", withExtension: "json") {
            LogManager.debug("JSON url: \(bundleUrl)", logger: utilsLog)
            return decodeNudgePreferences(from: bundleUrl)
        }

        if CommandLineUtilities().bundleModeProfileEnabled(), let bundleUrl = Globals.bundle.url(forResource: "com.github.macadmins.Nudge.tester", withExtension: "plist") {
            LogManager.debug("Using embedded plist url: \(bundleUrl)", logger: utilsLog)
            return nil
        }

        if let jsonUrl = URL(string: url) {
            LogManager.debug("JSON url: \(url)", logger: utilsLog)
            return decodeNudgePreferences(from: jsonUrl)
        }

        LogManager.error("Could not find or decode JSON configuration", logger: prefsJSONLog)
        return nil
    }

    func isFileEmpty(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? NSNumber {
                return fileSize.intValue == 0
            }
        } catch {
            LogManager.error("Error getting file attributes: \(error.localizedDescription)", logger: prefsJSONLog)
        }
        return false
    }

    func redownloadAndReprocessSOFA(url: URL) -> MacOSDataFeed? {
        let sofaData = SOFA().URLSync(url: url)
        if let responseCode = sofaData.responseCode, responseCode == 200 {
            let fileManager = FileManager.default
            let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportDirectory.appendingPathComponent(Globals.bundleID)
            let sofaFile = "sofa-macos_data_feed.json"
            let sofaPath = appDirectory.appendingPathComponent(sofaFile)

            do {
                if let data = sofaData.data {
                    if fileManager.fileExists(atPath: appDirectory.path) {
                        try data.write(to: sofaPath)
                    }
                    let assetInfo = try MacOSDataFeed(data: data)
                    return assetInfo
                } else {
                    LogManager.error("Failed to fetch sofa JSON: No data received.", logger: sofaLog)
                    return redownloadAndReprocessSOFA(url: url)
                }
            } catch {
                LogManager.error("Failed to decode sofa JSON after redownload: \(error.localizedDescription)", logger: sofaLog)
                LogManager.error("Failed to decode sofa JSON after redownload: \(error)", logger: sofaLog)
            }
        } else {
            if sofaData.responseCode == nil {
                LogManager.error("Failed to fetch sofa JSON: Device likely has no network connectivity.", logger: sofaLog)
            } else {
                LogManager.error("Failed to fetch sofa JSON: \(sofaData.error?.localizedDescription ?? "Unknown error")", logger: sofaLog)
            }
        }
        return nil
    }
}

struct SubProcessUtilities {
    func runProcess(launchPath: String, arguments: [String]) -> (output: String, error: String, exitCode: Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            return ("", "Error running process", -1)
        }

        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)

        return (output, error, task.terminationStatus)
    }
}

struct SMAppManager {
    private func handleLegacyLaunchAgent(passedThroughCLI: Bool, action: String) {
        logOrPrint("Legacy Nudge LaunchAgent currently loaded. Please disable this agent before attempting to \(action) modern agent.", passedThroughCLI: passedThroughCLI, exitCode: 1)
    }

    @available(macOS 13.0, *)
    func loadSMAppLaunchAgent(appService: SMAppService, appServiceStatus: SMAppService.Status) {
        let url = URL(fileURLWithPath: "/Library/LaunchAgents/\(UserExperienceVariables.launchAgentIdentifier).plist")
        let legacyStatus = SMAppService.statusForLegacyPlist(at: url)
        let passedThroughCLI = CommandLineUtilities().registerSMAppArgumentPassed()

        if legacyStatus == .enabled {
            handleLegacyLaunchAgent(passedThroughCLI: passedThroughCLI, action: "register")
            return
        }

        switch appServiceStatus {
            case .enabled:
                logOrPrint("Nudge LaunchAgent is currently registered and enabled", passedThroughCLI: passedThroughCLI, exitCode: 0)
            default:
                registerOrUnregister(appService: appService, passedThroughCLI: passedThroughCLI, action: "register")
        }
    }

    private func logOrPrint(_ message: String, passedThroughCLI: Bool, exitCode: Int? = nil) {
        if passedThroughCLI {
            print(message)
            if let code = exitCode { exit(Int32(code)) }
        } else {
            LogManager.info("\(message)", logger: uiLog)
        }
    }

    @available(macOS 13.0, *)
    private func registerOrUnregister(appService: SMAppService, passedThroughCLI: Bool, action: String) {
        do {
            logOrPrint("\(action.capitalized)ing Nudge LaunchAgent", passedThroughCLI: passedThroughCLI)
            try action == "register" ? appService.register() : appService.unregister()
            logOrPrint("Successfully \(action)ed Nudge LaunchAgent", passedThroughCLI: passedThroughCLI, exitCode: 0)
        } catch {
            logOrPrint("Failed to \(action) Nudge LaunchAgent", passedThroughCLI: passedThroughCLI, exitCode: 1)
        }
    }

    @available(macOS 13.0, *)
    func unloadSMAppLaunchAgent(appService: SMAppService, appServiceStatus: SMAppService.Status) {
        let passedThroughCLI = CommandLineUtilities().unregisterSMAppArgumentPassed()

        switch appServiceStatus {
            case .notFound, .notRegistered:
                logOrPrint("Nudge LaunchAgent has never been registered or is not currently registered", passedThroughCLI: passedThroughCLI, exitCode: 0)
            default:
                registerOrUnregister(appService: appService, passedThroughCLI: passedThroughCLI, action: "unregister")
        }
    }
}

struct UIUtilities {
    func centerNudge() {
        NSApp.windows.first?.center()
    }

    func createCorrectURLType(from input: String) -> URL? {
        // Checks if the input contains "://", a simple heuristic to decide if it's a web URL
        let isWebURL = ["data:", "https://", "http://", "file://"].contains(where: input.starts(with:))

        // Returns a URL initialized appropriately based on the input type
        return isWebURL ? URL(string: input) : URL(fileURLWithPath: input)
    }

    private func determineUpdateURL() -> URL? {
        if let actionButtonPath = FeatureVariables.actionButtonPath {
            if actionButtonPath.isEmpty {
                LogManager.warning("actionButtonPath is set but contains an empty string. Defaulting to /System/Library/CoreServices/Software Update.app.", logger: utilsLog)
                return URL(fileURLWithPath: "/System/Library/CoreServices/Software Update.app")
            }

            // Check if it's a shell command
            if isShellCommand(path: actionButtonPath) {
                return nil
            }

            // Check if the string is a URL with a scheme
            if URL(string: actionButtonPath)?.scheme != nil {
                return URL(string: actionButtonPath)
            } else {
                // It's a file path
                return URL(fileURLWithPath: actionButtonPath)
            }
        }


        if AppStateManager().requireMajorUpgrade() {
            if majorUpgradeAppPathExists {
                return URL(fileURLWithPath: OSVersionRequirementVariables.majorUpgradeAppPath)
            } else if majorUpgradeBackupAppPathExists {
                return URL(fileURLWithPath: NetworkFileManager().getBackupMajorUpgradeAppPath())
            }
        }

        LogManager.warning("Defaulting actionButtonPath to /System/Library/CoreServices/Software Update.app.", logger: utilsLog)
        return URL(fileURLWithPath: "/System/Library/CoreServices/Software Update.app")
    }

    func executeShellCommand(command: String, userClicked: Bool) {
        let cmds = command.components(separatedBy: " ")
        guard let launchPath = cmds.first, let argument = cmds.last else {
            LogManager.error("Invalid shell command format", logger: uiLog)
            return
        }

        let task = Process()
        task.launchPath = launchPath
        task.arguments = [argument]

        if userClicked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    try task.run()
                } catch {
                    LogManager.error("Error running script: \(error.localizedDescription)", logger: uiLog)
                }
            }
        } else {
            do {
                try task.run()
            } catch {
                LogManager.error("Error running script: \(error.localizedDescription)", logger: uiLog)
            }
        }
    }

    private func isShellCommand(path: String) -> Bool {
        let shellCommands = ["/bin/bash", "/bin/sh", "/bin/zsh"]
        return shellCommands.contains(where: path.hasPrefix)
    }

    func openMoreInfo() {
        guard let url = URL(string: OSVersionRequirementVariables.aboutUpdateURL) else {
            return
        }
        LogManager.notice("User clicked moreInfo button", logger: uiLog)
        NSWorkspace.shared.open(url)
    }

    func openMoreInfoUnsupported() {
        guard let url = URL(string: OSVersionRequirementVariables.unsupportedURL) else {
            return
        }
        LogManager.notice("User clicked moreInfo button in unsupported state", logger: uiLog)
        NSWorkspace.shared.open(url)
    }

    func postUpdateDeviceActions(userClicked: Bool, unSupportedUI: Bool) {
        if userClicked {
            LogManager.notice(unSupportedUI ? "User clicked updateDevice (Replace My Device) via Unsupported UI workflow" : "User clicked updateDevice" , logger: uiLog)
            // Remove forced blur and reset window level
            if !nudgePrimaryState.backgroundBlur.isEmpty {
                nudgePrimaryState.backgroundBlur.forEach { blurWindowController in
                    uiLog.notice("\("Attempting to remove forced blur", privacy: .public)")
                    blurWindowController.close()
                    nudgePrimaryState.backgroundBlur.removeAll()
                }
                NSApp.windows.first?.level = .normal
            }
        } else {
            LogManager.notice(unSupportedUI ? "Synthetically clicked updateDevice (Replace My Device) via Unsupported UI workflow due to allowedDeferral count" : "Synthetically clicked updateDevice due to allowedDeferral count" , logger: uiLog)
        }
    }

    func setDeferralTime(deferralTime: Date) {
        guard !CommandLineUtilities().demoModeEnabled() else { return }
        Globals.nudgeDefaults.set(deferralTime, forKey: "deferRunUntil")
    }

    func showEasterEgg() -> Bool {
        let components = Calendar.current.dateComponents([.day, .month], from: DateManager().getCurrentDate())
        return components.month == 8 && components.day == 6
    }

    func updateDevice(userClicked: Bool = true) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        if let url = determineUpdateURL() {
            let openAction = {
                if url.isFileURL {
                    NSWorkspace.shared.openApplication(at: url, configuration: configuration)
                } else {
                    NSWorkspace.shared.open(url)
                }
            }

            // Execute the action immediately or with a delay based on user interaction
            if userClicked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: openAction)
            } else {
                openAction()
            }
        } else {
            if let actionButtonPath = FeatureVariables.actionButtonPath {
                executeShellCommand(command: actionButtonPath, userClicked: userClicked)
            } else {
                LogManager.error("actionButtonPath is nil.", logger: uiLog)
            }
        }

        postUpdateDeviceActions(userClicked: userClicked, unSupportedUI: false)
    }

    func userInitiatedExit() {
        LogManager.notice("User clicked primaryQuitButton", logger: uiLog)
        nudgePrimaryState.shouldExit = true
        exit(0)
    }
}

struct VersionManager {
    static func fullyUpdated() -> Bool {
        let currentOSVersion = GlobalVariables.currentOSVersion
        let requiredMinimumOSVersion = nudgePrimaryState.requiredMinimumOSVersion
        let fullyUpdated = versionGreaterThanOrEqual(currentVersion: currentOSVersion, newVersion: requiredMinimumOSVersion)
        if fullyUpdated {
            LogManager.notice("Current operating system (\(currentOSVersion)) is greater than or equal to required operating system (\(requiredMinimumOSVersion))", logger: utilsLog)
            return true
        }
        return false
    }

    static func getMajorOSVersion() -> Int {
        var majorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        if (CommandLineUtilities().simulateOSVersion() != nil) {
            majorOSVersion = Int(CommandLineUtilities().simulateOSVersion()!.split(separator: ".").first.map(String.init)!)!
        }
        logOSVersion(majorOSVersion, for: "OS Version")
        return majorOSVersion
    }

    static func getMajorRequiredNudgeOSVersion() -> Int {
        let requiredVersion = nudgePrimaryState.requiredMinimumOSVersion

        // Handle new string values directly
        switch requiredVersion {
        case "latest", "latest-minor", "latest-supported":
            return 0
        default:
            break
        }

        // Existing logic for version numbers
        guard let majorVersion = Int(requiredVersion.split(separator: ".").first ?? "") else {
            LogManager.error("Invalid format for requiredMinimumOSVersion - value is \(requiredVersion)", logger: utilsLog)
            return 0
        }
        logOSVersion(majorVersion, for: "Major required OS version")
        return majorVersion
    }

    static func getMajorVersion(from version: String) -> Int {
        return Int(version.split(separator: ".").first.map(String.init)!)!
    }

    static func getMinorOSVersion() -> Int {
        var minorOSVersion = ProcessInfo().operatingSystemVersion.minorVersion
//        if (CommandLineUtilities().simulateOSVersion() != nil) {
//            let components = CommandLineUtilities().simulateOSVersion()!.split(separator: ".")
//            if components.count > 1 {
//                minorOSVersion = components.dropFirst().joined(separator: ".") // THIS WONT BE AN INT
//            }
//        }
        logOSVersion(minorOSVersion, for: "Minor OS Version")
        return minorOSVersion
    }

    static func getNudgeVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    private static func logOSVersion(_ version: Int, for description: String) {
        LogManager.info("\(description): \(version)", logger: utilsLog)
    }

    static func newNudgeEvent() -> Bool {
        versionGreaterThan(currentVersion: nudgePrimaryState.requiredMinimumOSVersion, newVersion: nudgePrimaryState.userRequiredMinimumOSVersion)
    }

    // Helper function to remove duplicates while preserving order
    func removeDuplicates(from array: [String]) -> [String] {
        var seen = Set<String>()
        return array.filter { seen.insert($0).inserted }
    }

    // Adapted from https://stackoverflow.com/a/25453654
    static func versionEqual(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedSame
    }

    static func versionGreaterThan(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedDescending
    }

    static func versionGreaterThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) != .orderedAscending
    }

    static func versionLessThan(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedAscending
    }

    static func versionLessThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) != .orderedDescending
    }
}

var cameras: [CameraManager] {
    var innerArray: [CameraManager] = []
    var opa = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))

    var dataSize: UInt32 = 0
    var dataUsed: UInt32 = 0
    var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize)
    guard result == kCMIOHardwareNoError, let devices = malloc(Int(dataSize)) else { return [] }

    result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, devices)
    guard result == kCMIOHardwareNoError else {
        free(devices)
        return []
    }

    for offset in stride(from: 0, to: Int(dataSize), by: MemoryLayout<CMIOObjectID>.size) {
        let current = devices.advanced(by: offset).assumingMemoryBound(to: CMIOObjectID.self)
        innerArray.append(CameraManager(id: current.pointee))
    }

    free(devices)
    return innerArray
}
