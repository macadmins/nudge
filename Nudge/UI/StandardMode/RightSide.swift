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
    @Environment(\.colorScheme) var colorScheme

    private var screenShotPath: String {
        ImageManager().getScreenShotPath(colorScheme: colorScheme)
    }

    var body: some View {
        VStack {
            Spacer()
            headerSection
                .padding([.leading, .trailing], UIConstants.contentWidthPadding)
                .padding(.bottom, UIConstants.bottomPadding)
            informationSection
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(5)
            Spacer()
        }
        .padding(.top, UIConstants.screenshotTopPadding)
        .padding(.bottom, UIConstants.bottomPadding)
        .padding([.leading, .trailing], UIConstants.contentWidthPadding)
    }
    
    private var headerSection: some View {
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
                        Text(UserInterfaceVariables.subHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.body)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var informationSection: some View {
        VStack {
            Spacer()
                .frame(height: 10)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(UserInterfaceVariables.mainContentHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.callout)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Text(UserInterfaceVariables.mainContentSubHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.callout)
                        Spacer()
                    }
                }
                Spacer()
                
                Button(action: {
                    UIUtilities().updateDevice()
                }) {
                    Text(UserInterfaceVariables.actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            HStack {
                Text(UserInterfaceVariables.mainContentNote.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                Spacer()
            }
            
            ScrollView(.vertical) {
                VStack {
                    HStack {
                        Text(UserInterfaceVariables.mainContentText.replacingOccurrences(of: "\\n", with: "\n").localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
            screenshotDisplay
        }
        .padding([.leading, .trailing], UIConstants.contentWidthPadding)
    }
    
    private var screenshotDisplay: some View {
        Group {
            if shouldShowScreenshot {
                screenshotButton
            } else {
                EmptyView()
            }
        }
    }

    private var screenshotButton: some View {
        Button(action: { appState.screenShotZoomViewIsPresented = true }) {
            Image(nsImage: ImageManager().getCorrectImage(path: screenShotPath, type: "ScreenShot"))
                .customResizable(maxHeight: UIConstants.screenshotMaxHeight)
        }
        .buttonStyle(.plain)
        .help(UserInterfaceVariables.screenShotAltText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        .sheet(isPresented: $appState.screenShotZoomViewIsPresented) {
            ScreenShotZoom()
        }
        .onHoverEffect()
    }
    
    private var shouldShowScreenshot: Bool {
        // Logic to determine if the screenshot should be shown
        let imagePath = ImageManager().getScreenShotPath(colorScheme: colorScheme)
        return FileManager.default.fileExists(atPath: imagePath) || imagePath.starts(with: "data:") || forceScreenShotIconMode()
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        StandardModeRightSide()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("RightSide (\(id))")
    }
}
#endif
