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
    
    var body: some View {
        let screenShotPath = Utils().getScreenShotPath(colorScheme: colorScheme)

        VStack(alignment: .center) {
            HStack {
                Button(
                    action: {
                        appState.screenShotZoomViewIsPresented = false
                    }
                )
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .frame(width: 30, height: 30)
                
                // Horizontally align close button to left
                Spacer()
            }
            
            HStack {
                Button(
                    action: {
                        appState.screenShotZoomViewIsPresented = false
                    }, label: {
                    if screenShotPath.starts(with: "data:") {
                        Image(nsImage: Utils().createImageBase64(base64String: screenShotPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(maxHeight: 675)
                    } else {
                        if FileManager.default.fileExists(atPath: screenShotPath) {
                            Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 675)
                        } else {
                            Image("CompanyScreenshotIcon")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 675)
                        }
                    }
                }
                )
                .buttonStyle(.plain)
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            // Vertically align Screenshot to center
            Spacer()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(maxWidth: 900)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct ScreenShotZoom_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            ScreenShotZoom()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("ScreenShotZoom (\(id))")
        }
    }
}
#endif
