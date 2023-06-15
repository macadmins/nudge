//
//  Defaults.swift
//  Nudge
//
//  Created by Erik Gomez on 6/13/23.
//

import Foundation
import UserNotifications
import SwiftUI

// Generics
let bundle = Bundle.main
let bundleID = bundle.bundleIdentifier ?? "com.github.macadmins.Nudge"
let dnc = DistributedNotificationCenter.default()
let nc = NotificationCenter.default
let snc = NSWorkspace.shared.notificationCenter

// Intervals
let dayTimeInterval: CGFloat = 86400
let hourTimeInterval: CGFloat = 3600
let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect() // Setup the main refresh timer that controls the child refresh logic

// Preferences
let configJSON = Utils().getConfigurationAsJSON()
let configProfile = Utils().getConfigurationAsProfile()
let nudgeDefaults = UserDefaults.standard
let nudgeJSONPreferences = Utils().getNudgeJSONPreferences()

// State
var demoModeArgumentPassed = false
let DNDServer = Bundle(path: "/System/Library/PrivateFrameworks/DoNotDisturbServer.framework")?.load() ?? false // Idea from https://github.com/saagarjha/vers/blob/d9460f6e14311e0a90c4c171975c93419481586b/vers/Headers.swift
var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" // https://zacwhite.com/2020/detecting-swiftui-previews/
}
var nudgePrimaryState = AppState()
var nudgeLogState = LogState()
let serialNumber = Utils().getSerialNumber()
var unitTestingArgumentPassed = false

// UI
let bottomPadding: CGFloat = 10
let buttonTextMinWidth: CGFloat = 35
let contentWidthPadding: CGFloat = 25
var declaredWindowHeight: CGFloat = 450
var declaredWindowWidth: CGFloat = 900
let languageCode = NSLocale.current.languageCode!
let languageID = Locale.current.identifier
let leftSideWidth: CGFloat = 300
var logoHeight: CGFloat = 150
var logoWidth: CGFloat = 200
let screens = NSScreen.screens
let screenshotMaxHeight: CGFloat = 120
let screenshotTopPadding: CGFloat = 28
let windowDelegate = AppDelegate.WindowDelegate()

class AppState: ObservableObject {
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
    @Published var backgroundBlur = [BackgroundBlurWindowController]()
    @Published var screenCurrentlyLocked = false
    @Published var locale = Locale.current
    @Published var nudgeCustomEventDate = Utils().getCurrentDate()
    @Published var nudgeEventDate = Utils().getCurrentDate()
    @Published var screenShotZoomViewIsPresented = false
    @Published var deferViewIsPresented = false
    @Published var additionalInfoViewIsPresented = false
    @Published var differentiateWithoutColor = NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
}

class DNDConfig {
    static let rawType = NSClassFromString("DNDSAuxiliaryStateMonitor") as? NSObject.Type ?? nil
    let rawValue: NSObject?
    
    init() {
        self.rawValue = Self.rawType == nil ? nil : (Self.rawType!).init()
    }
    
    required init(rawValue: NSObject?) {
        guard rawValue!.isKind(of: Self.rawType!) else { fatalError() }
        self.rawValue = rawValue == nil ? nil : rawValue
    }
}
