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
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var manager: PolicyManager
    
    // State variables
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    @State var deferralCountUI = 0
    
    // Modal view for screenshot and device info
    @State var showDeviceInfo = false
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()
    
    // Nudge UI
    var body: some View {
        // Left side of Nudge
        // Additional Device Information
        VStack{
            Button(action: {
                self.showDeviceInfo.toggle()
            }) {
                Image(systemName: "questionmark.circle")
            }
            .padding(.leading, -140)
            .padding(.top, -25.0)
            .buttonStyle(PlainButtonStyle())
            // TODO: This is broken because of the padding
            .help("Click for additional device information")
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
            
            // Company Logo
            if colorScheme == .dark {
                if FileManager.default.fileExists(atPath: iconDarkPath) {
                    Image(nsImage: Utils().createImageData(fileImagePath: iconDarkPath))
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
            } else {
                if FileManager.default.fileExists(atPath: iconLightPath) {
                    Image(nsImage: Utils().createImageData(fileImagePath: iconLightPath))
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
            
            // Horizontal line
            HStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 1)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            .frame(width: 230)
            
            
            // Can only have 10 objects per stack unless you hack it and use groups
            Group {
                // Required OS Version
                HStack{
                    Text("Required OS Version:")
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(requiredMinimumOSVersion))
                        .foregroundColor(.secondary)
                        .fontWeight(.bold)
                }
                
                // Current OS Version
                HStack{
                    Text("Current OS Version:")
                    Spacer()
                    Text(manager.current.description)
                        .foregroundColor(.secondary)
                }
                
                // Days Remaining
                HStack{
                    Text("Days remaining to update:")
                    Spacer()
                    if self.daysRemaining <= 0 {
                        Text(String(0))
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(self.daysRemaining))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Ignored Count
                HStack{
                    Text("Ignored Count:")
                    Spacer()
                    Text(String(self.deferralCountUI))
                        .onReceive(nudgeRefreshCycleTimer) { _ in
                            if needToActivateNudge(deferralCountVar: deferralCount, lastRefreshTimeVar: lastRefreshTime) {
                                self.deferralCountUI += 1
                            }
                        }
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 250)
            .padding(.vertical, 0.5)
            
            // Force buttons to the bottom with a spacer
            Spacer()
            
            // More Info
            // https://developer.apple.com/documentation/swiftui/openurlaction
            HStack(alignment: .top) {
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
                    
                }
                // Force the button to the left with a spacer
                Spacer()
            }
            .frame(width: 250)
            .padding(.bottom, 17.5)
        }
        .frame(width: 300, height: 450)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeLeftSidePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                StandardModeLeftSide().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            StandardModeLeftSide().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif

