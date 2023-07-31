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
            if Utils().debugUIModeEnabled() {
                VSplitView {
                    ForEach([true, false], id: \.self) { id in
                        ContentView(forceSimpleMode: id)
                            .environmentObject(appState)
                            .frame(width: declaredWindowWidth, height: declaredWindowHeight)
                    }
                }
                .frame(height: declaredWindowHeight*2)
            } else {
                ContentView()
                    .environmentObject(appState)
                    .frame(width: declaredWindowWidth, height: declaredWindowHeight)
            }
        }
        .windowResizabilityContentSize()
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    var forceSimpleMode: Bool = false // do not move
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let backgroundView = if simpleMode() || forceSimpleMode {
            AnyView(SimpleMode())
        } else {
            AnyView(StandardMode())
        }
        backgroundView
            .background(
                HostingWindowFinder { window in
                    window?.standardWindowButton(.closeButton)?.isHidden = true //hides the red close button
                    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //hides the yellow miniaturize button
                    window?.standardWindowButton(.zoomButton)?.isHidden = true //this removes the green zoom button
                    window?.center() // center
                    window?.isMovable = false // not movable
                    window?.collectionBehavior = [.fullScreenAuxiliary]
                    window?.delegate = windowDelegate
                    _ = needToActivateNudge()
                }
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear(perform: nudgeStartLogic)
            .onAppear() {
                updateUI()
            }
            .onReceive(nudgeRefreshCycleTimer) { _ in
                if needToActivateNudge() {
                    appState.userSessionDeferrals += 1
                    appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
                }
                updateUI()
            }
    }
    
    func updateUI() {
        if Utils().requireDualQuitButtons() || appState.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
            appState.requireDualQuitButtons = true
        }
        if Utils().pastRequiredInstallationDate() || appState.deferralCountPastThreshhold {
            appState.allowButtons = false
        }
        appState.daysRemaining = Utils().getNumberOfDaysBetween()
        appState.hoursRemaining = Utils().getNumberOfHoursRemaining()
    }
}

struct HostingWindowFinder: NSViewRepresentable {
    // https://stackoverflow.com/a/66039864
    // https://gist.github.com/steve228uk/c960b4880480c6ed186d

    var callback: (NSWindow?) -> ()
    
    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        if Utils().versionArgumentPassed() {
            print(Utils().getNudgeVersion())
            Utils().exitNudge()
        }
        
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Create an AppDelegate so that we can more finely control how Nudge operates
class AppDelegate: NSObject, NSApplicationDelegate {
    // This allows Nudge to terminate if all of the windows have been closed. It was needed when the close button was visible, but less needed now.
    // However if someone does close all the windows, we still want this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        // TODO: This function can be used to stop nudge from resigning its activation state
        // print("applicationWillResignActive")
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        // TODO: This function can be used to force nudge right back in front if a user moves to another app
        // print("applicationDidResignActive")
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // TODO: Perhaps move some of the ContentView logic into this - Ex: updateUI()
        // print("applicationWillBecomeActive")
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // TODO: Perhaps move some of the ContentView logic into this - Ex: centering UI, full screen
        // print("applicationDidBecomeActive")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Utils().centerNudge()
        // print("applicationDidFinishLaunching")
        
        // Observe all notifications generated by the default NotificationCenter
        //        nc.addObserver(forName: nil, object: nil, queue: nil) { notification in
        //            print("NotificationCenter: \(notification.name.rawValue), Object: \(notification)")
        //        }
        //        // Observe all notifications generated by the default DistributedNotificationCenter - No longer works as of Catalina
        //        dnc.addObserver(forName: nil, object: nil, queue: nil) { notification in
        //            print("DistributedNotificationCenter: \(notification.name.rawValue), Object: \(notification)")
        //        }
        
        // Observe screen locking. Maybe useful later
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { notification in
            nudgePrimaryState.screenCurrentlyLocked = true
            utilsLog.info("\("Screen was locked", privacy: .public)")
        }
        
        nc.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main)
        {
            notification -> Void in
            print("Screen parameters changed - Notification Center")
            Utils().centerNudge()
        }

        nc.addObserver(
            forName: NSWindow.didChangeScreenProfileNotification,
            object: NSApplication.shared,
            queue: .main)
        {
            notification -> Void in
            print("Display has changed profiles - Notification Center")
            Utils().centerNudge()
        }
        
