//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import CoreMediaIO
import Foundation
import IOKit
#if canImport(ServiceManagement)
import ServiceManagement
#endif
import SwiftUI
import SystemConfiguration

struct AppStateManager {
    func activateNudge() {
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
        let gracePeriodPathCreationTimeInHours = Int(currentDate.timeIntervalSince(gracePeriodPathCreationDate) / 3600)
        let combinedGracePeriod = UserExperienceVariables.gracePeriodInstallDelay + UserExperienceVariables.gracePeriodLaunchDelay

        if currentDate > PrefsWrapper.requiredInstallationDate || combinedGracePeriod > DateManager().getNumberOfHoursRemaining(currentDate: currentDate) {
            if UserExperienceVariables.gracePeriodLaunchDelay > gracePeriodPathCreationTimeInHours {
                LogManager.info("Device within gracePeriodLaunchDelay, exiting Nudge", logger: uiLog)
                nudgePrimaryState.shouldExit = true
                return currentDate
            } else {
                LogManager.info("gracePeriodPath (\(UserExperienceVariables.gracePeriodPath)) outside of gracePeriodLaunchDelay (\(UserExperienceVariables.gracePeriodLaunchDelay)) - File age is \(gracePeriodPathCreationTimeInHours) hours", logger: uiLog)
            }

            if UserExperienceVariables.gracePeriodInstallDelay > gracePeriodPathCreationTimeInHours {
                requiredInstallationDate = gracePeriodPathCreationDate.addingTimeInterval(Double(combinedGracePeriod) * 3600)
                LogManager.notice("Device permitted for gracePeriods - setting date to: \(requiredInstallationDate)", logger: uiLog)
                return requiredInstallationDate
            }
        }

        return PrefsWrapper.requiredInstallationDate
    }


    func exitNudge() {
        LogManager.notice("Nudge is terminating due to condition met", logger: uiLog)
        nudgePrimaryState.shouldExit = true
        exit(0)
    }

    func getCreationDateForPath(_ path: String, testFileDate: Date?) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        if attributes?[.size] as? Int == 0  && testFileDate == nil {
            return DateManager().coerceStringToDate(dateString: "2020-08-06T00:00:00Z")
        }
        let creationDate = attributes?[.creationDate] as? Date
        return testFileDate ?? creationDate
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

    func gracePeriodLogic(currentDate: Date = DateManager().getCurrentDate(), testFileDate: Date? = nil) -> Date {
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

        return calculateNewRequiredInstallationDateIfNeeded(currentDate: currentDate, gracePeriodPathCreationDate: gracePeriodPathCreationDate)
    }

    func sofaPeriodLogic(currentDate: Date = DateManager().getCurrentDate(), testFileDate: Date? = nil) -> Date {
        if OptionalFeatureVariables.utilizeSOFAFeed {
            if releaseDate.addingTimeInterval(TimeInterval(UserExperienceVariables.sofaPeriodLaunchDelay * 86400)) > currentDate {
                LogManager.info("Device within sofaPeriodLaunchDelay, exiting Nudge", logger: uiLog)
                nudgePrimaryState.shouldExit = true
                return currentDate
            } else {
                LogManager.info("Device outside sofaPeriodLaunchDelay", logger: uiLog)
                return PrefsWrapper.requiredInstallationDate
            }
        }
        return PrefsWrapper.requiredInstallationDate
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

struct CommandLineUtilities {
    let arguments = Set(CommandLine.arguments)

    func bundleModeJSONEnabled() -> Bool {
        let argumentPassed = arguments.contains("-bundle-mode-json")
        if argumentPassed && !nudgeLogState.hasLoggedBundleMode {
            LogManager.debug("-bundle-mode-json argument passed", logger: uiLog)
            nudgeLogState.hasLoggedBundleMode = true
        }
        return argumentPassed
    }

    func bundleModeProfileEnabled() -> Bool {
        let argumentPassed = arguments.contains("-bundle-mode-profile")
        if argumentPassed && !nudgeLogState.hasLoggedBundleMode {
            LogManager.debug("-bundle-mode-profile argument passed", logger: uiLog)
            nudgeLogState.hasLoggedBundleMode = true
        }
        return argumentPassed
    }

    func debugUIModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-debug-ui-mode")
        if argumentPassed && !nudgeLogState.afterFirstRun {
            LogManager.debug("-debug-ui-mode argument passed", logger: uiLog)
        }
        return argumentPassed
    }

    func demoModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-demo-mode")
        if argumentPassed && !nudgeLogState.hasLoggedDemoMode {
            nudgeLogState.hasLoggedDemoMode = true
            LogManager.debug("-demo-mode argument passed", logger: uiLog)
        }
        return argumentPassed
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-force-screenshot-icon")
        if argumentPassed && !nudgeLogState.hasLoggedScreenshotIconMode {
            nudgeLogState.hasLoggedScreenshotIconMode = true
            LogManager.debug("-force-screenshot-icon argument passed", logger: uiLog)
        }
        return argumentPassed
    }

    func registerSMAppArgumentPassed() -> Bool {
        arguments.contains("--register")
    }

    func simpleModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-simple-mode")
        if argumentPassed && !nudgeLogState.hasLoggedSimpleMode {
            nudgeLogState.hasLoggedSimpleMode = true
            LogManager.debug("-simple-mode argument passed", logger: uiLog)
        }
        return argumentPassed
    }

    func unitTestingEnabled() -> Bool {
        let argumentPassed = arguments.contains("-unit-testing")
        if !nudgeLogState.hasLoggedUnitTestingMode {
            if argumentPassed {
                nudgeLogState.hasLoggedUnitTestingMode = true
                LogManager.debug("-unit-testing argument passed", logger: uiLog)
            }
        }
        return argumentPassed
    }

    func unregisterSMAppArgumentPassed() -> Bool {
        arguments.contains("--unregister")
    }

    func versionArgumentPassed() -> Bool {
        let argumentPassed = arguments.contains("-version")
        if argumentPassed {
            LogManager.debug("-version argument passed", logger: uiLog)
        }
        return argumentPassed
    }
}

