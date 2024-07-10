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
                        Text(.init(appState.deviceSupportedByOSVersion ? getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : getMainHeaderUnsupported().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                            .font(.largeTitle)
                            .minimumScaleFactor(0.5)
                            .frame(maxHeight: 25)
                            .lineLimit(1)
                    }

                    HStack {
                        Text(.init(appState.deviceSupportedByOSVersion ? UserInterfaceVariables.subHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : UserInterfaceVariables.subHeaderUnsupported.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                            .font(.body)
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
                        Text(.init(appState.deviceSupportedByOSVersion ? UserInterfaceVariables.mainContentHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : UserInterfaceVariables.mainContentHeaderUnsupported.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                            .font(.callout)
                        Spacer()
                    }
                    HStack {
                        Text(appState.deviceSupportedByOSVersion ? UserInterfaceVariables.mainContentSubHeader.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : UserInterfaceVariables.mainContentSubHeaderUnsupported.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.callout)
                        Spacer()
                    }
                }
                Spacer()
                
                if appState.deviceSupportedByOSVersion {
                    Button(action: {
                        UIUtilities().updateDevice()
                    }) {
                        Text(.init(UserInterfaceVariables.actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    InformationButtonAsAction()
                }
            }
            
            Divider()
            
            HStack {
                Text(.init(appState.deviceSupportedByOSVersion ? UserInterfaceVariables.mainContentNote.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : UserInterfaceVariables.mainContentNoteUnsupported.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                    .font(.callout)
                    .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                Spacer()
            }
            
            ScrollView(.vertical) {
                VStack {
                    HStack {
                        Text(.init(appState.deviceSupportedByOSVersion ? UserInterfaceVariables.mainContentText.replacingOccurrences(of: "\\n", with: "\n").localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : UserInterfaceVariables.mainContentTextUnsupported.replacingOccurrences(of: "\\n", with: "\n").localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
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
            if shouldShowScreenshot() {
                screenshotButton
            } else {
                EmptyView()
            }
        }
    }

    private var screenshotButton: some View {
        Button(action: { appState.screenShotZoomViewIsPresented = true }) {
            AsyncImage(url: UIUtilities().createCorrectURLType(from: screenShotPath)) { phase in
                switch phase {
                    case .empty:
                        Image(systemName: "square.dashed")
                            .customResizable(maxHeight: UIConstants.screenshotMaxHeight)
                            .customFontWeight(fontWeight: .ultraLight)
                            .opacity(0.05)
                    case .failure:
                        Image(systemName: "questionmark.square.dashed")
                            .customResizable(maxHeight: UIConstants.screenshotMaxHeight)
                            .customFontWeight(fontWeight: .ultraLight)
                            .opacity(0.05)
                    case .success(let image):
                        image
                            .customResizable(maxHeight: UIConstants.screenshotMaxHeight)
                    @unknown default:
                        EmptyView()
                }
            }
        }
        .buttonStyle(.plain)
        .help(UserInterfaceVariables.screenShotAltText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        .sheet(isPresented: $appState.screenShotZoomViewIsPresented) {
            ScreenShotZoom()
        }
        .onHoverEffect()
    }

    private func shouldShowScreenshot() -> Bool {
        ["data:", "https://", "http://", "file://"].contains(where: screenShotPath.starts(with:)) || FileManager.default.fileExists(atPath: screenShotPath) || forceScreenShotIconMode()
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
