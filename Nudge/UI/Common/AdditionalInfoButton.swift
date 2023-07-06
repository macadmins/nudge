//
//  AdditionalInfoButton.swift
//  AdditionalInfoButton
//
//  Created by Bart Reardon on 31/8/21.
//

import SwiftUI

struct AdditionalInfoButton: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Button(action: {
                Utils().userInitiatedDeviceInfo()
                appState.additionalInfoViewIsPresented = true
            }) {
                Image(systemName: "questionmark.circle")
            }
            .padding(.top, 1.0)
            .buttonStyle(.plain)
            .help("Click for additional device information".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .sheet(isPresented: $appState.additionalInfoViewIsPresented) {
                DeviceInfo()
            }
            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    AdditionalInfoButton()
        .environmentObject(nudgePrimaryState)
        .previewDisplayName("AdditionalInfoButton")
}
#endif
