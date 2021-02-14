//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Primary Nudge UI
struct Nudge: View {
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
    
    // Modal view for screenshot and device info
    @State var showSSDetail = false
    @State var showDeviceInfo = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

    // Nudge UI
    var body: some View {
        if simpleMode() {
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
                                    AppKit.NSApp.terminate(nil)
                                } label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: 35)
                                }
                            } else {
                                Button {
                                    hasClickedSecondaryQuitButton = true
                                } label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: 35)
                                }
                                .hidden()
                            }
                        } else {
                            Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                                Text(primaryQuitButtonText)
                                    .frame(minWidth: 35)
                              }
                            )
                        }
                    }
                }
                // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
                .padding(.trailing, 20)
                .padding(.bottom, 15)
                .onAppear(perform: nudgeStartLogic)
            }
            .frame(width: 900, height: 450)
        } else {
            HStack(spacing: 0){
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
                        deviceInfo()
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
                
                // Vertical Line
                VStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1)
                }
                .frame(height: 525)

                // Right side of Nudge
                VStack{
                    Group {
                        // mainHeader
                        HStack {
                            Text(getMainHeader())
                                .font(.largeTitle)
                                .multilineTextAlignment(.leading)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Spacer()
                        }
                        // subHeader
                        HStack {
                            Text(subHeader)
                                .font(.body)
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 0.5)
                    .frame(width: 500)
                    
                    // I'm kind of impressed with myself
                    Group {
                        VStack(alignment: .leading) {
                            // mainContentHeader / mainContentSubHeader
                            HStack {
                                VStack {
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
                                Button(action: Utils().updateDevice, label: {
                                    Text(actionButtonText)
                                  }
                                )
                                .keyboardShortcut(.defaultAction)
                            }
                            .padding(.top, 20.0)
                            .padding(.leading, 20.0)
                            .padding(.trailing, 20.0)
                            
                            // Horizontal line
                            HStack{
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(height: 1)
                            }
                            .padding(.leading, 20.0)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            .frame(width: 525)
                            
                            // mainContentNote
                            HStack {
                                Text(mainContentNote)
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.red)
                                Spacer()
                            }
                            .padding(.leading, 20.0)
                            
                            // mainContentText
                            Text(mainContentText)
                                .font(.callout)
                                .font(.body)
                                .fontWeight(.regular)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 20.0)

                            HStack {
                                Spacer()
                                // screenShot
                                if colorScheme == .dark && FileManager.default.fileExists(atPath: screenShotDarkPath) {
                                    Button {
                                        self.showSSDetail.toggle()
                                    } label: {
                                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotDarkPath))
                                            .resizable()
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 128)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Click to zoom into screenshot")
                                    .sheet(isPresented: $showSSDetail) {
                                        screenShotZoom()
                                    }
                                    .onHover { inside in
                                        if inside {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                                    Button {
                                        self.showSSDetail.toggle()
                                    } label: {
                                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                                            .resizable()
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 128)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Click to zoom into screenshot")
                                    .sheet(isPresented: $showSSDetail) {
                                        screenShotZoom()
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
                                                .frame(maxHeight: 128)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Click to zoom into screenshot")
                                        .sheet(isPresented: $showSSDetail) {
                                            screenShotZoom()
                                        }
                                        .onHover { inside in
                                            if inside {
                                                NSCursor.pointingHand.push()
                                            } else {
                                                NSCursor.pop()
                                            }
                                        }
                                    } else {
                                        Text("Force a 128 pixel")
                                            .hidden()
                                            .frame(minHeight: 128)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(5)

                        // Bottom buttons
                        HStack {
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
                                        } label: {
                                            Text(secondaryQuitButtonText)
                                        }
                                    }
                                } else {
                                    Button {} label: {
                                        Text(secondaryQuitButtonText)
                                    }
                                    .hidden()
                                }
                            
                                // primaryQuitButton
                                if requireDualQuitButtons {
                                    if self.hasClickedSecondaryQuitButton {
                                        Button {
                                            AppKit.NSApp.terminate(nil)
                                        } label: {
                                            Text(primaryQuitButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    } else {
                                        Button {
                                            hasClickedSecondaryQuitButton = true
                                        } label: {
                                            Text(primaryQuitButtonText)
                                                .frame(minWidth: 35)
                                        }
                                        .hidden()
                                    }
                                } else {
                                    Button {
                                        AppKit.NSApp.terminate(nil)
                                    } label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 0.5)
                    .frame(width: 550)
                }
                .frame(width: 600)
                .padding(.bottom, 15)
                // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
                .onAppear(perform: nudgeStartLogic)
            }
            .frame(width: 900, height: 450)
        }
    }
}

// Sheet view for Screenshot zoom
struct screenShotZoom: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()})
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .frame(width: 35, height: 35)
                Spacer()
            }
        
            HStack {
                Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
                    if colorScheme == .dark && FileManager.default.fileExists(atPath: screenShotDarkPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotDarkPath))
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    } else {
                        Image("CompanyScreenshotIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(maxHeight: 512)
                    }
                  }
                )
                .padding(.top, -75)
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
    }
}


// Sheet view for Device Information
struct deviceInfo: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // State variables
    @State var systemConsoleUsername = Utils().getSystemConsoleUsername()
    @State var serialNumber = Utils().getSerialNumber()
    @State var cpuType = Utils().getCPUTypeString()
    
    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()})
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .frame(width: 35, height: 35)
                
                Spacer()
            }
            
            // Additional Device Information
            HStack{
                Text("Additional Device Information")
                    .fontWeight(.bold)
            }
            .padding(.vertical, 1)

            // Username
            HStack{
                Text("Username:")
                Text(self.systemConsoleUsername)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)

            // Serial Number
            HStack{
                Text("Serial Number:")
                Text(self.serialNumber)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)

            // Architecture
            HStack{
                Text("Architecture:")
                Text(self.cpuType)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)
            
            // Language
            HStack{
                Text("Language:")
                Text(language)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(width: 350, height: 175)
    }
}


#if DEBUG
// Xcode preview for both light and dark mode
struct Nudge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
