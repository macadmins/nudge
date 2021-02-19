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
        VStack{
            // Company Logo
            if colorScheme == .dark {
                if FileManager.default.fileExists(atPath: iconDarkPath) {
                    Image(nsImage: Utils().createImageData(fileImagePath: iconDarkPath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 300, height: 225)
                } else {
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 200, height: 150)
                        .padding(.vertical, 50)
                }
            } else {
                if FileManager.default.fileExists(atPath: iconLightPath) {
                    Image(nsImage: Utils().createImageData(fileImagePath: iconLightPath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 300, height: 225)
                        .padding(.vertical, 2)
                } else {
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 200, height: 150)
                        .padding(.vertical, 50)
                }
            }
            
            // mainHeader
            HStack {
                Text(getMainHeader())
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 2)
            
            // Days Remaining
            HStack {
                Text("Days remaining to update:")
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
            .padding(.vertical, 2)
            
            // Ignored Count
            HStack{
                Text("Ignored Count:")
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
            .padding(.vertical, 2)
            
            // actionButton
            Button(action: Utils().updateDevice, label: {
                Text(actionButtonText)
                    .frame(minWidth: 120)
            }
            )
            .keyboardShortcut(.defaultAction)
            .padding(.vertical, 2)
            
            Spacer()
            
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
                    .help("Click for more information about the security update")
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .padding(.leading, 20)
                }
                
                // Separate the buttons with a spacer
                Spacer()
                
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
                                Utils().exitNudge()
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
                            Utils().exitNudge()
                        } label: {
                            Text(primaryQuitButtonText)
                                .frame(minWidth: 35)
                        }
                    }
                }
            }
            // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
            .padding(.trailing, 20)
            .padding(.bottom, 15)
            .onAppear(perform: nudgeStartLogic)
        }
        .frame(width: 900, height: 450)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct SimpleModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                SimpleMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            SimpleMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