        nc.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: NSApplication.shared,
            queue: .main)
        {
            notification -> Void in
            print("Window object frame moved - Notification Center")
            Utils().centerNudge()
        }
        
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { notification in
            nudgePrimaryState.screenCurrentlyLocked = false
            utilsLog.info("\("Screen was unlocked", privacy: .public)")
        }
        
        // Entering/leaving/exiting a full screen app or space
        snc.addObserver(
            self,
            selector: #selector(spacesStateChanged(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        
        snc.addObserver(
            self,
            selector: #selector(logHiddenApplication(_:)),
            name: NSWorkspace.didHideApplicationNotification,
            object: nil
        )
        
        if attemptToBlockApplicationLaunches {
            registerLocal()
            if !nudgeLogState.afterFirstLaunch && terminateApplicationsOnLaunch {
                terminateApplications()
            }
            snc.addObserver(
                self,
                selector: #selector(terminateApplicationSender(_:)),
                name: NSWorkspace.didLaunchApplicationNotification,
                object: nil
            )
        }
        
        // Listen for keyboard events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.detectBannedShortcutKeys(with: $0) {
                return nil
            } else {
                return $0
            }
        }
        
        if !nudgeLogState.afterFirstLaunch {
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
    }
    
    @objc func logHiddenApplication(_ notification: Notification) {
        utilsLog.info("\("Application hidden", privacy: .public)")
    }
    
    @objc func spacesStateChanged(_ notification: Notification) {
        Utils().centerNudge()
        utilsLog.info("\("Spaces state changed", privacy: .public)")
        nudgePrimaryState.afterFirstStateChange = true
    }
    
    @objc func terminateApplicationSender(_ notification: Notification) {
        utilsLog.info("\("Application launched", privacy: .public)")
        terminateApplications()
    }
    
    func terminateApplications() {
        if !Utils().pastRequiredInstallationDate() {
            return
        }
        utilsLog.info("\("Application launched", privacy: .public)")
        for runningApplication in NSWorkspace.shared.runningApplications {
            let appBundleID = runningApplication.bundleIdentifier ?? ""
            let appName = runningApplication.localizedName ?? ""
            if appBundleID == "com.github.macadmins.Nudge" {
                continue
            }
            if blockedApplicationBundleIDs.contains(appBundleID) {
                utilsLog.info("\("Found \(appName), terminating application", privacy: .public)")
                scheduleLocal(applicationIdentifier: appName)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001, execute: {
                    runningApplication.forceTerminate()
                })
            }
        }
    }
    
    @objc func registerLocal() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .provisional, .sound]) { (granted, error) in
            if granted {
                uiLog.info("\("User granted notifications - application blocking status now available", privacy: .public)")
            } else {
                uiLog.info("\("User denied notifications - application blocking status will be unavailable", privacy: .public)")
            }
        }
    }
    
    @objc func scheduleLocal(applicationIdentifier: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (settings) in
            let content = UNMutableNotificationContent()
            content.title = "Application terminated".localized(desiredLanguage: getDesiredLanguage())
            content.subtitle = "(\(applicationIdentifier))"
            content.body = "Please update your device to use this application".localized(desiredLanguage: getDesiredLanguage())
            content.categoryIdentifier = "alert"
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.001, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            switch settings.authorizationStatus {
                    
                case .authorized:
                    center.add(request)
                case .denied:
                    uiLog.info("\("Application terminated without user notification", privacy: .public)")
                case .notDetermined:
                    uiLog.info("\("Application terminated without user notification status", privacy: .public)")
                case .provisional:
                    uiLog.info("\("Application terminated with provisional user notification status", privacy: .public)")
                    center.add(request)
                @unknown default:
                    uiLog.info("\("Application terminated with unknown user notification status", privacy: .public)")
            }
        }
    }
    
    func detectBannedShortcutKeys(with event: NSEvent) -> Bool {
        // Only detect shortcut keys if Nudge is active - adapted from https://stackoverflow.com/questions/32446978/swift-capture-keydown-from-nsviewcontroller/40465919
        if NSApplication.shared.isActive {
            switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
                    // Disable CMD + W - closes the Nudge window and breaks it
                case [.command] where event.characters == "w":
                    uiLog.warning("\("Nudge detected an attempt to close the application via CMD + W shortcut key.", privacy: .public)")
                    return true
                    // Disable CMD + N - closes the Nudge window and breaks it
                case [.command] where event.characters == "n":
                    uiLog.warning("\("Nudge detected an attempt to create a new window via CMD + N shortcut key.", privacy: .public)")
                    return true
                    // Disable CMD + M - closes the Nudge window and breaks it
                case [.command] where event.characters == "m":
                    uiLog.warning("\("Nudge detected an attempt to minimise the application via CMD + M shortcut key.", privacy: .public)")
                    return true
                    // Disable CMD + Q - fully closes Nudge
                case [.command] where event.characters == "q":
                    uiLog.warning("\("Nudge detected an attempt to close the application via CMD + Q shortcut key.", privacy: .public)")
                    return true
                    // Disable CMD + Option + M - minimizes Nudge and could render it broken when blur is enabled
                case [.command, .option] where event.characters == "µ":
                    uiLog.warning("\("Nudge detected an attempt to minimise the application via CMD + Option + M shortcut key.", privacy: .public)")
                    return true
                    // Disable CMD + Option + N - Opens new tabs in Nudge and breaks UI
                case [.command, .option] where event.characters == "~":
                    uiLog.warning("\("Nudge detected an attempt add tabs to the application via CMD + Option + N shortcut key.", privacy: .public)")
                    return true
                    // Don't care about any other shortcut keys
                default:
                    return false
            }
        }
        return false
    }
    
    // Only exit if primaryQuitButton is clicked
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if nudgePrimaryState.shouldExit {
            return NSApplication.TerminateReply.terminateNow
        } else {
            uiLog.warning("\("Nudge detected an attempt to exit the application.", privacy: .public)")
            return NSApplication.TerminateReply.terminateCancel
        }
    }
    
    func runSoftwareUpdate() {
        if Utils().demoModeEnabled() || Utils().unitTestingEnabled() {
            return
        }
        
        if asynchronousSoftwareUpdate && Utils().requireMajorUpgrade() == false && !Utils().pastRequiredInstallationDate() {
            DispatchQueue(label: "nudge-su", attributes: .concurrent).asyncAfter(deadline: .now(), execute: {
                SoftwareUpdate().Download()
            })
        } else {
            SoftwareUpdate().Download()
        }
    }
    
    // Pre-Launch Logic
    func applicationWillFinishLaunching(_ notification: Notification) {
        // print("applicationWillFinishLaunching")
        if #available(macOS 13, *) {
            let appService = SMAppService.agent(plistName: "com.github.macadmins.Nudge.plist")
            let appServiceStatus = appService.status
            if CommandLine.arguments.contains("--register") || loadLaunchAgent {
                Utils().loadSMAppLaunchAgent(appService: appService, appServiceStatus: appServiceStatus)
            } else if CommandLine.arguments.contains("--unregister") || !loadLaunchAgent {
                Utils().unloadSMAppLaunchAgent(appService: appService, appServiceStatus: appServiceStatus)
            }
        }
        
        if FileManager.default.fileExists(atPath: "/Library/Managed Preferences/com.github.macadmins.Nudge.json.plist") {
            prefsProfileLog.warning("\("Found bad profile path at /Library/Managed Preferences/com.github.macadmins.Nudge.json.plist", privacy: .public)")
            exit(1)
        }
        
        if CommandLine.arguments.contains("-print-profile-config") {
            if !configProfile.isEmpty {
                print(String(data: configProfile, encoding: .utf8) as AnyObject)
            }
            exit(0)
        } else if CommandLine.arguments.contains("-print-json-config") {
            if !configJSON.isEmpty {
                print(String(decoding: configJSON, as: UTF8.self))
            }
            exit(0)
        }
        
        _ = Utils().gracePeriodLogic()
        
        if nudgePrimaryState.shouldExit {
            exit(0)
        }
        
        if randomDelay {
            let randomDelaySeconds = Int.random(in: 1...maxRandomDelayInSeconds)
            uiLog.notice("Delaying initial run (in seconds) by: \(String(randomDelaySeconds), privacy: .public)")
            sleep(UInt32(randomDelaySeconds))
        }
        
        self.runSoftwareUpdate()
        if Utils().requireMajorUpgrade() {
            if actionButtonPath != nil {
                if !actionButtonPath!.isEmpty {
                    return
                } else {
                    prefsProfileLog.warning("\("actionButtonPath contains empty string - actionButton will be unable to trigger any action required for major upgrades", privacy: .public)")
                    return
                }
            }
            
            if attemptToFetchMajorUpgrade == true && fetchMajorUpgradeSuccessful == false && (majorUpgradeAppPathExists == false && majorUpgradeBackupAppPathExists == false) {
                uiLog.error("\("Unable to fetch major upgrade and application missing, exiting Nudge", privacy: .public)")
                nudgePrimaryState.shouldExit = true
                exit(1)
            } else if attemptToFetchMajorUpgrade == false && (majorUpgradeAppPathExists == false && majorUpgradeBackupAppPathExists == false) {
                uiLog.error("\("Unable to find major upgrade application, exiting Nudge", privacy: .public)")
                nudgePrimaryState.shouldExit = true
                exit(1)
            }
        }
    }
    
    class WindowDelegate: NSObject, NSWindowDelegate {
        func windowDidMove(_ notification: Notification) {
            print("Window attempted to move - Window Delegate")
            Utils().centerNudge()
        }
        func windowDidChangeScreen(_ notification: Notification) {
            print("Window moved screens - Window Delegate")
            Utils().centerNudge()
        }
        func windowDidChangeScreenProfile(_ notification: Notification) {
            print("Display has changed profiles - Window Delegate")
            Utils().centerNudge()
        }
    }
}

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

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            StandardMode()
                .environmentObject(nudgePrimaryState)
                .previewLayout(.fixed(width: declaredWindowWidth, height: declaredWindowHeight))
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("StandardMode (\(id))")
        }
        ForEach(["en", "es"], id: \.self) { id in
            SimpleMode()
                .environmentObject(nudgePrimaryState)
                .previewLayout(.fixed(width: declaredWindowWidth, height: declaredWindowHeight))
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("SimpleMode (\(id))")
        }
    }
}
#endif
