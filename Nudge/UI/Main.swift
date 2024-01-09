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
        window?.isMovable = false
        window?.collectionBehavior = [.fullScreenAuxiliary]
        window?.delegate = UIConstants.windowDelegate
        // _ = needToActivateNudge()
    }

    private func handleNudgeActivation() {
        if needToActivateNudge() {
            appState.userSessionDeferrals += 1
            appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
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

    // Pre-Launch Logic
    func applicationWillFinishLaunching(_ notification: Notification) {
        // print("applicationWillFinishLaunching")
        handleSMAppService()
        checkForBadProfilePath()
        handleCommandLineArguments()
        applyGracePeriodLogic()
        applyRandomDelayIfNecessary()
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
                    LogManager.info("Notifications are denied; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
                case .notDetermined:
                    LogManager.info("Notification status not determined; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
                @unknown default:
                    LogManager.info("Unknown notification status; cannot schedule notification for \(applicationIdentifier)", logger: uiLog)
            }
        }
    }

    // Observe screen locking. Maybe useful later
    @objc func screenLocked(_ notification: Notification) {
        nudgePrimaryState.screenCurrentlyLocked = true
        LogManager.info("Screen was locked", logger: utilsLog)
    }

    @objc func screenParametersChanged(_ notification: Notification) {
        LogManager.info("Screen parameters changed - Notification Center", logger: utilsLog)
        UIUtilities().centerNudge()
    }

    @objc func screenProfileChanged(_ notification: Notification) {
        LogManager.info("Display has changed profiles - Notification Center", logger: utilsLog)
        UIUtilities().centerNudge()
    }

    @objc func screenUnlocked(_ notification: Notification) {
        nudgePrimaryState.screenCurrentlyLocked = false
        LogManager.info("Screen was unlocked", logger: utilsLog)
    }

    @objc func spacesStateChanged(_ notification: Notification) {
        UIUtilities().centerNudge()
        LogManager.info("Spaces state changed", logger: utilsLog)
        nudgePrimaryState.afterFirstStateChange = true
    }

    @objc func terminateApplicationSender(_ notification: Notification) {
        LogManager.info("Application launched - checking if application should be terminated", logger: utilsLog)
        terminateApplications()
    }

    private func applyGracePeriodLogic() {
        _ = AppStateManager().gracePeriodLogic()
        if nudgePrimaryState.shouldExit {
            exit(0)
        }
    }

    private func applyRandomDelayIfNecessary() {
        if UserExperienceVariables.randomDelay {
            let delaySeconds = Int.random(in: 1...UserExperienceVariables.maxRandomDelayInSeconds)
            LogManager.notice("Delaying initial run (in seconds) by: \(delaySeconds)", logger: uiLog)
            sleep(UInt32(delaySeconds))
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
        content.title = "Application terminated".localized(desiredLanguage: getDesiredLanguage())
        content.subtitle = "(\(applicationIdentifier))"
        content.body = "Please update your device to use this application".localized(desiredLanguage: getDesiredLanguage())
        content.categoryIdentifier = "alert"
        content.sound = UNNotificationSound.default
        return content
    }

    private func detectBannedShortcutKeys(with event: NSEvent) -> Bool {
        guard NSApplication.shared.isActive else { return false }
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
                // Disable CMD + W - closes the Nudge window and breaks it
            case [.command] where event.charactersIgnoringModifiers == "w":
                LogManager.warning("Nudge detected an attempt to close the application via CMD + W shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + N - closes the Nudge window and breaks it
            case [.command] where event.charactersIgnoringModifiers == "n":
                LogManager.warning("Nudge detected an attempt to close the application via CMD + N shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Q - fully closes Nudge
            case [.command] where event.charactersIgnoringModifiers == "q":
                LogManager.warning("Nudge detected an attempt to quit the application via CMD + Q shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + M - Minimizes Nudge
            case [.command] where event.charactersIgnoringModifiers == "m":
                LogManager.warning("Nudge detected an attempt to minimize the application via CMD + M shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + H - Hides Nudge
            case [.command] where event.charactersIgnoringModifiers == "h":
                LogManager.warning("Nudge detected an attempt to hide the application via CMD + H shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + Esc (Force Quit Applications)
            case [.command, .option] where event.charactersIgnoringModifiers == "\u{1b}": // Escape key
                LogManager.warning("Nudge detected an attempt to open Force Quit Applications via CMD + Option + Esc.", logger: utilsLog)
                return true
                // Disable CMD + Option + M - Minimizes Nudge
            case [.command, .option] where event.charactersIgnoringModifiers == "µ":
                LogManager.warning("Nudge detected an attempt to minimise the application via CMD + Option + M shortcut key.", logger: utilsLog)
                return true
                // Disable CMD + Option + N - Add tabs to Nudge window
            case [.command, .option] where event.charactersIgnoringModifiers == "~":
                LogManager.warning("Nudge detected an attempt to add tabs to the application via CMD + Option + N shortcut key.", logger: utilsLog)
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
        Globals.nc.addObserver(
            self,
            selector: #selector(terminateApplicationSender(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    private func handleAttemptToFetchMajorUpgrade() {
        if GlobalVariables.fetchMajorUpgradeSuccessful == false && !majorUpgradeAppPathExists && !majorUpgradeBackupAppPathExists {
            LogManager.error("Unable to fetch major upgrade and application missing, exiting Nudge", logger: uiLog)
            nudgePrimaryState.shouldExit = true
            exit(1)
        }
    }

    private func handleNoAttemptToFetchMajorUpgrade() {
        if !majorUpgradeAppPathExists && !majorUpgradeBackupAppPathExists {
            LogManager.error("Unable to find major upgrade application, exiting Nudge", logger: uiLog)
            nudgePrimaryState.shouldExit = true
            exit(1)
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
            LogManager.warning("actionButtonPath is nil or empty - actionButton will be unable to trigger any action required for major upgrades", logger: prefsProfileLog)
            return
        }
    }

    private func handleSMAppService() {
        if #available(macOS 13, *) {
            let appService = SMAppService.agent(plistName: "com.github.macadmins.Nudge.SMAppService.plist")
            let appServiceStatus = appService.status

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
        setupScreenLockObservers()
        setupScreenChangeObservers()
        setupWorkspaceNotificationCenterObservers()
    }

    private func setupNotificationCenterObservers() {
        Globals.nc.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: NSApplication.shared,
            queue: .main) { _ in
                print("Window object frame moved - Notification Center")
                UIUtilities().centerNudge()
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
        Globals.nc.addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        Globals.nc.addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
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
        LogManager.info("Successfully terminated application: \(application.bundleIdentifier ?? "")", logger: utilsLog)
    }

    private func terminateApplications() {
        guard DateManager().pastRequiredInstallationDate() else {
            return
        }

        let runningApplications = NSWorkspace.shared.runningApplications
        for runningApplication in runningApplications {
            let appBundleID = runningApplication.bundleIdentifier ?? ""
            if appBundleID == "com.github.macadmins.Nudge" {
                continue
            }
            if OptionalFeatureVariables.blockedApplicationBundleIDs.contains(appBundleID) {
                LogManager.info("Found \(appBundleID), terminating application", logger: utilsLog)
                terminateApplication(runningApplication)
            }
        }
    }

    func runSoftwareUpdate() {
        guard !CommandLineUtilities().demoModeEnabled(),
              !CommandLineUtilities().unitTestingEnabled() else {
            return
        }

        let shouldRunAsynchronously = OptionalFeatureVariables.asynchronousSoftwareUpdate &&
        !AppStateManager().requireMajorUpgrade() &&
        !DateManager().pastRequiredInstallationDate()

        if shouldRunAsynchronously {
            runUpdateAsynchronously()
        } else {
            SoftwareUpdate().download()
        }
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        print("Window attempted to move - Window Delegate")
        UIUtilities().centerNudge()
    }
    func windowDidChangeScreen(_ notification: Notification) {
        print("Window moved screens - Window Delegate")
        UIUtilities().centerNudge()
    }
    func windowDidChangeScreenProfile(_ notification: Notification) {
        print("Display has changed profiles - Window Delegate")
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
