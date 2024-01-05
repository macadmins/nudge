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
        utilsLog.info("\("Activating Nudge", privacy: .public)")
        nudgePrimaryState.lastRefreshTime = DateManager().getCurrentDate()
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.

        // load the blur background and send it to the back if we are past the required install date
        if DateManager().pastRequiredInstallationDate() && OptionalFeatureVariables.aggressiveUserFullScreenExperience {
            UIUtilities().centerNudge()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows[0].makeKeyAndOrderFront(self)
            uiLog.info("\("Enabling blurred background", privacy: .public)")
            nudgePrimaryState.backgroundBlur.removeAll()
            for (index, screen) in screens.enumerated() {
                nudgePrimaryState.backgroundBlur.append(BackgroundBlurWindowController())
                loopedScreen = screen
                nudgePrimaryState.backgroundBlur[index].close()
                nudgePrimaryState.backgroundBlur[index].loadWindow()
                nudgePrimaryState.backgroundBlur[index].showWindow(self)
            }
            NSApp.windows[0].level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
            return
        }

        if NSWorkspace.shared.isActiveSpaceFullScreen() && !nudgePrimaryState.afterFirstStateChange {
            uiLog.notice("\("Bypassing activation due to full screen bugs in macOS", privacy: .public)")
            return
        } else {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows[0].makeKeyAndOrderFront(self)
        }
    }

    func allow1HourDeferral() -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        let allow1HourDeferralButton = DateManager().getNumberOfHoursRemaining() > 0
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allow1HourDeferralButton: \(allow1HourDeferralButton, privacy: .public)")
        }
        return allow1HourDeferralButton
    }

    func allow24HourDeferral() -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        let allow24HourDeferralButton = DateManager().getNumberOfHoursRemaining() > UserExperienceVariables.imminentWindowTime
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allow24HourDeferralButton: \(allow24HourDeferralButton, privacy: .public)")
        }
        return allow24HourDeferralButton
    }

    func allowCustomDeferral() -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        let allowCustomDeferralButton = DateManager().getNumberOfHoursRemaining() > UserExperienceVariables.approachingWindowTime
        // TODO: Technically we should also log when this value changes in the middle of a nudge run
        if !nudgeLogState.afterFirstRun {
            uiLog.info("Device allowCustomDeferralButton: \(allowCustomDeferralButton, privacy: .public)")
        }
        return allowCustomDeferralButton
    }

    func exitNudge() {
        uiLog.notice("\("Nudge is terminating due to condition met", privacy: .public)")
        nudgePrimaryState.shouldExit = true
        exit(0)
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

    func gracePeriodLogic(currentDate: Date = DateManager().getCurrentDate(), testFileDate: Date? = nil) -> Date {
        if (UserExperienceVariables.allowGracePeriods || PrefsWrapper.allowGracePeriods) && !CommandLineUtilities().demoModeEnabled() {
            if FileManager.default.fileExists(atPath: UserExperienceVariables.gracePeriodPath) || CommandLineUtilities().unitTestingEnabled() {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: UserExperienceVariables.gracePeriodPath) as [FileAttributeKey: Any],
                   var gracePeriodPathCreationDate = attributes[FileAttributeKey.creationDate] as? Date {
                    if testFileDate != nil {
                        gracePeriodPathCreationDate = testFileDate!
                    }
                    let gracePeriodPathCreationTimeInHours = Int(currentDate.timeIntervalSince(gracePeriodPathCreationDate) / 3600)
                    let combinedGracePeriod = UserExperienceVariables.gracePeriodInstallDelay + UserExperienceVariables.gracePeriodLaunchDelay
                    uiLog.info("\("allowGracePeriods is set to true", privacy: .public)")
                    if (currentDate > PrefsWrapper.requiredInstallationDate) || combinedGracePeriod > DateManager().getNumberOfHoursRemaining(currentDate: currentDate) {
                        // Exit Scenario
                        if UserExperienceVariables.gracePeriodLaunchDelay > gracePeriodPathCreationTimeInHours {
                            uiLog.info("\("Device within gracePeriodLaunchDelay, exiting Nudge", privacy: .public)")
                            nudgePrimaryState.shouldExit = true
                        }

                        // Launch Scenario
                        if UserExperienceVariables.gracePeriodInstallDelay > gracePeriodPathCreationTimeInHours {
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

    func requireDualQuitButtons() -> Bool {
        if CommandLineUtilities().demoModeEnabled() {
            return true
        }
        if UserInterfaceVariables.singleQuitButton {
            uiLog.info("Single quit button configured")
            return false
        }
        let requireDualQuitButtons = (UserExperienceVariables.approachingWindowTime / 24) >= DateManager().getNumberOfDaysBetween()
        if !nudgePrimaryState.hasLoggedRequireDualQuitButtons {
            nudgePrimaryState.hasLoggedRequireDualQuitButtons = true
            uiLog.info("Device requireDualQuitButtons: \(requireDualQuitButtons, privacy: .public)")
        }
        return requireDualQuitButtons
    }

    func requireMajorUpgrade() -> Bool {
        let requireMajorUpdate = VersionManager().versionGreaterThan(currentVersion: String(VersionManager().getMajorRequiredNudgeOSVersion()), newVersion: String(VersionManager().getMajorOSVersion()))
        if !nudgeLogState.hasLoggedRequireMajorUgprade {
            nudgeLogState.hasLoggedRequireMajorUgprade = true
            utilsLog.info("Device requireMajorUpgrade: \(requireMajorUpdate, privacy: .public)")
        }
        return requireMajorUpdate
    }
}

// https://stackoverflow.com/questions/37470201/how-can-i-tell-if-the-camera-is-in-use-by-another-process
// led me to https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm
// Complete credit to https://github.com/ttimpe/camera-usage-detector-mac/blob/845df180f9d19463e8fd382277e2f61d88ca7d5d/CameraUsage/CameraUsageController.swift
// kCMIODevicePropertyDeviceIsRunningSomewhere is the key here
struct CameraManager {
    var id: CMIOObjectID

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
}

struct CommandLineUtilities {
    let arguments = Set(CommandLine.arguments)

    func bundleModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-bundle-mode")
        if argumentPassed && !nudgeLogState.hasLoggedBundleMode {
            uiLog.debug("\("-bundle-mode argument passed", privacy: .public)")
            nudgeLogState.hasLoggedBundleMode = true
        }
        return argumentPassed
    }

    func debugUIModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-debug-ui-mode")
        if argumentPassed && !nudgeLogState.afterFirstRun {
            uiLog.debug("\("-debug-ui-mode argument passed", privacy: .public)")
        }
        return argumentPassed
    }

    func demoModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-demo-mode")
        if argumentPassed && !nudgeLogState.hasLoggedDemoMode {
            nudgeLogState.hasLoggedDemoMode = true
            uiLog.debug("\("-demo-mode argument passed", privacy: .public)")
        }
        return argumentPassed
    }

    func forceScreenShotIconModeEnabled() -> Bool {
        let argumentPassed = arguments.contains("-force-screenshot-icon")
        if argumentPassed && !nudgeLogState.hasLoggedScreenshotIconMode {
            nudgeLogState.hasLoggedScreenshotIconMode = true
            uiLog.debug("\("-force-screenshot-icon argument passed", privacy: .public)")
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
            uiLog.debug("\("-simple-mode argument passed", privacy: .public)")
        }
        return argumentPassed
    }

    func unitTestingEnabled() -> Bool {
        let argumentPassed = arguments.contains("-unit-testing")
        if !nudgeLogState.hasLoggedUnitTestingMode {
            if argumentPassed {
                nudgeLogState.hasLoggedUnitTestingMode = true
                uiLog.debug("\("-unit-testing argument passed", privacy: .public)")
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
            uiLog.debug("\("-version argument passed", privacy: .public)")
        }
        return argumentPassed
    }
}

struct ConfigurationManager {
    func getConfigurationAsJSON() -> Data {
        guard let nudgeJSONConfig = try? newJSONEncoder().encode(nudgeJSONPreferences),
              let json = try? JSONSerialization.jsonObject(with: nudgeJSONConfig),
              let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            uiLog.error("Failed to serialize JSON configuration")
            return Data()
        }
        return jsonData
    }

    func getConfigurationAsProfile() -> Data {
        var nudgeProfileConfig = [String: Any]()
        nudgeProfileConfig["optionalFeatures"] = nudgeDefaults.dictionary(forKey: "optionalFeatures")
        nudgeProfileConfig["osVersionRequirements"] = nudgeDefaults.array(forKey: "osVersionRequirements")
        nudgeProfileConfig["userExperience"] = nudgeDefaults.dictionary(forKey: "userExperience")
        nudgeProfileConfig["userInterface"] = nudgeDefaults.dictionary(forKey: "userInterface")

        guard !nudgeProfileConfig.isEmpty,
              let plistData = try? PropertyListSerialization.data(fromPropertyList: nudgeProfileConfig, format: .xml, options: 0),
              let xmlPlistData = try? XMLDocument(data: plistData, options: .nodePreserveAll) else {
            uiLog.error("Failed to serialize profile configuration")
            return Data()
        }

        return xmlPlistData.xmlData(options: .nodePrettyPrint)
    }

    func getTimerController() -> Int {
        let hoursRemaining = DateManager().getNumberOfHoursRemaining()
        let timerCycle = determineTimerCycle(basedOn: hoursRemaining)

        if timerCycle != nudgePrimaryState.timerCycle {
            uiLog.info("timerCycle: \(timerCycle, privacy: .public)")
            nudgePrimaryState.timerCycle = timerCycle
        }
        return timerCycle
    }

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
}

struct DateManager {
    private let dateFormatterISO8601: DateFormatter = {
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

    func getFormattedDate(date: Date? = nil) -> Date {
        let initialDate = dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: date ?? Date())) ?? Date()
        switch Calendar.current.identifier {
            case .gregorian, .buddhist, .iso8601, .japanese:
                return initialDate
            default:
                return dateFormatterCurrent.date(from: dateFormatterISO8601.string(from: initialDate)) ?? Date()
        }
    }

    func getCurrentDate() -> Date {
        switch Calendar.current.identifier {
            case .buddhist, .japanese, .gregorian, .coptic, .ethiopicAmeteMihret, .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura, .persian:
                return dateFormatterISO8601.date(from: dateFormatterISO8601.string(from: Date())) ?? Date()
            default:
                return Date()
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
            utilsLog.notice("Device pastRequiredInstallationDate: \(isPast, privacy: .public)")
        }
        return isPast
    }
}

struct DeviceManager {
    // https://stackoverflow.com/a/63539782
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

    func getHardwareUUID() -> String {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return "DC3F0981-D881-408F-BED7-8D6F1DEE8176"
        }
        return getPropertyFromPlatformExpert(key: String(kIOPlatformUUIDKey)) ?? ""
    }

    func getPatchOSVersion() -> Int {
        let PatchOSVersion = ProcessInfo().operatingSystemVersion.patchVersion
        utilsLog.info("Patch OS Version: \(PatchOSVersion, privacy: .public)")
        return PatchOSVersion
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
        utilsLog.debug("System console username: \(username)")
        return username
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
}

struct ImageManager {
    func createImageBase64(base64String: String) -> NSImage {
        let base64Prefix = "data:image/png;base64,"
        let cleanBase64String = base64String.hasPrefix(base64Prefix) ? String(base64String.dropFirst(base64Prefix.count)) : base64String

        guard let imageData = Data(base64Encoded: cleanBase64String, options: .ignoreUnknownCharacters) else {
            uiLog.error("Failed to decode base64 string to data")
            return createErrorImage()
        }

        guard let image = NSImage(data: imageData) else {
            uiLog.error("Failed to create image from decoded data")
            return createErrorImage()
        }

        return image
    }

    func createImageData(fileImagePath: String) -> NSImage {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: fileImagePath)) else {
            uiLog.error("Error accessing file \(fileImagePath). Incorrect permissions")
            return createErrorImage()
        }
        return NSImage(data: imageData) ?? createErrorImage()
    }

    private func createErrorImage() -> NSImage {
        let errorImageConfig = NSImage.SymbolConfiguration(pointSize: 200, weight: .regular)
        return NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)?.withSymbolConfiguration(errorImageConfig) ?? NSImage()
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
    func logUserDeferrals(resetCount: Bool = false) {
        if CommandLineUtilities().demoModeEnabled() {
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
        if CommandLineUtilities().demoModeEnabled() {
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

    func logRequiredMinimumOSVersion() {
        nudgeDefaults.set(OSVersionRequirementVariables.requiredMinimumOSVersion, forKey: "requiredMinimumOSVersion")
    }

    func userInitiatedDeviceInfo() {
        uiLog.notice("\("User clicked deviceInfo", privacy: .public)")
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
    func getBackupMajorUpgradeAppPath() -> String {
        if VersionManager().getMajorRequiredNudgeOSVersion() == 12 {
            return "/Applications/Install macOS Monterey.app"
        } else if VersionManager().getMajorRequiredNudgeOSVersion() == 13 {
            return "/Applications/Install macOS Ventura.app"
        } else if VersionManager().getMajorRequiredNudgeOSVersion() == 14 {
            return "/Applications/Install macOS Sonoma.app"
        } else { // TODO: Update this for next year with another else if
            return "/Applications/Install macOS Monterey.app"
        }
    }

    func getJSONUrl() -> String {
        let jsonURL = nudgeDefaults.string(forKey: "json-url") ?? "file:///Library/Preferences/com.github.macadmins.Nudge.json" // For Greg Neagle
        utilsLog.debug("JSON url: \(jsonURL, privacy: .public)")
        return jsonURL
    }

    func getNudgeJSONPreferences() -> NudgePreferences? {
        let url = getJSONUrl()
        if CommandLineUtilities().bundleModeEnabled() {
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

        if CommandLineUtilities().demoModeEnabled() || CommandLineUtilities().unitTestingEnabled() {
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
}

struct SMAppManager {
    @available(macOS 13.0, *)
    func loadSMAppLaunchAgent(appService: SMAppService, appServiceStatus: SMAppService.Status) {
        let url = URL(string: "/Library/LaunchAgents/\(UserExperienceVariables.launchAgentIdentifier).plist")!
        let legacyStatus = SMAppService.statusForLegacyPlist(at: url)
        let passedThroughCLI = CommandLineUtilities().registerSMAppArgumentPassed()
        if legacyStatus == .enabled {
            if passedThroughCLI {
                print("Legacy Nudge LaunchAgent currently loaded. Please disable this agent before attempting to register modern agent.")
                exit(1)
            } else {
                osLog.info("Legacy Nudge LaunchAgent currently loaded. Please disable this agent before attempting to register modern agent.")
            }
        } else {
            if appServiceStatus == .enabled {
                if passedThroughCLI {
                    print("Nudge LaunchAgent is currently registered and enabled")
                    exit(0)
                } else {
                    osLog.info("Nudge LaunchAgent is currently registered and enabled")
                }
            } else {
                do {
                    if passedThroughCLI {
                        print("Registering Nudge LaunchAgent")
                    } else {
                        osLog.info("Registering Nudge LaunchAgent")
                    }
                    try appService.register()
                } catch {
                    if passedThroughCLI {
                        print("Failed to register Nudge LaunchAgent")
                        exit(1)
                    } else {
                        osLog.info("Failed to register Nudge LaunchAgent")
                        return
                    }
                }
                if passedThroughCLI {
                    print("Successfully registered Nudge LaunchAgent")
                    exit(0)
                } else {
                    osLog.info("Successfully registered Nudge LaunchAgent")
                }
            }
        }
    }

    @available(macOS 13.0, *)
    func unloadSMAppLaunchAgent(appService: SMAppService, appServiceStatus: SMAppService.Status) {
        let passedThroughCLI = CommandLineUtilities().unregisterSMAppArgumentPassed()
        if appServiceStatus == .notFound {
            if passedThroughCLI {
                print("Nudge LaunchAgent has never been registered")
                exit(0)
            } else {
                osLog.info("Nudge LaunchAgent has never been registered")
            }
        } else if appServiceStatus == .notRegistered {
            if passedThroughCLI {
                print("Nudge LaunchAgent is not currently registered")
                exit(0)
            } else {
                osLog.info("Nudge LaunchAgent is not currently registered")
            }
        } else {
            do {
                if passedThroughCLI {
                    print("Unregistering Nudge LaunchAgent")
                } else {
                    osLog.info("Unregistering Nudge LaunchAgent")
                }
                try appService.unregister()
            } catch {
                if passedThroughCLI {
                    print("Failed to unregister Nudge LaunchAgent")
                    exit(1)
                } else {
                    osLog.info("Failed to unregister Nudge LaunchAgent")
                    return
                }
            }
            if passedThroughCLI {
                print("Successfully unregistered Nudge LaunchAgent")
                exit(0)
            } else {
                osLog.info("Successfully unregistered Nudge LaunchAgent")
            }
        }
    }
}

struct UIUtilities {
    func centerNudge() {
        // NSApp.windows[0] is only safe because we have a single window. Should we increase windows, this will be a problem.
        // Sheets do not count as windows though.
        NSApp.windows[0].center()
    }

    func openMoreInfo() {
        guard let url = URL(string: OSVersionRequirementVariables.aboutUpdateURL) else {
            return
        }
        uiLog.notice("\("User clicked moreInfo button", privacy: .public)")
        NSWorkspace.shared.open(url)
    }

    func setDeferralTime(deferralTime: Date) {
        if CommandLineUtilities().demoModeEnabled() {
            return
        }
        nudgeDefaults.set(deferralTime, forKey: "deferRunUntil")
    }

    func showEasterEgg() -> Bool {
        let components = Calendar.current.dateComponents([.day, .month], from: DateManager().getCurrentDate())
        return (components.month == 8 && components.day == 6)
    }

    func updateDevice(userClicked: Bool = true) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        var url = String()
        if FeatureVariables.actionButtonPath != nil {
            if !FeatureVariables.actionButtonPath!.isEmpty {
                url = FeatureVariables.actionButtonPath!
            } else {
                prefsProfileLog.error("\("actionButtonPath contains empty string - actionButton will be unable to trigger any action.", privacy: .public)")
                return
            }
        } else if AppStateManager().requireMajorUpgrade() {
            if majorUpgradeAppPathExists {
                url = OSVersionRequirementVariables.majorUpgradeAppPath
            } else if majorUpgradeBackupAppPathExists {
                url = NetworkFileManager().getBackupMajorUpgradeAppPath()
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
            if nudgePrimaryState.backgroundBlur.count > 0 {
                uiLog.notice("\("Attempting to remove forced blur", privacy: .public)")
                for (index, _) in screens.enumerated() {
                    nudgePrimaryState.backgroundBlur[index].close()
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
        exit(0)
    }
}

struct VersionManager {
    func fullyUpdated() -> Bool {
        let fullyUpdated = VersionManager().versionGreaterThanOrEqual(currentVersion: GlobalVariables.currentOSVersion, newVersion: OSVersionRequirementVariables.requiredMinimumOSVersion)
        if fullyUpdated {
            utilsLog.notice("\("Current operating system (\(GlobalVariables.currentOSVersion)) is greater than or equal to required operating system (\(OSVersionRequirementVariables.requiredMinimumOSVersion))", privacy: .public)")
            return true
        } else {
            return false
        }
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
        let parts = OSVersionRequirementVariables.requiredMinimumOSVersion.split(separator: ".", omittingEmptySubsequences: false)
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

    func getNudgeVersion() -> String {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    func newNudgeEvent() -> Bool {
        VersionManager().versionGreaterThan(currentVersion: OSVersionRequirementVariables.requiredMinimumOSVersion, newVersion: nudgePrimaryState.userRequiredMinimumOSVersion)
    }

    // Adapted from https://stackoverflow.com/a/25453654
    func versionEqual(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedSame
    }

    func versionGreaterThan(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedDescending
    }

    func versionGreaterThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) != .orderedAscending
    }

    func versionLessThan(currentVersion: String, newVersion: String) -> Bool {
        return currentVersion.compare(newVersion, options: .numeric) == .orderedAscending
    }

    func versionLessThanOrEqual(currentVersion: String, newVersion: String) -> Bool {
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
