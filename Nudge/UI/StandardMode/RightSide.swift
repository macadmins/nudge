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
    @EnvironmentObject var manager: PolicyManager
    
    // State variables
    @State var requireDualQuitButtons = Utils().requireDualQuitButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasClickedSecondaryQuitButton = false
    @State var deferralCountUI = 0
    
    // Modal view for screenshot and device info
    @State var showSSDetail = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Nudge UI
    var body: some View {
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
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeRightSidePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                StandardModeLeftSide().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            StandardModeRightSide().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
