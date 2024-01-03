//
//  DeviceInfo.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

struct DeviceInfo: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 7.5) {
            closeButton
            Text("Additional Device Information".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .fontWeight(.bold)
            infoRow(label: "Username:", value: Utils().getSystemConsoleUsername())
            infoRow(label: "Serial Number:", value: Utils().getSerialNumber())
            infoRow(label: "Architecture:", value: Utils().getCPUTypeString())
            infoRow(label: "Language:", value: languageCode)
            infoRow(label: "Version:", value: Utils().getNudgeVersion())
            Spacer() // Vertically align Additional Device Information to center
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 400, height: 200)
    }
    
    private var closeButton: some View {
        HStack {
            Button(action: { appState.additionalInfoViewIsPresented = false }) {
                CloseButton()
            }
            .buttonStyle(.plain)
            .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            .onHoverEffect()
            .frame(width: 30, height: 30)
            Spacer() // Horizontally align close button to left
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            Text(value)
                .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
        }
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        DeviceInfo()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("DeviceInfo (\(id))")
    }
}
#endif
