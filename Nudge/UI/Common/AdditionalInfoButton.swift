//
//  AdditionalInfoButton.swift
//  AdditionalInfoButton
//
//  Created by Bart Reardon on 31/8/21.
//

import SwiftUI

struct AdditionalInfoButton: View {
    
    // Modal view for screenshot and device info
    @State var showDeviceInfo = false
    
    var body: some View {
        HStack {
            Button(action: {
                Utils().userInitiatedDeviceInfo()
                self.showDeviceInfo.toggle()
            }) {
                Image(systemName: "questionmark.circle")
            }
            .padding(.top, 1.0)
            .buttonStyle(.plain)
            .help("Click for additional device information".localized(desiredLanguage: getDesiredLanguage()))
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .sheet(isPresented: $showDeviceInfo) {
                DeviceInfo()
            }
            Spacer()
        }
    }
}

struct AdditionalInfoButton_Previews: PreviewProvider {
    static var previews: some View {
        AdditionalInfoButton()
    }
}
