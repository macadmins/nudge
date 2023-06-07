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
    @Environment(\.locale) var locale: Locale
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    // Modal view for screenshot and deferral info
    @State var showSSDetail = false
    
    // Some constants for defining element positioning and whatnot
    let contentWidthPadding: CGFloat = 25
    let bottomPadding: CGFloat = 10
    let topPadding: CGFloat = 28
    let screenshotMaxHeight: CGFloat = 120
    
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
                            Text(getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                                .font(.largeTitle)
                                .minimumScaleFactor(0.5)
                                .frame(maxHeight: 25)
                                .lineLimit(1)
                        }
                        // subHeader
                        HStack {
                            Text(subHeader.localized(desiredLanguage: getDesiredLanguage(locale: locale)))
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
            .padding(.bottom, bottomPadding)
            
            // I'm kind of impressed with myself
            VStack {
                VStack {
                    Spacer()
                        .frame(height: 10)
                    // mainContentHeader / mainContentSubHeader
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(mainContentHeader.localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            HStack {
                                Text(mainContentSubHeader.localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                                    .font(.callout)
                                Spacer()
                            }
                        }
                        Spacer()
                        // actionButton
                        Button(action: {
                            Utils().updateDevice()
                        }) {
                            Text(actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: locale)))
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
                        Text(mainContentNote.localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(differentiateWithoutColor ? .accessibleRed : .red)
                        Spacer()
                    }
                    
                    // mainContentText
                    ScrollView(.vertical) {
                        VStack {
                            HStack {
                                Text(mainContentText.replacingOccurrences(of: "\\n", with: "\n").localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                                    .font(.callout)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                    
                    if screenShotExists || forceScreenShotIconMode() {
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
                                .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
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
                                    .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
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
                                    .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                                    .sheet(isPresented: $showSSDetail) {
                                        ScreenShotZoom()
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.leading, contentWidthPadding)
                .padding(.trailing, contentWidthPadding)
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(5)
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.leading, contentWidthPadding)
        .padding(.trailing, contentWidthPadding)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeRightSide_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            StandardModeRightSide(viewObserved: nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("RightSide (\(id))")
        }
    }
}
#endif
