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
    
    // State variables
    @State var systemConsoleUsername = Utils().getSystemConsoleUsername()
    @State var serialNumber = Utils().getSerialNumber()
    @State var cpuType = Utils().getCPUTypeString()
    @State var nudgeVersion = Utils().getNudgeVersion()
    
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
            
            // Additional Device Information
            HStack{
                Text("Additional Device Information")
                    .fontWeight(.bold)
            }
            .padding(.vertical, 1)
            
            // Username
            HStack{
                Text("Username:")
                Text(self.systemConsoleUsername)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)
            
            // Serial Number
            HStack{
                Text("Serial Number:")
                Text(self.serialNumber)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)
            
            // Architecture
            HStack{
                Text("Architecture:")
                Text(self.cpuType)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 1)
            
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
            .padding(.vertical, 1)
            
            Spacer()
        }
        .frame(width: 400, height: 200)
    }
}

