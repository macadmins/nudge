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
    
    // Modal view for screenshot and device info
    @State var showDeviceInfo = false
    
    let logowidth  : CGFloat = 200
    let logoheight : CGFloat = 150
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let companyLogoPath = Utils().getCompanyLogoPath(darkMode: darkMode)
        // Left side of Nudge
        GeometryReader { geometry in
            VStack {
                VStack(alignment: .center, spacing: 20) {
                    HStack {
                        Button(action: {
                            Utils().userInitiatedDeviceInfo()
                            self.showDeviceInfo.toggle()
                        }) {
                            Image(systemName: "questionmark.circle")
                        }
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

                    // Company Logo
                    Group {
                        if FileManager.default.fileExists(atPath: companyLogoPath) {
                            Image(nsImage: Utils().createImageData(fileImagePath: companyLogoPath))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: logowidth, height: logoheight)
                        } else {
                            Image(systemName: "applelogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: logowidth, height: logoheight)
                        }
                    }

                    // Horizontal line
                    HStack{
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                    }
                    .frame(width: geometry.size.width*0.8)

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
                            if viewObserved.daysRemaining <= 0 && !Utils().demoModeEnabled() {
                                Text(String(viewObserved.daysRemaining))
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            } else {
                                Text(String(viewObserved.daysRemaining))
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
                    .frame(width: geometry.size.width*0.8)
                }

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
                .frame(width: geometry.size.width*0.8)
                .offset(y: 15)
            }
        }
        .frame(width: 280, alignment: .center)
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

