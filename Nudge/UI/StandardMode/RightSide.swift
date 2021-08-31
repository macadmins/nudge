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
    
    // Some constants for defining element positioning and whatnot
    let contentWidthPadding     : CGFloat = 25
    let bottomPadding           : CGFloat = 10
    let topPadding              : CGFloat = 18
    let contentHeight           : CGFloat = 245
    let contentBackgroundHeight : CGFloat = 350
    let screenshotMaxHeight     : CGFloat = 120
    let buttonTextMinWidth      : CGFloat = 35
    
    let hourTimeInterval        : CGFloat = 3600
    let dayTimeInterval         : CGFloat = 86400
    
    // Nudge UI
    var body: some View {
        let darkMode = colorScheme == .dark
        let screenShotPath = Utils().getScreenShotPath(darkMode: darkMode)
        let screenShotExists = FileManager.default.fileExists(atPath: screenShotPath)
        // Right side of Nudge
        VStack {
            Spacer()
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
            .padding(.leading, contentWidthPadding)
            .padding(.trailing, contentWidthPadding)
            
            // I'm kind of impressed with myself
            VStack {
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
                
                // Horizontal line
                HStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                
                // mainContentNote
                HStack {
                    Text(mainContentNote)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(Color.red)
                    Spacer()
                }

                // mainContentText
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
                .frame(height: contentHeight)

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
                                .frame(maxHeight: screenshotMaxHeight)
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
                                    .frame(maxHeight: screenshotMaxHeight)
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
                                    .frame(maxHeight: screenshotMaxHeight)
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
                .padding(.leading, contentWidthPadding)
                .padding(.trailing, contentWidthPadding)
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(5)
            .frame(height: contentBackgroundHeight)
                
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
                                            .frame(minWidth: buttonTextMinWidth)
                                    }
                                    if Utils().allow1HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(hourTimeInterval), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(hourTimeInterval))
                                            updateDeferralUI()
                                        } label: {
                                            Text(oneHourDeferralButtonText)
                                                .frame(minWidth: buttonTextMinWidth)
                                        }
                                    }
                                    if Utils().allow24HourDeferral() {
                                        Button {
                                            nudgeDefaults.set(nudgeEventDate.addingTimeInterval(dayTimeInterval), forKey: "deferRunUntil")
                                            userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(dayTimeInterval))
                                            updateDeferralUI()
                                        } label: {
                                            Text(oneDayDeferralButtonText)
                                                .frame(minWidth: buttonTextMinWidth)
                                        }
                                    }
                                    if Utils().allowCustomDeferral() {
                                        Divider()
                                        Button {
                                            self.showDeferView.toggle()
                                        } label: {
                                            Text(customDeferralButtonText)
                                                .frame(minWidth: buttonTextMinWidth)
                                        }
                                    }
                                }
                                .frame(maxWidth: 100)
                            } else {
                                Button {
                                    Utils().userInitiatedExit()
                                } label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: buttonTextMinWidth)
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
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.leading, contentWidthPadding)
        .padding(.trailing, contentWidthPadding)
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