struct ConfigurationManager {
    private func determineTimerCycle(basedOn hoursRemaining: Int) -> Int {
        switch hoursRemaining {
            case ...0:
                return UserExperienceVariables.elapsedRefreshCycle
            case ...UserExperienceVariables.imminentWindowTime:
                return UserExperienceVariables.imminentRefreshCycle
            case ...UserExperienceVariables.approachingWindowTime:
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
        let hoursRemaining = DateManager().getNumberOfHoursRemaining()
        let timerCycle = determineTimerCycle(basedOn: hoursRemaining)

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

    private let dateFormatterCurrent: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()

    func coerceStringToDate(dateString: String) -> Date {
        dateFormatterISO8601.date(from: dateString) ?? getCurrentDate()
    }

    func getCurrentDate() -> Date {
        switch Calendar.current.identifier {
            case .buddhist, .japanese, .gregorian, .coptic, .ethiopicAmeteMihret, .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura, .persian:
                return dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
            default:
                return Date()
        }
    }

    func getFormattedDate(date: Date? = nil) -> Date {
        let initialDate = dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: date ?? Date())) ?? Date()
        switch Calendar.current.identifier {
            case .gregorian, .buddhist, .iso8601, .japanese:
                return initialDate
            default:
                return dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: initialDate)) ?? Date()
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

    func getHardwareModelID() -> String {
        var hardwareModelID = ""
        if DeviceManager().getCPUTypeString() == "Apple Silicon" {
            // There is no local bridge
            hardwareModelID = getIORegInfo(serviceTarget: "target-sub-type") ?? "Unknown"
        } else {
            // Attempt localbridge for T2, if it fails, it's likely a T1 or lower
            let bridgeID = getBridgeModelID()
            let boardID = getIORegInfo(serviceTarget: "board-id")
            if bridgeID.isEmpty {
                // Fallback to boardID for T1
                hardwareModelID = boardID ?? "Unknown"
            } else {
                // T2 uses bridge ID for it's update brain via gdmf
                hardwareModelID = bridgeID
            }
        }
        LogManager.debug("Hardware Model ID: \(hardwareModelID)", logger: utilsLog)
        return hardwareModelID.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let sofaJSONExists = fileManager.fileExists(atPath: sofaPath.path)
        if sofaJSONExists {
            let sofaPathCreationDate = AppStateManager().getModifiedDateForPath(sofaPath.path, testFileDate: nil)
            // Use Cache as it is within time inverval
            if TimeInterval(OptionalFeatureVariables.refreshSOFAFeedTime) >= Date().timeIntervalSince(sofaPathCreationDate!) {
                LogManager.info("Utilizing previously cached SOFA json", logger: sofaLog)
                do {
                    let sofaData = try Data(contentsOf: sofaPath)
                    let assetInfo = try MacOSDataFeed(data: sofaData)
                    return assetInfo
                } catch {
                    LogManager.error("Failed to decode local sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                    LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                    return nil
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
            if (sofaData.error == nil) {
                if sofaData.responseCode == 304 && sofaJSONExists {
                    LogManager.info("Utilizing previously cached SOFA json due to Etag not changing", logger: sofaLog)
                    do {
                        let sofaData = try Data(contentsOf: sofaPath)
                        let assetInfo = try MacOSDataFeed(data: sofaData)
                        return assetInfo
                    } catch {
                        LogManager.error("Failed to decode local sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                        LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                        return nil
                    }
                } else {
                    do {
                        if fileManager.fileExists(atPath: appDirectory.path) {
                            try sofaData.data!.write(to: sofaPath)
                        }
                        let assetInfo = try MacOSDataFeed(data: sofaData.data!)
                        return assetInfo
                    } catch {
                        LogManager.error("Failed to decode sofa JSON: \(error.localizedDescription)", logger: sofaLog)
                        LogManager.error("Failed to decode sofa JSON: \(error)", logger: sofaLog)
                        return nil
                    }
                }
            } else {
                LogManager.error("Failed to fetch sofa JSON: \(sofaData.error!.localizedDescription)", logger: sofaLog)
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

    private func postUpdateDeviceActions(userClicked: Bool) {
        if userClicked {
            LogManager.notice("User clicked updateDevice", logger: uiLog)
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
            LogManager.notice("Synthetically clicked updateDevice due to allowedDeferral count", logger: uiLog)
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

        postUpdateDeviceActions(userClicked: userClicked)
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
        let majorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        logOSVersion(majorOSVersion, for: "OS Version")
        return majorOSVersion
    }

    static func getMajorRequiredNudgeOSVersion() -> Int {
        guard let majorVersion = Int(nudgePrimaryState.requiredMinimumOSVersion.split(separator: ".").first ?? "") else {
            LogManager.error("Invalid format for requiredMinimumOSVersion - value is \(nudgePrimaryState.requiredMinimumOSVersion)", logger: utilsLog)
            return 0
        }
        logOSVersion(majorVersion, for: "Major required OS version")
        return majorVersion
    }

    static func getMinorOSVersion() -> Int {
        let minorOSVersion = ProcessInfo().operatingSystemVersion.minorVersion
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
