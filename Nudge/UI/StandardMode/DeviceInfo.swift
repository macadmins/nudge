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
                .buttonStyle(PlainButtonStyle())
                .help("Click to close")
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
                    Text("Additional Device Information")
                        .fontWeight(.bold)
                }
                // Username
                HStack{
                    Text("Username:")
                    Text(self.systemConsoleUsername)
                        .foregroundColor(.secondary)
                }
                // Serial Number
                HStack{
                    Text("Serial Number:")
                    Text(self.serialNumber)
                        .foregroundColor(.secondary)
                }
                // Architecture
                HStack{
                    Text("Architecture:")
                    Text(self.cpuType)
                        .foregroundColor(.secondary)
                }
                // Language
                HStack{
                    Text("Language:")
                    Text(language)
                        .foregroundColor(.secondary)
                }
                // Nudge Version
                HStack{
                    Text("Version:")
                    Text(self.nudgeVersion)
                        .foregroundColor(.secondary)
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
struct DeviceInfoPreview: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                DeviceInfo().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.3") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            DeviceInfo().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.3") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif

