//
//  ScreenShotZoomSheet.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// Sheet view for Screenshot zoom
struct ScreenShotZoom: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private var screenShotPath: String {
        Utils().getScreenShotPath(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .center) {
            closeButton
            screenShotButton
            Spacer() // Vertically align Screenshot to center
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(maxWidth: 900)
    }
    
    private var closeButton: some View {
        HStack {
            Button(action: { appState.screenShotZoomViewIsPresented = false }) {
                CloseButton()
            }
            .buttonStyle(.plain)
            .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            .onHoverEffect()
            .frame(width: 30, height: 30)
            Spacer() // Horizontally align close button to left
        }
    }
    
    private var screenShotButton: some View {
        HStack {
            Button(action: { appState.screenShotZoomViewIsPresented = false }) {
                screenShotImage
            }
            .buttonStyle(.plain)
            .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            .onHoverEffect()
        }
    }
    
    private var screenShotImage: some View {
        if screenShotPath.starts(with: "data:") {
            Image(nsImage: Utils().createImageBase64(base64String: screenShotPath))
                .customMaxHeightResizable(maxHeight: 675)
        } else if FileManager.default.fileExists(atPath: screenShotPath) {
            Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                .customMaxHeightResizable(maxHeight: 675)
        } else {
            Image("CompanyScreenshotIcon")
                .customMaxHeightResizable(maxHeight: 675)
        }
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        ScreenShotZoom()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("ScreenShotZoom (\(id))")
    }
}
#endif
