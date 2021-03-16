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
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let darkMode = colorScheme == .dark
        let screenShotPath = Utils().getScreenShotPath(darkMode: darkMode)
        VStack(alignment: .center) {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()})
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage()))
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
                Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
                    if FileManager.default.fileExists(atPath: screenShotPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    } else {
                        Image("CompanyScreenshotIcon")
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    }
                }
                )
                .buttonStyle(PlainButtonStyle())
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage()))
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
        .frame(maxWidth: 900, maxHeight: 450)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct ScreenShotZoomPreview: PreviewProvider {
    static var previews: some View {
        Group {
            ScreenShotZoom().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.light)
            ScreenShotZoom().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
