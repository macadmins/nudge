//
//  Defaults.swift
//  Nudge
//
//  Created by Erik Gomez on 6/13/23.
//

import Foundation
import UserNotifications
import SwiftUI

// State
var globals = Globals()
var uiConstants = UIConstants()
var nudgePrimaryState = AppState()
var nudgeLogState = LogState()

struct Globals {
    static let bundle = Bundle.main
    static let bundleID = bundle.bundleIdentifier ?? "com.github.macadmins.Nudge"
    static let dnc = DistributedNotificationCenter.default()
    static let nc = NotificationCenter.default
    static let snc = NSWorkspace.shared.notificationCenter
    // Preferences
    static let configJSON = ConfigurationManager().getConfigurationAsJSON()
    static let configProfile = ConfigurationManager().getConfigurationAsProfile()
    static let nudgeDefaults = UserDefaults.standard
    static let nudgeJSONPreferences = NetworkFileManager().getNudgeJSONPreferences()
    // Device Properties
    static let gdmfAssets = NetworkFileManager().getGDMFAssets()
    static let sofaAssets = NetworkFileManager().getSOFAAssets()
    static let hardwareModelID = DeviceManager().getHardwareModelID()
}

struct Intervals {
    static let dayTimeInterval: CGFloat = 86400
    static let hourTimeInterval: CGFloat = 3600
    // Setup the main refresh timer that controls the child refresh logic
    static let nudgeRefreshCycleTimer = Timer.publish(every: Double(UserExperienceVariables.nudgeRefreshCycle), on: .main, in: .common).autoconnect()
}

struct UIConstants {
    static let bottomPadding: CGFloat = 10
    static let buttonTextMinWidth: CGFloat = 35
    static let contentWidthPadding: CGFloat = 25
    static let DNDServer = Bundle(path: "/System/Library/PrivateFrameworks/DoNotDisturbServer.framework")?.load() ?? false // Idea from https://github.com/saagarjha/vers/blob/d9460f6e14311e0a90c4c171975c93419481586b/vers/Headers.swift
    static let languageCode = NSLocale.current.languageCode!
    static let languageID = Locale.current.identifier
    static let leftSideWidth: CGFloat = 300
    static let screens = NSScreen.screens
    static let screenshotMaxHeight: CGFloat = 120
    static let screenshotTopPadding: CGFloat = 28
    static let serialNumber = DeviceManager().getSerialNumber()
    static let windowDelegate = WindowDelegate()

    var declaredWindowHeight: CGFloat = 450
    var declaredWindowWidth: CGFloat = 900
    var demoModeArgumentPassed = false
    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" // https://zacwhite.com/2020/detecting-swiftui-previews/
    }
    var logoHeight: CGFloat = 150
    var logoWidth: CGFloat = 200
    var unitTestingArgumentPassed = false
}

class AppState: ObservableObject {
    @Published var activelyExploitedCVEs = false
    @Published var afterFirstStateChange = false
    @Published var allowButtons = true
    @Published var daysRemaining = DateManager().getNumberOfDaysBetween()
    @Published var deferralCountPastThreshold = false
    @Published var deferRunUntil = Globals.nudgeDefaults.object(forKey: "deferRunUntil") as? Date
    @Published var deviceSupportedByOSVersion = true
    @Published var hasClickedSecondaryQuitButton = false
    @Published var hasLoggedDeferralCountPastThreshold = false
    @Published var hasLoggedDeferralCountPastThresholdDualQuitButtons = false
    @Published var hasLoggedRequireDualQuitButtons = false
    @Published var hoursRemaining = DateManager().getNumberOfHoursRemaining()
    @Published var lastRefreshTime = DateManager().getFormattedDate()
    @Published var requireDualQuitButtons = false
    @Published var requiredMinimumOSVersion = OSVersionRequirementVariables.requiredMinimumOSVersion
    @Published var shouldExit = false
    @Published var timerCycle = 0
    @Published var userDeferrals = Globals.nudgeDefaults.object(forKey: "userDeferrals") as? Int ?? 0
    @Published var userQuitDeferrals = Globals.nudgeDefaults.object(forKey: "userQuitDeferrals") as? Int ?? 0
    @Published var userRequiredMinimumOSVersion = Globals.nudgeDefaults.object(forKey: "requiredMinimumOSVersion") as? String ?? "0.0"
    @Published var userSessionDeferrals = Globals.nudgeDefaults.object(forKey: "userSessionDeferrals") as? Int ?? 0
    @Published var backgroundBlur = [BackgroundBlurWindowController]()
    @Published var screenCurrentlyLocked = false
    @Published var locale = Locale.current
    @Published var nudgeCustomEventDate = DateManager().getCurrentDate()
    @Published var nudgeEventDate = DateManager().getCurrentDate()
    @Published var screenShotZoomViewIsPresented = false
    @Published var deferViewIsPresented = false
    @Published var additionalInfoViewIsPresented = false
    @Published var differentiateWithoutColor = NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
}

class DNDConfig {
    static let rawType = NSClassFromString("DNDSAuxiliaryStateMonitor") as? NSObject.Type
    let rawValue: NSObject?

    init() {
        if let rawType = Self.rawType {
            self.rawValue = rawType.init()
        } else {
            self.rawValue = nil
            LogManager.error("DNDSAuxiliaryStateMonitor class could not be found.", logger: utilsLog)
        }
    }

    required init?(rawValue: NSObject?) {
        guard let rawType = Self.rawType, let unwrappedRawValue = rawValue, unwrappedRawValue.isKind(of: rawType) else {
            LogManager.error("Initialization with rawValue failed.", logger: utilsLog)
            return nil
        }
        self.rawValue = unwrappedRawValue
    }
}
