//
//  LeftSide.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// StandardModeLeftSide
struct StandardModeLeftSide: View {
    @ObservedObject var viewObserved: ViewState
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    
    // State variables
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    
    // Modal view for screenshot and device info
    @State var showDeviceInfo = false
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let companyLogoPath = Utils().getCompanyLogoPath(darkMode: darkMode)
        // Left side of Nudge
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Button(action: {
                    Utils().userInitiatedDeviceInfo()
                    self.showDeviceInfo.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                }
                .padding(.leading, -3.5)
                .padding(.top, 1.0)
                .buttonStyle(.plain)
                .help("Click for additional device information".localized(desiredLanguage: getDesiredLanguage()))
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .sheet(isPresented: $showDeviceInfo) {
                    DeviceInfo()
                }
                Spacer()
            }
            .frame(width: 290)

            // Company Logo
            Group {
                if FileManager.default.fileExists(atPath: companyLogoPath) {
                    Image(nsImage: Utils().createImageData(fileImagePath: companyLogoPath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 200, height: 150)
                } else {
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 200, height: 150)
                }
            }
            .frame(width: 250)

            // Horizontal line
            HStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 1)
            }
            .frame(width: 230)

            VStack(alignment: .center, spacing: 10) {
                // Required OS Version
                HStack{
                    Text("Required OS Version:".localized(desiredLanguage: getDesiredLanguage()))
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(requiredMinimumOSVersion))
                        .foregroundColor(.secondary)
                        .fontWeight(.bold)
                }

                // Current OS Version
                HStack{
                    Text("Current OS Version:".localized(desiredLanguage: getDesiredLanguage()))
                    Spacer()
                    Text(currentOSVersion)
                        .foregroundColor(.secondary)
                }

                // Days Remaining
                HStack{
                    Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                    Spacer()
                    if self.daysRemaining <= 0 {
                        Text(String(self.daysRemaining))
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    } else {
                        Text(String(self.daysRemaining))
                            .foregroundColor(.secondary)
                    }
                }

                // Deferred Count
                // Show by default, allow to be hidden via preference
                if showDeferralCount {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                        Spacer()
                        Text(String(viewObserved.userDeferrals))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 250)

            // Force buttons to the bottom with a spacer
            Spacer()

            // More Info
            HStack {
                // informationButton
                if aboutUpdateURL != "" {
                    Button(action: Utils().openMoreInfo, label: {
                        Text(informationButtonText)
                            .foregroundColor(.secondary)
                    }
                    )
                        .buttonStyle(.plain)
                    .help("Click for more information about the security update".localized(desiredLanguage: getDesiredLanguage()))
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                }
                // Force the button to the left with a spacer
                Spacer()
            }
            .padding(.top, 45.0)
            .frame(width: 250, height: 35)
        }
        .frame(width: 300, height: 450)
        .onAppear() {
            updateUI()
        }
        .onReceive(nudgeRefreshCycleTimer) { _ in
            if needToActivateNudge(lastRefreshTimeVar: lastRefreshTime) {
                viewObserved.userSessionDeferrals += 1
                viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
            }
            updateUI()
        }
    }
    func updateUI() {
        self.daysRemaining = Utils().getNumberOfDaysBetween()
        if Utils().requireDualQuitButtons() || viewObserved.userDeferrals > allowedDeferralsUntilForcedSecondaryQuitButton {
            viewObserved.requireDualQuitButtons = true
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeLeftSidePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardModeLeftSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                StandardModeLeftSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif

