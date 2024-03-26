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
        ImageManager().getScreenShotPath(colorScheme: colorScheme)
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
        AsyncImage(url: UIUtilities().createCorrectURLType(from: screenShotPath)) { phase in
            switch phase {
                case .empty:
                    Image(systemName: "square.dashed")
                        .customResizable(maxHeight: 675)
                        .customFontWeight(fontWeight: .ultraLight)
                        .opacity(0.05)
                case .failure:
                    Image(systemName: "questionmark.square.dashed")
                        .customResizable(maxHeight: 675)
                        .customFontWeight(fontWeight: .ultraLight)
                        .opacity(0.05)
                case .success(let image):
                    image
                        .scaledToFit()
                @unknown default:
                    EmptyView()
            }
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
