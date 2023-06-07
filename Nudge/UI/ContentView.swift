//
//  ContentView.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

// https://stackoverflow.com/a/66039864
// https://gist.github.com/steve228uk/c960b4880480c6ed186d

let screens = NSScreen.screens

class ViewState: ObservableObject {
    @Published var afterFirstStateChange = false
    @Published var allowButtons = true
    @Published var daysRemaining = Utils().getNumberOfDaysBetween()
    @Published var deferralCountPastThreshhold = false
    @Published var deferRunUntil = nudgeDefaults.object(forKey: "deferRunUntil") as? Date
    @Published var hasClickedSecondaryQuitButton = false
    @Published var hasLoggedDeferralCountPastThreshhold = false
    @Published var hasLoggedDeferralCountPastThresholdDualQuitButtons = false
    @Published var hasLoggedRequireDualQuitButtons = false
    @Published var hoursRemaining = Utils().getNumberOfHoursRemaining()
    @Published var lastRefreshTime = Utils().getFormattedDate()
    @Published var requireDualQuitButtons = false
    @Published var shouldExit = false
    @Published var timerCycle = 0
    @Published var userDeferrals = nudgeDefaults.object(forKey: "userDeferrals") as? Int ?? 0
    @Published var userQuitDeferrals = nudgeDefaults.object(forKey: "userQuitDeferrals") as? Int ?? 0
    @Published var userRequiredMinimumOSVersion = nudgeDefaults.object(forKey: "requiredMinimumOSVersion") as? String ?? "0.0"
    @Published var userSessionDeferrals = nudgeDefaults.object(forKey: "userSessionDeferrals") as? Int ?? 0
    @Published var blurredBackground =  [BlurWindowController]()
    @Published var screenCurrentlyLocked = false
}

class LogState {
    var afterFirstLaunch = false
    var afterFirstRun = false
    var hasLoggedBundleMode = false
    var hasLoggedDemoMode = false
    var hasLoggedMajorOSVersion = false
    var hasLoggedMajorRequiredOSVersion = false
    var hasLoggedPastRequiredInstallationDate = false
    var hasLoggedRequireMajorUgprade = false
    var hasLoggedScreenshotIconMode = false
    var hasLoggedSimpleMode = false
    var hasLoggedUnitTestingMode = false
}

// BackgroundView
struct BackgroundView: View {
    var forceSimpleMode: Bool = false
    @ObservedObject var viewObserved: ViewState
    var body: some View {
        if simpleMode() || forceSimpleMode {
            SimpleMode(viewObserved: viewObserved)
        } else {
            StandardMode(viewObserved: viewObserved)
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewObserved: ViewState
    var forceSimpleMode: Bool = false
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    var body: some View {
        BackgroundView(forceSimpleMode: forceSimpleMode, viewObserved: viewObserved).background(
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
                viewObserved.userSessionDeferrals += 1
                viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
            }
            updateUI()
        }
    }
    
    func updateUI() {
        if Utils().requireDualQuitButtons() || viewObserved.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
            viewObserved.requireDualQuitButtons = true
        }
        if Utils().pastRequiredInstallationDate() || viewObserved.deferralCountPastThreshhold {
            viewObserved.allowButtons = false
        }
        viewObserved.daysRemaining = Utils().getNumberOfDaysBetween()
        viewObserved.hoursRemaining = Utils().getNumberOfHoursRemaining()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            StandardMode(viewObserved: nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
        }
        ForEach(["en", "es"], id: \.self) { id in
            SimpleMode(viewObserved: nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
        }
    }
}
#endif

struct HostingWindowFinder: NSViewRepresentable {
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
