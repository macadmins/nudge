//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Normal Mode
struct NudgeNormalMode: View {
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
                    VStack(alignment: .leading) {
                        HStack {
                            VStack {
                                // mainHeader
                                HStack {
                                    Text(getMainHeader())
                                        .font(.largeTitle)
                                        .minimumScaleFactor(0.5)
                                        .frame(maxHeight: 25)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                // subHeader
                                HStack {
                                    Text(subHeader)
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, 0.5)
                .padding(.leading, 20.0)
                .padding(.trailing, 20.0)
                .frame(width: 550)

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
                        .frame(width: 530)

                        // mainContentNote
                        HStack {
                            Text(mainContentNote)
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(Color.red)
                            Spacer()
                        }
                        .padding(.leading, 20.0)
                        .padding(.trailing, 20.0)

                        // mainContentText
                        HStack {
                            VStack {
                                Text(mainContentText)
                                    .font(.callout)
                                    .font(.body)
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                        .frame(minHeight: 125.0)
                        .frame(maxHeight: 125.0)
                        .padding(.leading, 20.0)
                        .padding(.trailing, 20.0)

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
                                        .frame(maxHeight: 125)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Click to zoom into screenshot")
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
                            } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                                Button {
                                    self.showSSDetail.toggle()
                                } label: {
                                    Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                                        .resizable()
                                        .scaledToFit()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 125)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Click to zoom into screenshot")
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
                                            .frame(maxHeight: 125)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Click to zoom into screenshot")
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
                                    Text("Force a 125 pixel")
                                        .hidden()
                                        .frame(minHeight: 125)
                                }
                            }

                            Spacer()
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(5)
                    .frame(width: 550)

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
                                        userHasClickedSecondaryQuitButton()
                                    } label: {
                                        Text(secondaryQuitButtonText)
                                    }
                                    .padding(.trailing, 20.0)
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
                                        Utils().exitNudge()
                                    } label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                    }
                                    .padding(.trailing, 20.0)
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

#if DEBUG
// Xcode preview for both light and dark mode
struct NudgeNormalModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                NudgeNormalMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            NudgeNormalMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
