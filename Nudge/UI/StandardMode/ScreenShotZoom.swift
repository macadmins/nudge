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
        VStack {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()})
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .frame(width: 35, height: 35)
                Spacer()
            }
            
            HStack {
                Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
                    if colorScheme == .dark && FileManager.default.fileExists(atPath: screenShotDarkPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotDarkPath))
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 512)
                    } else {
                        Image("CompanyScreenshotIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(maxHeight: 512)
                    }
                }
                )
                .padding(.top, -75)
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
    }
}
