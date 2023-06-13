//
//  Defaults.swift
//  Nudge
//
//  Created by Erik Gomez on 6/13/23.
//

import Foundation
import UserNotifications
import SwiftUI

let windowDelegate = AppDelegate.WindowDelegate()
let dnc = DistributedNotificationCenter.default()
let nc = NotificationCenter.default
let snc = NSWorkspace.shared.notificationCenter
let bundle = Bundle.main
let serialNumber = Utils().getSerialNumber()
let configJSON = Utils().getConfigurationAsJSON()
let configProfile = Utils().getConfigurationAsProfile()
let screens = NSScreen.screens

// Pixels for Nudge UI
var declaredWindowHeight: CGFloat = 450
var declaredWindowWidth: CGFloat = 900
let leftSideWidth: CGFloat = 300
let bottomPadding: CGFloat = 10
let contentWidthPadding: CGFloat = 25
var logoWidth: CGFloat = 200
var logoHeight: CGFloat = 150
let buttonTextMinWidth: CGFloat = 35
let screenshotTopPadding: CGFloat = 28
let screenshotMaxHeight: CGFloat = 120

// Intervals
let hourTimeInterval: CGFloat = 3600
let dayTimeInterval: CGFloat = 86400
// Setup the main refresh timer that controls the child refresh logic
let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

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
    @Published var colorScheme = ColorScheme.light
    @Published var nudgeCustomEventDate = Utils().getCurrentDate()
    @Published var nudgeEventDate = Utils().getCurrentDate()
    @Published var screenShotZoomViewIsPresented = false
    @Published var deferViewIsPresented = false
    @Published var additionalInfoViewIsPresented = false
    @Published var differentiateWithoutColor = NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
}
