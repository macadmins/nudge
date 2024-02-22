//
//  Utils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import CoreMediaIO
import Foundation
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

    private func getCreationDateForPath(_ path: String, testFileDate: Date?) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        let creationDate = attributes?[.creationDate] as? Date
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
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))

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
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))

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

    func bundleModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-bundle-mode")
        if argumentPassed && !nudgeLogState.hasLoggedBundleMode {
            LogManager.debug("-bundle-mode argument passed", logger: uiLog)
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
        nudgeProfileConfig["optionalFeatures"] = Globals.nudgeDefaults.dictionary(forKey: "optionalFeatures")
        nudgeProfileConfig["osVersionRequirements"] = Globals.nudgeDefaults.array(forKey: "osVersionRequirements")
        nudgeProfileConfig["userExperience"] = Globals.nudgeDefaults.dictionary(forKey: "userExperience")
        nudgeProfileConfig["userInterface"] = Globals.nudgeDefaults.dictionary(forKey: "userInterface")

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

    func getCPUTypeString() -> String {
        // https://stackoverflow.com/a/63539782
        let type = getCPUTypeInt()
        guard type != -1 else {
            return "error in CPU type"
        }

        let cpuArch = type & 0xff // Mask for architecture bits

        switch cpuArch {
            case Int(CPU_TYPE_X86) /* Intel */:
                LogManager.debug("CPU Type is Intel", logger: utilsLog)
                return "Intel"
            case Int(CPU_TYPE_ARM) /* Apple Silicon */:
                LogManager.debug("CPU Type is Apple Silicon", logger: utilsLog)
                return "Apple Silicon"
            default:
                LogManager.debug("Unknown CPU Type", logger: utilsLog)
                return "unknown"
        }
    }

    func getHardwareUUID() -> String {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return "DC3F0981-D881-408F-BED7-8D6F1DEE8176"
        }
        return getPropertyFromPlatformExpert(key: String(kIOPlatformUUIDKey)) ?? ""
    }

    func getPatchOSVersion() -> Int {
        let PatchOSVersion = ProcessInfo().operatingSystemVersion.patchVersion
        LogManager.info("Patch OS Version: \(PatchOSVersion)", logger: utilsLog)
        return PatchOSVersion
    }

    private func getPropertyFromPlatformExpert(key: String) -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
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
        Globals.nudgeDefaults.set(OSVersionRequirementVariables.requiredMinimumOSVersion, forKey: "requiredMinimumOSVersion")
    }

    func logUserDeferrals(resetCount: Bool = false) {
        updateDeferralCount(&nudgePrimaryState.userDeferrals, resetCount: resetCount, key: "userDeferrals")
    }

    func logUserQuitDeferrals(resetCount: Bool = false) {
        updateDeferralCount(&nudgePrimaryState.userQuitDeferrals, resetCount: resetCount, key: "userQuitDeferrals")
    }

    func logUserSessionDeferrals(resetCount: Bool = false) {
        updateDeferralCount(&nudgePrimaryState.userSessionDeferrals, resetCount: resetCount, key: "userSessionDeferrals")
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
                LogManager.error("Failed to load data from URL: \(url)", logger: prefsJSONLog)
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

    func getBackupMajorUpgradeAppPath() -> String {
        switch VersionManager.getMajorRequiredNudgeOSVersion() {
            case 12:
                return "/Applications/Install macOS Monterey.app"
            case 13:
                return "/Applications/Install macOS Ventura.app"
            case 14:
                return "/Applications/Install macOS Sonoma.app"
            default:
                return "/Applications/Install macOS Monterey.app"
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

        if CommandLineUtilities().bundleModeEnabled(), let bundleUrl = Globals.bundle.url(forResource: "com.github.macadmins.Nudge.tester", withExtension: "json") {
            LogManager.debug("JSON url: \(bundleUrl)", logger: utilsLog)
            return decodeNudgePreferences(from: bundleUrl)
        }

        if let jsonUrl = URL(string: url) {
            LogManager.debug("JSON url: \(url)", logger: utilsLog)
            return decodeNudgePreferences(from: jsonUrl)
        }

        LogManager.error("Could not find or decode JSON configuration", logger: prefsJSONLog)
        return nil
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

    private func determineUpdateURL() -> URL? {
        if let actionButtonPath = FeatureVariables.actionButtonPath {
            if actionButtonPath.isEmpty {
                LogManager.warning("actionButtonPath is set but contains an empty string. Defaulting to out of box behavior.", logger: utilsLog)
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
        let requiredMinimumOSVersion = OSVersionRequirementVariables.requiredMinimumOSVersion
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
        guard let majorVersion = Int(OSVersionRequirementVariables.requiredMinimumOSVersion.split(separator: ".").first ?? "") else {
            LogManager.error("Invalid format for requiredMinimumOSVersion", logger: utilsLog)
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
        versionGreaterThan(currentVersion: OSVersionRequirementVariables.requiredMinimumOSVersion, newVersion: nudgePrimaryState.userRequiredMinimumOSVersion)
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
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))

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
