//
//  DeviceInfo.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// Sheet view for Device Information
struct DeviceInfo: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.locale) var locale: Locale
    
    // State variables
    @State var systemConsoleUsername = Utils().getSystemConsoleUsername()
    @State var serialNumber = Utils().getSerialNumber()
    @State var cpuType = Utils().getCPUTypeString()
    @State var nudgeVersion = Utils().getNudgeVersion()
    
    var body: some View {
        VStack(alignment: .center, spacing: 7.5) {
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
                .buttonStyle(.plain)
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
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
            // Additional Device Information
            Group {
                HStack{
                    Text("Additional Device Information".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                        .fontWeight(.bold)
                }
                // Username
                HStack{
                    Text("Username:".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                    Text(self.systemConsoleUsername)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                // Serial Number
                HStack{
                    Text("Serial Number:".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                    Text(self.serialNumber)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                // Architecture
                HStack{
                    Text("Architecture:".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                    Text(self.cpuType)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                // Language
                HStack{
                    Text("Language:".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                    Text(language)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                // Nudge Version
                HStack{
                    Text("Version:".localized(desiredLanguage: getDesiredLanguage(locale: locale)))
                    Text(self.nudgeVersion)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
            }
            
            // Vertically align Additional Device Information to center
            Spacer()
        }
        .frame(width: 400, height: 200)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct DeviceInfo_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            DeviceInfo()
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("DeviceInfo (\(id))")
        }
    }
}
#endif

