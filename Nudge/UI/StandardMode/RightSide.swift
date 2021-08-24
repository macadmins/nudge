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
    @ObservedObject var viewObserved: ViewState
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    // State variables
    @State var hasClickedSecondaryQuitButton = false
    @State var nudgeEventDate = Date()
    @State var nudgeCustomEventDate = Date()
    
    // Modal view for screenshot and deferral info
    @State var showSSDetail = false
    @State var showDeferView = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let screenShotPath = Utils().getScreenShotPath(darkMode: darkMode)
        let screenShotExists = FileManager.default.fileExists(atPath: screenShotPath)
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
                if !screenShotExists && !forceScreenShotIconMode() {
                    ScrollView(.vertical) {
                        VStack {
                            HStack {
                                Text(mainContentText.replacingOccurrences(of: "\\n", with: "\n"))
                                    .font(.callout)
                                    .font(.body)
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .frame(minHeight: 245.0)
                    .frame(maxHeight: 245.0)
                    .frame(width: 510)
                } else {
                    ScrollView(.vertical) {
                        VStack {
                            HStack {
                                Text(mainContentText.replacingOccurrences(of: "\\n", with: "\n"))
                                    .font(.callout)
                                    .font(.body)
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .frame(minHeight: 125.0)
                    .frame(maxHeight: 125.0)
                    .frame(width: 510)
                }

                HStack {
                    Spacer()
                    // screenShot
                    if screenShotExists {
                        Button {
                            self.showSSDetail.toggle()
                        } label: {
                            Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
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
                
                if viewObserved.allowButtons || Utils().demoModeEnabled() {
                    // secondaryQuitButton
                    if viewObserved.requireDualQuitButtons {
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
                    if viewObserved.requireDualQuitButtons == false || hasClickedSecondaryQuitButton {
                        HStack(spacing: 20) {
                            if allowUserQuitDeferrals {
                                Menu("Defer".localized(desiredLanguage: getDesiredLanguage())) {
                                    Button {
                                        nudgeDefaults.set(nudgeEventDate, forKey: "deferRunUntil")
                                        updateDeferralUI()
                                    } label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                    }
                                    if Utils().allow1HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(3600), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(3600))
                                            updateDeferralUI()
                                        } label: {
                                            Text(oneHourDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allow24HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(86400), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(86400))
                                            updateDeferralUI()
                                        } label: {
                                            Text(oneDayDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                    if Utils().allowCustomDeferral() {
                                        Divider()
                                        Button {
                                            self.showDeferView.toggle()
                                        } label: {
                                            Text(customDeferralButtonText)
                                                .frame(minWidth: 35)
                                        }
                                    }
                                }
                                .frame(maxWidth: 100)
                            } else {
                                Button {
                                    Utils().userInitiatedExit()
                                } label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: 35)
                                }
                            }
                        }
                        .sheet(isPresented: $showDeferView) {
                        } content: {
                            DeferView(viewObserved: viewObserved)
                        }
                    }
                }
            }
            .frame(width: 510)
        }
        .frame(width: 600, height: 450)
    }

    func updateDeferralUI() {
        viewObserved.userQuitDeferrals += 1
        viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
        Utils().logUserQuitDeferrals()
        Utils().logUserDeferrals()
        Utils().userInitiatedExit()
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeRightSidePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardModeRightSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                StandardModeRightSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
