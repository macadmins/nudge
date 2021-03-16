//
//  SimpleMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// SimpleMode
struct SimpleMode: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: PolicyManager
    
    // State variables
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    @State var requireDualQuitButtons = Utils().requireDualQuitButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasClickedSecondaryQuitButton = false
    @State var deferralCountUI = 0
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let companyLogoPath = Utils().getCompanyLogoPath(darkMode: darkMode)
        VStack {
            VStack(alignment: .center, spacing: 10) {
                // Company Logo
                HStack {
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
                .frame(width: 300, height: 225)

                // mainHeader
                HStack {
                    Text(getMainHeader())
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Days Remaining
                HStack {
                    Text("Days remaining to update:".localized(desiredLanguage: getDesiredLanguage()))
                        .font(.title2)
                    if self.daysRemaining <= 0 {
                        Text(String(0))
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text(String(self.daysRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }

                // Deferred Count
                HStack {
                    Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                        .font(.title2)
                    Text(String(self.deferralCountUI))
                        .font(.title2)
                        .fontWeight(.bold)
                        .onReceive(nudgeRefreshCycleTimer) { _ in
                            if needToActivateNudge(deferralCountVar: deferralCount, lastRefreshTimeVar: lastRefreshTime) {
                                self.deferralCountUI += 1
                            }
                        }
                }

                // actionButton
                Button(action: {
                    Utils().updateDevice()
                }) {
                    Text(actionButtonText)
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
            }
            .frame(height: 390)
            
            // Bottom buttons
            HStack {
                // informationButton
                if aboutUpdateURL != "" {
                    Button(action: Utils().openMoreInfo, label: {
                        Text(informationButtonText)
                            .foregroundColor(.secondary)
                    }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .help("Click for more information about the security update".localized(desiredLanguage: getDesiredLanguage()))
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

                // Separate the buttons with a spacer
                Spacer()
                
                #if DEBUG
                Button {
                    Utils().userInitiatedExit()
                } label: {
                    Text(primaryQuitButtonText)
                        .frame(minWidth: 35)
                }
                #endif

                if Utils().demoModeEnabled() || !pastRequiredInstallationDate && allowedDeferrals > self.deferralCountUI {
                    // secondaryQuitButton
                    if requireDualQuitButtons {
                        if self.hasClickedSecondaryQuitButton {
                            Button {} label: {
                                Text(secondaryQuitButtonText)
                            }
                            .hidden()
                        } else {
                            Button {
                                hasClickedSecondaryQuitButton = true
                                userHasClickedSecondaryQuitButton()
                            } label: {
                                Text(secondaryQuitButtonText)
                            }
                        }
                    } else {
                        Button(action: {}, label: {
                            Text(secondaryQuitButtonText)
                        }
                        )
                        .hidden()
                    }
                    
                    // primaryQuitButton
                    if requireDualQuitButtons {
                        if self.hasClickedSecondaryQuitButton {
                            Button {
                                Utils().userInitiatedExit()
                            } label: {
                                Text(primaryQuitButtonText)
                                    .frame(minWidth: 35)
                            }
                        } else {
                            Button {
                                hasClickedSecondaryQuitButton = true
                                userHasClickedSecondaryQuitButton()
                            } label: {
                                Text(primaryQuitButtonText)
                                    .frame(minWidth: 35)
                            }
                            .hidden()
                        }
                    } else {
                        Button {
                            Utils().userInitiatedExit()
                        } label: {
                            Text(primaryQuitButtonText)
                                .frame(minWidth: 35)
                        }
                    }
                }
            }
            .frame(width: 860)
            // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
        }
        .frame(width: 900, height: 450)
        .onAppear(perform: nudgeStartLogic)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct SimpleModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                SimpleMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2")))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            SimpleMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2")))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
