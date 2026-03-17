//
//  Main.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

#if canImport(ServiceManagement)
import ServiceManagement
#endif
import SwiftUI
import UserNotifications

@main
struct Main: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = nudgePrimaryState

    var body: some Scene {
        WindowGroup {
            mainContentView
        }
        .windowResizabilityContentSize()
        .windowStyle(.hiddenTitleBar)
    }

    private var mainContentView: some View {
        if CommandLineUtilities().debugUIModeEnabled() {
            return AnyView(debugModeView)
        } else {
            return AnyView(
                ContentView()
                    .environmentObject(appState)
                    .standardFrame
            )
        }
    }

    private var debugModeView: some View {
        VSplitView {
            ForEach([true, false], id: \.self) { forceSimpleMode in
                ContentView(forceSimpleMode: forceSimpleMode)
                    .environmentObject(appState)
                    .standardFrame
            }
        }
        .frame(height: uiConstants.declaredWindowHeight * 2)
    }
}

extension View {
    var standardFrame: some View {
        self.frame(width: uiConstants.declaredWindowWidth, height: uiConstants.declaredWindowHeight)
    }
}

struct ContentView: View {
    var forceSimpleMode: Bool = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        contentView
            .background(HostingWindowFinder(callback: configureWindow))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                initialLaunchLogic()
                handleNudgeActivation()
                updateUI()
            }
            .onReceive(Intervals.nudgeRefreshCycleTimer) { _ in
                handleNudgeActivation()
            }
    }

    private var contentView: some View {
        if simpleMode() || forceSimpleMode {
            return AnyView(SimpleMode())
        } else {
            return AnyView(StandardMode())
        }
    }

    private func configureWindow(window: NSWindow?) {
        window?.standardWindowButton(.closeButton)?.isHidden = true
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(.zoomButton)?.isHidden = true
        window?.center()
        window?.isMovable = UserExperienceVariables.allowMovableWindow
        window?.collectionBehavior = [.fullScreenAuxiliary]
        window?.delegate = UIConstants.windowDelegate
    }

    private func handleNudgeActivation() {
        if needToActivateNudge() {
            if nudgeLogState.afterFirstLaunch {
                appState.userSessionDeferrals += 1
                appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
            }
            AppStateManager().activateNudge()
        }
        updateUI()
    }

    func updateUI() {
        if AppStateManager().requireDualQuitButtons() || appState.userDeferrals > UserExperienceVariables.allowedDeferralsUntilForcedSecondaryQuitButton {
            appState.requireDualQuitButtons = true
        }
        if DateManager().pastRequiredInstallationDate() || appState.deferralCountPastThreshold {
            appState.allowButtons = false
        }
        appState.daysRemaining = DateManager().getNumberOfDaysBetween()
        appState.hoursRemaining = DateManager().getNumberOfHoursRemaining()
        appState.secondsRemaining = DateManager().getNumberOfSecondsRemaining()
    }
}

struct HostingWindowFinder: NSViewRepresentable {
    // https://stackoverflow.com/a/66039864
    // https://gist.github.com/steve228uk/c960b4880480c6ed186d
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Create an AppDelegate so that we can more finely control how Nudge operates
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidBecomeActive(_ notification: Notification) {
        // TODO: Perhaps move some of the ContentView logic into this - Ex: centering UI, full screen
        // print("applicationDidBecomeActive")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // print("applicationDidFinishLaunching")
        UIUtilities().centerNudge()
        setupNotificationObservers()
        handleKeyboardEvents()
        handleApplicationLaunchesIfNeeded()
        checkFullScreenStateOnFirstLaunch()
    }

    func applicationDidResignActive(_ notification: Notification) {
        // TODO: This function can be used to force nudge right back in front if a user moves to another app
        // print("applicationDidResignActive")
    }

    // Only exit if primaryQuitButton is clicked
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if nudgePrimaryState.shouldExit {
            return .terminateNow
        } else {
            if (CommandLineUtilities().simulateOSVersion() != nil) || (CommandLineUtilities().simulateHardwareID() != nil) || (CommandLineUtilities().simulateDate() != nil) {
                LogManager.warning("Attempt to exit Nudge was allowed due to simulation arguments.", logger: uiLog)
                return .terminateNow
            }
            // Log the attempt to exit the application if it should not exit yet
            LogManager.warning("Attempt to exit Nudge was prevented.", logger: uiLog)
            return .terminateCancel
        }
    }

    // Allows Nudge to terminate if all windows have been closed.
    // Useful if the close button is visible or if windows are closed by other means.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        // TODO: Perhaps move some of the ContentView logic into this - Ex: updateUI()
        // print("applicationWillBecomeActive")
    }

    func sofaPreLaunchLogic() {
        if OptionalFeatureVariables.utilizeSOFAFeed {
            var selectedOS: OSInformation?
            var foundMatch = false
            Globals.sofaAssets = NetworkFileManager().getSOFAAssets()
            if let macOSSOFAAssets = Globals.sofaAssets?.osVersions {
                // Get current installed OS version
                let currentInstalledVersion = GlobalVariables.currentOSVersion
                let currentMajorVersion = VersionManager.getMajorVersion(from: currentInstalledVersion)

                for osVersion in macOSSOFAAssets {
                    if PrefsWrapper.requiredMinimumOSVersion == "latest" {
                        selectedOS = osVersion.latest
                    } else if PrefsWrapper.requiredMinimumOSVersion == "latest-minor" {
                        if VersionManager.getMajorOSVersion() == Int(osVersion.osVersion.split(separator: " ").last!) {
                            selectedOS = osVersion.latest
                        } else {
                            continue
                        }
                    } else if PrefsWrapper.requiredMinimumOSVersion == "latest-supported" {
                        if OptionalFeatureVariables.attemptToCheckForSupportedDevice {
                            selectedOS = osVersion.securityReleases.first
                            if !selectedOS!.supportedDevices.contains(where: { supportedDevice in Globals.hardwareModelIDs.contains { $0.uppercased() == supportedDevice.uppercased() } }) {
                                continue
                            }
                        } else {
                            LogManager.notice("Attempting to use latest-supported without supported device UI features. Please set attemptToCheckForSupportedDevice to true", logger: sofaLog)
                            break
                        }
                    } else {
                        if osVersion.securityReleases.first(where: { $0.productVersion == nudgePrimaryState.requiredMinimumOSVersion }) != nil {
                            selectedOS = osVersion.securityReleases.first(where: { $0.productVersion == nudgePrimaryState.requiredMinimumOSVersion })
                        } else {
                            continue
                        }
                    }

                    var totalActivelyExploitedCVEs = 0
                    let selectedOSVersion = selectedOS!.productVersion
                    var allVersions = [String]()

                    // Collect all versions
                    for osVersion in macOSSOFAAssets {
                        allVersions.append(osVersion.latest.productVersion)
                        for securityRelease in osVersion.securityReleases {
                            allVersions.append(securityRelease.productVersion)
                        }
                    }

                    // Sort versions
                    allVersions.sort { VersionManager.versionLessThan(currentVersion: $0, newVersion: $1) }

                    // Filter versions between current and selected OS version
                    let filteredVersions = VersionManager().removeDuplicates(from: allVersions.filter {
                        VersionManager.versionGreaterThanOrEqual(currentVersion: $0, newVersion: currentInstalledVersion) &&
                        VersionManager.versionLessThanOrEqual(currentVersion: $0, newVersion: selectedOSVersion)
                    })

                    // Filter versions with the same major version as the current installed version
                    var minorVersions = VersionManager().removeDuplicates(from: filteredVersions.filter { version in
                        VersionManager.getMajorVersion(from: version) == currentMajorVersion
                    })
                    // Remove the current installed version from minorVersions
                    minorVersions.removeAll { $0 == currentInstalledVersion }

                    // Count actively exploited CVEs in the filtered versions
                    LogManager.notice("Assessing macOS version range for active exploits: \(filteredVersions) ", logger: sofaLog)
                    for osVersion in macOSSOFAAssets {
                        if filteredVersions.contains(osVersion.latest.productVersion) {
                            totalActivelyExploitedCVEs += osVersion.latest.activelyExploitedCVEs.count
                        }
                        for securityRelease in osVersion.securityReleases {
                            if filteredVersions.contains(securityRelease.productVersion) {
                                totalActivelyExploitedCVEs += securityRelease.activelyExploitedCVEs.count
                            }
                        }
                    }
                    let activelyExploitedCVEs = totalActivelyExploitedCVEs > 0

                    let presentCVEs = selectedOS!.cves.count > 0
                    let slaExtension: TimeInterval
                    // Start setting UI fields
                    nudgePrimaryState.requiredMinimumOSVersion = selectedOS!.productVersion
                    nudgePrimaryState.sofaAboutUpdateURL = selectedOS!.securityInfo
                    nudgePrimaryState.activelyExploitedCVEs = activelyExploitedCVEs
                    switch (activelyExploitedCVEs, presentCVEs, AppStateManager().requireMajorUpgrade()) {
                    case (false, true, true):
                        LogManager.notice("Non Actively Exploited Major Upgrade detected. Using nonActivelyExploitedCVEsMajorUpgradeSLA value: \(OSVersionRequirementVariables.nonActivelyExploitedCVEsMajorUpgradeSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.nonActivelyExploitedCVEsMajorUpgradeSLA * 86400)
                    case (false, true, false):
                        LogManager.notice("Non Actively Exploited Minor Update detected. Using nonActivelyExploitedCVEsMinorUpdateSLA value: \(OSVersionRequirementVariables.nonActivelyExploitedCVEsMinorUpdateSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.nonActivelyExploitedCVEsMinorUpdateSLA * 86400)
                    case (true, false, true): // The selected major upgrade does not have CVEs, but the old OS does
                        LogManager.notice("Actively Exploited Major Upgrade detected. Using activelyExploitedCVEsMajorUpgradeSLA value: \(OSVersionRequirementVariables.activelyExploitedCVEsMajorUpgradeSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.activelyExploitedCVEsMajorUpgradeSLA * 86400)
                    case (true, true, true):
                        LogManager.notice("Actively Exploited Major Upgrade detected. Using activelyExploitedCVEsMajorUpgradeSLA value: \(OSVersionRequirementVariables.activelyExploitedCVEsMajorUpgradeSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.activelyExploitedCVEsMajorUpgradeSLA * 86400)
                    case (true, false, false):
                        LogManager.notice("Actively Exploited Minor Update detected. Using activelyExploitedCVEsMinorUpdateSLA value: \(OSVersionRequirementVariables.activelyExploitedCVEsMinorUpdateSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.activelyExploitedCVEsMinorUpdateSLA * 86400)
                    case (true, true, false):
                        LogManager.notice("Actively Exploited Minor Update detected. Using activelyExploitedCVEsMinorUpdateSLA value: \(OSVersionRequirementVariables.activelyExploitedCVEsMinorUpdateSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.activelyExploitedCVEsMinorUpdateSLA * 86400)
                    case (false, false, true):
                        LogManager.notice("Standard Major Upgrade detected. Using standardMajorUpgradeSLA value: \(OSVersionRequirementVariables.standardMajorUpgradeSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.standardMajorUpgradeSLA * 86400)
                    case (false, false, false):
                        LogManager.notice("Standard Minor Update detected. Using standardMinorUpdateSLA value: \(OSVersionRequirementVariables.standardMinorUpdateSLA)", logger: sofaLog)
                        slaExtension = TimeInterval(OSVersionRequirementVariables.standardMinorUpdateSLA * 86400)
                    default: // If we get here, something is wrong, use 90 days as a safety
                        LogManager.warning("SLA Extension logic failed, using 90 days as a safety", logger: sofaLog)
                        slaExtension = TimeInterval(90 * 86400)
                    }

                    if OptionalFeatureVariables.disableNudgeForStandardInstalls && !presentCVEs {
                        LogManager.notice("No known CVEs for \(selectedOS!.productVersion) and disableNudgeForStandardInstalls is set to true", logger: sofaLog)
                        AppStateManager().exitNudge()
                    }
                    LogManager.notice("SOFA Actively Exploited CVEs: \(activelyExploitedCVEs)", logger: sofaLog)

                    releaseDate = selectedOS!.releaseDate ?? Date()
                    if requiredInstallationDate == Date(timeIntervalSince1970: 0) {
                        if OSVersionRequirementVariables.minorVersionRecalculationThreshold > 0 {
                            if minorVersions.isEmpty {
                                requiredInstallationDate = selectedOS!.releaseDate?.addingTimeInterval(slaExtension) ?? DateManager().getCurrentDate().addingTimeInterval(TimeInterval(90 * 86400))
                            } else {
                                LogManager.notice("Assessing macOS version range for recalculation: \(minorVersions)", logger: sofaLog)
                                let safeIndex = max(0, minorVersions.count - (OSVersionRequirementVariables.minorVersionRecalculationThreshold + 1)) // Ensure the index is within bounds
                                let targetVersion = minorVersions[safeIndex]
                                var foundVersion = false
                                LogManager.notice("minorVersionRecalculationThreshold is set to \(OSVersionRequirementVariables.minorVersionRecalculationThreshold) - Current Version: \(currentInstalledVersion) - Targeting version \(targetVersion) requiredInstallationDate via SOFA", logger: sofaLog)
                                for osVersion in macOSSOFAAssets {
                                    for securityRelease in osVersion.securityReleases {
                                        if securityRelease.productVersion == targetVersion {
                                            requiredInstallationDate = securityRelease.releaseDate?.addingTimeInterval(slaExtension) ?? DateManager().getCurrentDate().addingTimeInterval(TimeInterval(90 * 86400))
                                            LogManager.notice("Found target macOS version \(targetVersion) - releaseDate is \(securityRelease.releaseDate!), slaExtension is \(LoggerUtilities().printTimeInterval(slaExtension))", logger: sofaLog)
                                            foundVersion = true
                                            break
                                        }
                                    }
                                }
                                if !foundVersion {
                                    LogManager.warning("Could not find requiredInstallationDate from target macOS \(targetVersion)", logger: sofaLog)
                                    requiredInstallationDate = selectedOS!.releaseDate?.addingTimeInterval(slaExtension) ?? DateManager().getCurrentDate().addingTimeInterval(TimeInterval(90 * 86400))
                                }
                            }
                        } else {
                            requiredInstallationDate = selectedOS!.releaseDate?.addingTimeInterval(slaExtension) ?? DateManager().getCurrentDate().addingTimeInterval(TimeInterval(90 * 86400))
                        }
                        LogManager.notice("Setting requiredInstallationDate via SOFA to \(requiredInstallationDate)", logger: sofaLog)
                    }
                    LogManager.notice("SOFA Matched OS Version: \(selectedOS!.productVersion)", logger: sofaLog)
                    LogManager.notice("SOFA Assets: \(selectedOS!.supportedDevices)", logger: sofaLog)
                    LogManager.notice("SOFA CVEs: \(selectedOS!.cves)", logger: sofaLog)

                    if OptionalFeatureVariables.attemptToCheckForSupportedDevice {
                        if selectedOS!.supportedDevices.isEmpty {
                            LogManager.warning("Sofa Assets list is empty, disregarding unsupported UI.", logger: sofaLog)
                            nudgePrimaryState.deviceSupportedByOSVersion = true
                        } else {
                            LogManager.notice("Assessed Model IDs: \(Globals.hardwareModelIDs)", logger: sofaLog)
                            let deviceMatchFound = selectedOS!.supportedDevices.contains(where: {
                                supportedDevice in Globals.hardwareModelIDs.contains { $0.uppercased() == supportedDevice.uppercased() } }
                            )
                            LogManager.notice("Assessed Model ID found in SOFA Entry: \(deviceMatchFound)", logger: sofaLog)
                            let majorRequiredVersion = VersionManager.getMajorRequiredNudgeOSVersion()
                            let currentMajorVersion = VersionManager.getMajorOSVersion()
                            if !deviceMatchFound && (majorRequiredVersion == currentMajorVersion) {
                                LogManager.warning("Assessed Model ID not found in SOFA Entry, but device is already running required major OS version. Disregarding unsupported UI.", logger: sofaLog)
                                nudgePrimaryState.deviceSupportedByOSVersion = true
                            } else {
                                nudgePrimaryState.deviceSupportedByOSVersion = deviceMatchFound
                            }
                        }
                    }
                    foundMatch = true
                    break
                }
                if !foundMatch {
                    // If no matching product version found or the device is not supported, return false
                    LogManager.notice("Could not find requiredMinimumOSVersion \(nudgePrimaryState.requiredMinimumOSVersion) in SOFA feed", logger: sofaLog)
                    if PrefsWrapper.requiredMinimumOSVersion == "latest-minor" {
                        LogManager.notice("Device is likely running a newer version of macOS than in the production SOFA feed, exiting", logger: sofaLog)
                        nudgePrimaryState.shouldExit = true
                        exit(1)
                    }
                }
            } else {
                LogManager.error("Could not fetch SOFA feed", logger: sofaLog)
                nudgePrimaryState.shouldExit = true
                exit(1)
            }
        }
    }

    // Pre-Launch Logic
    func applicationWillFinishLaunching(_ notification: Notification) {
        // print("applicationWillFinishLaunching")
        handleSMAppService()
        checkForBadProfilePath()
        handleCommandLineArguments()
        applyRandomDelayIfNecessary()
        sofaPreLaunchLogic()
        applyGracePeriodLogic()
        applydelayNudgeEventLogic()
        updateNudgeState()
        handleSoftwareUpdateRequirements()
    }

    func applicationWillResignActive(_ notification: Notification) {
        // TODO: This function can be used to stop nudge from resigning its activation state
        // print("applicationWillResignActive")
    }

    @objc func logHiddenApplication(_ notification: Notification) {
        LogManager.info("Application hidden", logger: utilsLog)
    }

    @objc func scheduleLocal(applicationIdentifier: String) {
        if applicationIdentifier.isEmpty { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let content = self.createNotificationContent(for: applicationIdentifier)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.001, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            switch settings.authorizationStatus {
                case .authorized, .provisional:
                    center.add(request)
                    LogManager.info("Scheduled notification for terminated application \(applicationIdentifier)", logger: uiLog)
                case .denied:
                    LogManager.error("Notifications are denied; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
                case .notDetermined:
                    LogManager.warning("Notification status not determined; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
                @unknown default:
                    LogManager.warning("Unknown notification status; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
            }
        }
    }

    @objc func screenParametersChanged(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        LogManager.info("Screen parameters changed - Notification Center", logger: utilsLog)
        UIUtilities().centerNudge()
    }

    @objc func screenProfileChanged(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        LogManager.info("Display has changed profiles - Notification Center", logger: utilsLog)
        UIUtilities().centerNudge()
    }

    @objc func spacesStateChanged(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        UIUtilities().centerNudge()
        LogManager.info("Spaces state changed", logger: utilsLog)
        nudgePrimaryState.afterFirstStateChange = true
    }

    @objc func terminateApplicationSender(_ notification: Notification) {
        LogManager.info("Application launched - checking if application should be terminated", logger: utilsLog)
        terminateApplications(afterInitialLaunch: true)
    }

    private func applyGracePeriodLogic() {
        _ = AppStateManager().gracePeriodLogic()
        if nudgePrimaryState.shouldExit {
            exit(0)
        }
    }

    private func applyRandomDelayIfNecessary() {
        if UserExperienceVariables.randomDelay && !(CommandLineUtilities().disableRandomDelayArgumentPassed() || CommandLineUtilities().unitTestingEnabled() || CommandLineUtilities().demoModeEnabled()) {
            let delaySeconds = Int.random(in: 1...UserExperienceVariables.maxRandomDelayInSeconds)
            LogManager.notice("Delaying initial run (in seconds) by: \(delaySeconds)", logger: uiLog)

            let delayDate = Date().addingTimeInterval(TimeInterval(delaySeconds))
            while Date() < delayDate {
                RunLoop.current.run(mode: .default, before: delayDate)
            }

            LogManager.notice("Finished delay", logger: uiLog)
        }
    }

    private func applydelayNudgeEventLogic() {
        _ = AppStateManager().delayNudgeEventLogic()
        if nudgePrimaryState.shouldExit {
            exit(0)
        }
    }

    private func checkForBadProfilePath() {
        let badProfilePath = "/Library/Managed Preferences/com.github.macadmins.Nudge.json.plist"
        if FileManager.default.fileExists(atPath: badProfilePath) {
            LogManager.warning("Found bad profile path at \(badProfilePath)", logger: prefsProfileLog)
            exit(1)
        }
    }

    private func checkFullScreenStateOnFirstLaunch() {
        guard !nudgeLogState.afterFirstLaunch else { return }
        nudgeLogState.afterFirstLaunch = true
        if NSWorkspace.shared.isActiveSpaceFullScreen() {
            NSApp.hide(self)
            // NSApp.windows.first?.resignKey()
            // NSApp.unhideWithoutActivation()
            // NSApp.deactivate()
            // NSApp.unhideAllApplications(nil)
            // NSApp.hideOtherApplications(self)
        }
    }

    private func createNotificationContent(for applicationIdentifier: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = UserInterfaceVariables.applicationTerminatedTitleText.localized(desiredLanguage: getDesiredLanguage())
        content.subtitle = "(\(applicationIdentifier))"
        content.title = UserInterfaceVariables.applicationTerminatedBodyText.localized(desiredLanguage: getDesiredLanguage())
        content.categoryIdentifier = "alert"
        content.sound = UNNotificationSound.default
        content.attachments = []
        let applicationTerminatedNotificationImagePath = UserInterfaceVariables.applicationTerminatedNotificationImagePath
        let tempImagePath = "/var/tmp/nudge-applicationTerminatedNotification.png"
        if FileManager.default.fileExists(atPath: applicationTerminatedNotificationImagePath) {
            if nudgePrimaryState.hasRenderedApplicationTerminatedNotificationImagePath {
                do {
                    let fileURL = URL(fileURLWithPath: tempImagePath)
                    let attachment = try UNNotificationAttachment(identifier: "AttachedContent", url: fileURL, options: .none)
                    content.attachments = [attachment]
                } catch let error {
                    LogManager.error("\(error)", logger: uiLog)
                }
            } else {
                do {
                    // In order for the attachment to look properly, it has to be resized to a square
                    guard let sourceImage = NSImage(contentsOfFile: applicationTerminatedNotificationImagePath) else {
                        throw NSError(domain: "Failed to load image from path: \(applicationTerminatedNotificationImagePath)", code: 0, userInfo: nil)
                    }
                    // Find the maximum dimension and create a square based on it
                    let maxDimension = max(sourceImage.size.width, sourceImage.size.height)
                    let newSize = CGSize(width: maxDimension, height: maxDimension)

                    // Create a new image with a square size, filling with transparent background
                    let targetImage = NSImage(size: newSize)
                    targetImage.lockFocus()
                    let context = NSGraphicsContext.current!
                    context.imageInterpolation = .high
                    NSColor.clear.set()
                    NSBezierPath(rect: NSRect(origin: .zero, size: newSize)).fill()

                    // Calculate the origin point to center the source image
                    let x = (maxDimension - sourceImage.size.width) / 2
                    let y = (maxDimension - sourceImage.size.height) / 2
                    let targetRect = NSRect(x: x, y: y, width: sourceImage.size.width, height: sourceImage.size.height)

                    sourceImage.draw(in: targetRect, from: NSRect(origin: .zero, size: sourceImage.size), operation: .sourceOver, fraction: 1.0)
                    targetImage.unlockFocus()

                    guard let tiffData = targetImage.tiffRepresentation,
                          let bitmapImage = NSBitmapImageRep(data: tiffData),
                          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
                        throw NSError(domain: "Failed to create or convert image", code: 0, userInfo: nil)
                    }

                    try pngData.write(to: URL(fileURLWithPath: tempImagePath))

                    // Load temporary file
                    let fileURL = URL(fileURLWithPath: tempImagePath)
                    let attachment = try UNNotificationAttachment(identifier: "AttachedContent", url: fileURL, options: .none)
                    content.attachments = [attachment]
                    nudgePrimaryState.hasRenderedApplicationTerminatedNotificationImagePath = true
                } catch let error {
                    LogManager.error("\(error)", logger: uiLog)
                }
            }
        } else {
            LogManager.error("applicationTerminatedNotificationImagePath does not exist on disk, skipping notification image.", logger: uiLog)
        }
        return content
    }

    private func detectBannedShortcutKeys(with event: NSEvent) -> Bool {
        if (CommandLineUtilities().simulateOSVersion() != nil) || (CommandLineUtilities().simulateHardwareID() != nil) || (CommandLineUtilities().simulateDate() != nil) { return false }
        guard NSApplication.shared.isActive else { return false }
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
                // Disable CMD + H - Hides Nudge
            case [.command] where event.charactersIgnoringModifiers == "h":
                LogManager.warning("Nudge detected an attempt to hide the application via CMD + H shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + M - Minimizes Nudge
            case [.command] where event.charactersIgnoringModifiers == "m":
                LogManager.warning("Nudge detected an attempt to minimize the application via CMD + M shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + N - closes the Nudge window and breaks it
            case [.command] where event.charactersIgnoringModifiers == "n":
                LogManager.warning("Nudge detected an attempt to close the application via CMD + N shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Q - fully closes Nudge
            case [.command] where event.charactersIgnoringModifiers == "q":
                LogManager.warning("Nudge detected an attempt to quit the application via CMD + Q shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + W - closes the Nudge window and breaks it
            case [.command] where event.charactersIgnoringModifiers == "w":
                LogManager.warning("Nudge detected an attempt to close the application via CMD + W shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + M - Minimizes Nudge
            case [.command, .option] where event.charactersIgnoringModifiers == "m":
                LogManager.warning("Nudge detected an attempt to minimise the application via CMD + Option + M shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + N - Add tabs to Nudge window
            case [.command, .option] where event.charactersIgnoringModifiers == "n":
                LogManager.warning("Nudge detected an attempt to add tabs to the application via CMD + Option + N shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + W - Close Window
            case [.command, .option] where event.charactersIgnoringModifiers == "w":
                LogManager.warning("Nudge detected an attempt to add tabs to the application via CMD + Option + W shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + Esc (Force Quit Applications)
            case [.command, .option] where event.charactersIgnoringModifiers == "\u{1b}": // Escape key
                // This doesn't work since Apple allows that shortcut to bypass the application's memory.
                LogManager.warning("Nudge detected an attempt to open Force Quit Applications via CMD + Option + Esc.", logger: utilsLog)
                return true
            default:
                // Don't care about any other shortcut keys
                return false
        }
    }

    private func handleApplicationLaunchesIfNeeded() {
        guard OptionalFeatureVariables.attemptToBlockApplicationLaunches else { return }
        registerLocalNotifications()
        if !nudgeLogState.afterFirstLaunch && OptionalFeatureVariables.terminateApplicationsOnLaunch {
            terminateApplications()
        }
        Globals.snc.addObserver(
            self,
            selector: #selector(terminateApplicationSender(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    private func handleAttemptToFetchMajorUpgrade() {
        if GlobalVariables.fetchMajorUpgradeSuccessful == false && !majorUpgradeAppPathExists && !majorUpgradeBackupAppPathExists {
            if VersionManager.versionGreaterThan(currentVersion: GlobalVariables.currentOSVersion, newVersion: "12.3") {
                LogManager.info("Unable to fetch major upgrade and application missing, but macOS 12.3 and higher support delta major upgrades. Using new logic.", logger: uiLog)
            } else {
                LogManager.error("Unable to fetch major upgrade and application missing, exiting Nudge", logger: uiLog)
                nudgePrimaryState.shouldExit = true
                exit(1)
            }
        }
    }

    private func handleNoAttemptToFetchMajorUpgrade() {
        if !majorUpgradeAppPathExists && !majorUpgradeBackupAppPathExists {
            LogManager.error("Unable to find major upgrade application, reverting to actionButtonPath", logger: uiLog)
        }
    }

    private func handleCommandLineArguments() {
        if CommandLineUtilities().versionArgumentPassed() {
            print(VersionManager.getNudgeVersion())
            AppStateManager().exitNudge()
        } else if CommandLine.arguments.contains("-print-profile-config") {
            printConfigProfileAndExit()
        } else if CommandLine.arguments.contains("-print-json-config") {
            printConfigJSONAndExit()
        }
    }

    private func handleKeyboardEvents() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            self?.detectBannedShortcutKeys(with: $0) == true ? nil : $0
        }
    }


    private func handleMajorUpgradeRequirements() {
        if let actionButtonPath = FeatureVariables.actionButtonPath, !actionButtonPath.isEmpty {
            if OptionalFeatureVariables.attemptToFetchMajorUpgrade {
                handleAttemptToFetchMajorUpgrade()
            } else {
                handleNoAttemptToFetchMajorUpgrade()
            }
        } else {
            LogManager.warning("actionButtonPath is nil or empty - actionButton will be attempt to use /System/Library/CoreServices/Software Update.app for major upgrades", logger: prefsProfileLog)
            return
        }
    }

    private func handleSMAppService() {
        if #available(macOS 13, *) {
            let appService = SMAppService.agent(plistName: "com.github.macadmins.Nudge.SMAppService.plist")
            let mainAppServce = SMAppService.mainApp
            let appServiceStatus = appService.status
            let mainAppServiceStatus = mainAppServce.status
//            print("")
//            print("com.github.macadmins.Nudge.SMAppService")
//            print("notRegistered: \(appServiceStatus == SMAppService.Status.notRegistered)")
//            print("enabled: \(appServiceStatus == SMAppService.Status.enabled)")
//            print("requiresApproval: \(appServiceStatus == SMAppService.Status.requiresApproval)")
//            print("notFound: \(appServiceStatus == SMAppService.Status.notFound)")
//            print("")
//            print("mainAppService")
//            print("notRegistered: \(mainAppServiceStatus == SMAppService.Status.notRegistered)")
//            print("enabled: \(mainAppServiceStatus == SMAppService.Status.enabled)")
//            print("requiresApproval: \(mainAppServiceStatus == SMAppService.Status.requiresApproval)")
//            print("notFound: \(mainAppServiceStatus == SMAppService.Status.notFound)")
//            print("")

            if CommandLine.arguments.contains("--register") || UserExperienceVariables.loadLaunchAgent {
                SMAppManager().loadSMAppLaunchAgent(appService: appService, appServiceStatus: appServiceStatus)
            } else if CommandLine.arguments.contains("--unregister") || !UserExperienceVariables.loadLaunchAgent {
                SMAppManager().unloadSMAppLaunchAgent(appService: appService, appServiceStatus: appServiceStatus)
            }
        }
    }

    private func handleSoftwareUpdateRequirements() {
        self.runSoftwareUpdate()

        if AppStateManager().requireMajorUpgrade() {
            handleMajorUpgradeRequirements()
        }
    }

    private func printConfigJSONAndExit() {
        if !Globals.configJSON.isEmpty {
            print(String(decoding: Globals.configJSON, as: UTF8.self))
        }
        AppStateManager().exitNudge()
    }

    private func printConfigProfileAndExit() {
        if !Globals.configProfile.isEmpty {
            print(String(data: Globals.configProfile, encoding: .utf8) as AnyObject)
        }
        AppStateManager().exitNudge()
    }

    private func registerLocalNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                LogManager.info("User granted notifications - application blocking status now available", logger: utilsLog)
            } else if let error = error {
                LogManager.error("Error requesting notifications authorization: \(error.localizedDescription)", logger: utilsLog)
            } else {
                LogManager.info("User denied notifications - application blocking status will be unavailable", logger: utilsLog)
            }
        }
    }

    private func runUpdateAsynchronously() {
        DispatchQueue(label: "nudge-su", attributes: .concurrent).async {
            SoftwareUpdate().download()
        }
    }

    private func setupNotificationObservers() {
        setupNotificationCenterObservers()
        setupScreenChangeObservers()
        setupScreenLockObservers()
        setupWorkspaceNotificationCenterObservers()
        setupUserDefaultsObservers()
    }

    private func setupNotificationCenterObservers() {
        Globals.nc.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: NSApplication.shared,
            queue: .main) { _ in
                if UserExperienceVariables.allowMovableWindow { return }
                LogManager.debug("Window object frame moved - Notification Center", logger: utilsLog)
                UIUtilities().centerNudge()
            }
    }

    private func setupUserDefaultsObservers() {
        Globals.nc.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main) { _ in
                if ConfigurationManager().getConfigurationAsProfile() == Globals.configProfile {
                    LogManager.debug("MDM Profile has been re-installed or updated but configuration is identical, no need to quit Nudge.", logger: sofaLog)
                } else {
                    LogManager.info("MDM Profile has been re-installed or updated. Quitting Nudge to allow LaunchAgent to re-initalize with new settings.", logger: sofaLog)
                    nudgePrimaryState.shouldExit = true
                    exit(2)
                }
            }
    }

    private func setupScreenChangeObservers() {
        Globals.nc.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        Globals.nc.addObserver(
            self,
            selector: #selector(screenProfileChanged),
            name: NSWindow.didChangeScreenProfileNotification,
            object: nil
        )
    }

    private func setupScreenLockObservers() {
        Globals.dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main) { _ in
                nudgePrimaryState.screenCurrentlyLocked = true
                utilsLog.info("Screen was locked")
            }
        Globals.dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main) { _ in
                nudgePrimaryState.screenCurrentlyLocked = false
                utilsLog.info("Screen was unlocked")
            }
    }

    private func setupWorkspaceNotificationCenterObservers() {
        Globals.snc.addObserver(
            self,
            selector: #selector(spacesStateChanged(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        Globals.snc.addObserver(
            self,
            selector: #selector(logHiddenApplication(_:)),
            name: NSWorkspace.didHideApplicationNotification,
            object: nil
        )
    }

    private func terminateApplication(_ application: NSRunningApplication) {
        guard application.terminate() else {
            LogManager.error("Failed to terminate application: \(application.bundleIdentifier ?? "")", logger: utilsLog)
            return
        }
        LogManager.notice("Successfully terminated application: \(application.bundleIdentifier ?? "")", logger: utilsLog)
    }

    private func terminateApplications(afterInitialLaunch: Bool = false) {
        guard DateManager().pastRequiredInstallationDate() else {
            return
        }
        var hasTerminatedAnApplication = false
        let runningApplications = NSWorkspace.shared.runningApplications
        for runningApplication in runningApplications {
            let appBundleID = runningApplication.bundleIdentifier ?? ""
            if appBundleID == "com.github.macadmins.Nudge" || appBundleID.isEmpty {
                continue
            }
            if OptionalFeatureVariables.blockedApplicationBundleIDs.contains(appBundleID) {
                LogManager.info("Found \(appBundleID), terminating application", logger: utilsLog)
                scheduleLocal(applicationIdentifier: appBundleID)
                terminateApplication(runningApplication)
                hasTerminatedAnApplication = true
            }
        }
        if hasTerminatedAnApplication && afterInitialLaunch {
            AppStateManager().activateNudge()
        }
    }

    func runSoftwareUpdate() {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return
        }

        if OptionalFeatureVariables.asynchronousSoftwareUpdate {
            runUpdateAsynchronously()
        } else {
            SoftwareUpdate().download()
        }
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        LogManager.debug("Window attempted to move - Window Delegate", logger: utilsLog)
        UIUtilities().centerNudge()
    }
    func windowDidChangeScreen(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        LogManager.debug("Window moved screens - Window Delegate", logger: utilsLog)
        UIUtilities().centerNudge()
    }
    func windowDidChangeScreenProfile(_ notification: Notification) {
        if UserExperienceVariables.allowMovableWindow { return }
        LogManager.debug("Display has changed profiles - Window Delegate", logger: utilsLog)
        UIUtilities().centerNudge()
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            StandardMode()
                .environmentObject(nudgePrimaryState)
                .previewLayout(.fixed(width: uiConstants.declaredWindowWidth, height: uiConstants.declaredWindowHeight))
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("StandardMode (\(id))")
        }
        ForEach(["en", "es"], id: \.self) { id in
            SimpleMode()
                .environmentObject(nudgePrimaryState)
                .previewLayout(.fixed(width: uiConstants.declaredWindowWidth, height: uiConstants.declaredWindowHeight))
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("SimpleMode (\(id))")
        }
    }
}
#endif

// Stuff if we ever implement fullscreen
//        let presentationOptions: NSApplication.PresentationOptions = [
//            .hideDock, // Dock is entirely unavailable. Spotlight menu is disabled.
//            // .autoHideMenuBar,           // Menu Bar appears when moused to.
//            // .disableAppleMenu,          // All Apple menu items are disabled.
//            .disableProcessSwitching      // Cmd+Tab UI is disabled. All Exposé functionality is also disabled.
//            // .disableForceQuit,             // Cmd+Opt+Esc panel is disabled.
//            // .disableSessionTermination,    // PowerKey panel and Restart/Shut Down/Log Out are disabled.
//            // .disableHideApplication,       // Application "Hide" menu item is disabled.
//            // .autoHideToolbar,
//            // .fullScreen
//        ]
//        let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presentationOptions]
//        if let screen = NSScreen.main {
//            view.enterFullScreenMode(screen, withOptions: [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions:presentationOptions.rawValue])
//        }
//        //view.enterFullScreenMode(NSScreen.main!, withOptions: optionsDictionary)
