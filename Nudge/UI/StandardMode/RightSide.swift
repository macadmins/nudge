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
    
    var body: some View {
        VStack {
            Spacer()
            headerSection
                .padding([.leading, .trailing], contentWidthPadding)
                .padding(.bottom, bottomPadding)
            informationSection
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(5)
            Spacer()
        }
        .padding(.top, screenshotTopPadding)
        .padding(.bottom, bottomPadding)
        .padding([.leading, .trailing], contentWidthPadding)
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
                    Utils().updateDevice()
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
        .padding([.leading, .trailing], contentWidthPadding)
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
            if let image = Utils().getScreenShotImage(path: Utils().getScreenShotPath(colorScheme: colorScheme)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: screenshotMaxHeight)
            } else {
                Image("CompanyScreenshotIcon") // Fallback image
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: screenshotMaxHeight)
            }
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
        let imagePath = Utils().getScreenShotPath(colorScheme: colorScheme)
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
