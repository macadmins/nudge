//
//  RightSide.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// StandardModeRightSide
struct StandardModeRightSide: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    // State variables
    @State var allowButtons = true
    @State var hasClickedCustomDeferralButton = false
    @State var hasClickedSecondaryQuitButton = false
    @State var requireDualQuitButtons = false
    @State var nudgeEventDate = Date()
    @State var nudgeCustomEventDate = Date()
    
    // Modal view for screenshot and device info
    @State var showSSDetail = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let screenShotPath = Utils().getScreenShotPath(darkMode: darkMode)
        // Right side of Nudge
        VStack {
            // mainHeader
            VStack(alignment: .center) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        // mainHeader
                        HStack {
                            Text(getMainHeader())
                                .font(.largeTitle)
                                .minimumScaleFactor(0.5)
                                .frame(maxHeight: 25)
                                .lineLimit(1)
                        }
                        // subHeader
                        HStack {
                            Text(subHeader)
                                .font(.body)
                                .fontWeight(.bold)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
            .frame(width: 510)
            
            // I'm kind of impressed with myself
            VStack {
                Spacer()
                    .frame(height: 10)
                // mainContentHeader / mainContentSubHeader
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(mainContentHeader)
                                 .font(.callout)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        HStack {
                            Text(mainContentSubHeader)
                                .font(.callout)
                            Spacer()
                        }
                    }
                    Spacer()
                    // actionButton
                    Button(action: {
                        Utils().updateDevice()
                    }) {
                        Text(actionButtonText)
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .frame(width: 510)
                
                // Horizontal line
                HStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                .frame(width: 510)
                
                // mainContentNote
                HStack {
                    Text(mainContentNote)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(Color.red)
                    Spacer()
                }
                .frame(width: 510)
                
                // mainContentText
                HStack {
                    Text(mainContentText.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.callout)
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .frame(minHeight: 125.0)
                .frame(maxHeight: 125.0)
                .frame(width: 510)
                
                HStack {
                    Spacer()
                    // screenShot
                    if FileManager.default.fileExists(atPath: screenShotPath) {
                        Button {
                            self.showSSDetail.toggle()
                        } label: {
                            Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 120)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage()))
                        .sheet(isPresented: $showSSDetail) {
                            ScreenShotZoom()
                        }
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    } else {
                        if forceScreenShotIconMode() {
                            Button {
                                self.showSSDetail.toggle()
                            } label: {
                                Image("CompanyScreenshotIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 120)
                            }
                            .buttonStyle(.plain)
                            .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage()))
                            .sheet(isPresented: $showSSDetail) {
                                ScreenShotZoom()
                            }
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        } else {
                            Button {
                                self.showSSDetail.toggle()
                            } label: {
                                Image("CompanyScreenshotIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 120)
                            }
                            .buttonStyle(.plain)
                            .hidden()
                            .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage()))
                            .sheet(isPresented: $showSSDetail) {
                                ScreenShotZoom()
                            }
                        }
                    }
                    Spacer()
                }
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(5)
            .frame(width: 550, height: 350)
                
            // Bottom buttons
            HStack {
                // Separate the buttons with a spacer
                Spacer()
                
                if allowButtons || Utils().demoModeEnabled() {
                    // secondaryQuitButton
                    if requireDualQuitButtons {
                        if self.hasClickedSecondaryQuitButton == false {
                            Button {
                                hasClickedSecondaryQuitButton = true
                                userHasClickedSecondaryQuitButton()
                            } label: {
                                Text(secondaryQuitButtonText)
                            }
                            .padding(.leading, -200.0)
                        }
                    }
                    
                    // primaryQuitButton
                    if requireDualQuitButtons == false || self.hasClickedSecondaryQuitButton {
                        HStack(spacing: 20) {
                            if hasClickedCustomDeferralButton == false {
                                Menu("Defer") {
                                    Button {
                                        // Always go back a day to trigger Nudge every time user hits this button
                                        nudgeDefaults.set(Calendar.current.date(byAdding: .minute, value: -(1440), to: nudgeEventDate), forKey: "deferRunUntil")
                                        Utils().userInitiatedExit()
                                    } label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                    }
                                    if Utils().allow1HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(3600), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(3600))
                                            Utils().userInitiatedExit()
                                        } label: {
                                            Text("One Hour")
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allow24HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(86400), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(86400))
                                            Utils().userInitiatedExit()
                                        } label: {
                                            Text("One Day")
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allowCustomDeferral() {
                                        Button {
                                            hasClickedCustomDeferralButton = true
                                        } label: {
                                            Text("Custom")
                                                .frame(minWidth: 35)
                                        }
                                    }
                                }
                                .frame(maxWidth: 100)
                            }
                            if hasClickedCustomDeferralButton {
                                DatePicker("Please enter a time", selection: $nudgeCustomEventDate, in: limitRange)
                                    .labelsHidden()
                                    .frame(maxWidth: 150)
                                Button {
                                    nudgeDefaults.set(nudgeCustomEventDate, forKey: "deferRunUntil")
                                    userHasClickedDeferralQuitButton(deferralTime: nudgeCustomEventDate)
                                    Utils().userInitiatedExit()
                                } label: {
                                    Text("Defer")
                                        .frame(minWidth: 35)
                                }
                            }
                        }
                        .frame(maxHeight: 30)
                    }
                }
            }
            .frame(width: 510)
        }
        .frame(width: 600, height: 450)
        .onReceive(nudgeRefreshCycleTimer) { _ in
            updateUI()
        }
        .onAppear() {
            updateUI()
        }
    }
    
    var limitRange: ClosedRange<Date> {
        let daysRemaining = Utils().getNumberOfDaysBetween()
        if daysRemaining > 0 {
            // Do not let the user defer past the point of the approachingWindowTime
            return Date()...Calendar.current.date(byAdding: .day, value: daysRemaining-(imminentWindowTime / 24), to: Date())!
        } else {
            return Date()...Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        }
    }
    
    func updateUI() {
        if Utils().requireDualQuitButtons() || hasLoggedDeferralCountPastThresholdDualQuitButtons {
            self.requireDualQuitButtons = true
        }
        if Utils().pastRequiredInstallationDate() || hasLoggedDeferralCountPastThreshold {
            self.allowButtons = false
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeRightSidePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardModeRightSide()
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            StandardModeRightSide()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
