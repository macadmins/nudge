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
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let screenShotPath = Utils().getScreenShotPath(colorScheme: appState.colorScheme)
        let screenShotExists = FileManager.default.fileExists(atPath: screenShotPath)
        VStack {
            Spacer()
            VStack(alignment: .center) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                .font(.largeTitle)
                                .minimumScaleFactor(0.5)
                                .frame(maxHeight: 25)
                                .lineLimit(1)
                        }

                        HStack {
                            Text(subHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
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

            VStack {
                VStack {
                    Spacer()
                        .frame(height: 10)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(mainContentHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            HStack {
                                Text(mainContentSubHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                    .font(.callout)
                                Spacer()
                            }
                        }
                        Spacer()

                        Button(action: {
                            Utils().updateDevice()
                        }) {
                            Text(actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    
                    // Horizontal line
                    HStack{
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                    }

                    HStack {
                        Text(mainContentNote.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                        Spacer()
                    }

                    ScrollView(.vertical) {
                        VStack {
                            HStack {
                                Text(mainContentText.replacingOccurrences(of: "\\n", with: "\n").localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                    .font(.callout)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                    
                    if screenShotExists || forceScreenShotIconMode() {
                        HStack {
                            Spacer()
                            if screenShotExists {
                                Button {
                                    appState.screenShotZoomViewIsPresented = true
                                } label: {
                                    Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                                        .resizable()
                                        .scaledToFit()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: screenshotMaxHeight)
                                }
                                .buttonStyle(.plain)
                                .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                .sheet(isPresented: $appState.screenShotZoomViewIsPresented) {
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
                                        appState.screenShotZoomViewIsPresented = true
                                    } label: {
                                        Image("CompanyScreenshotIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: screenshotMaxHeight)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                    .sheet(isPresented: $appState.screenShotZoomViewIsPresented) {
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
                                        appState.screenShotZoomViewIsPresented = true
                                    } label: {
                                        Image("CompanyScreenshotIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: screenshotMaxHeight)
                                    }
                                    .buttonStyle(.plain)
                                    .hidden()
                                    .help("Click to zoom into screenshot".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                    .sheet(isPresented: $appState.screenShotZoomViewIsPresented) {
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
        .padding(.top, screenshotTopPadding)
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
            StandardModeRightSide()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("RightSide (\(id))")
        }
    }
}
#endif
