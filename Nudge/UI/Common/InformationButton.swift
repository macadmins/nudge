//
//  InformationButton.swift
//  InformationButton
//
//  Created by Bart Reardon on 1/9/21.
//

import SwiftUI

struct InformationButton: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            informationButton
            Spacer() // Force the button to the left
        }
    }
    
    private var informationButton: some View {
        guard OSVersionRequirementVariables.aboutUpdateURL != "" else { return AnyView(EmptyView()) }

        return AnyView(
            Button(action: UIUtilities().openMoreInfo) {
                Text(.init(UserInterfaceVariables.informationButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
                    .foregroundColor(dynamicTextColor)
            }
                .buttonStyle(.plain)
                .help("Click for more information about the security update.".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .onHoverEffect()
        )
    }
    
    private var dynamicTextColor: Color {
        colorScheme == .light ? Color.accessibleSecondaryLight : Color.accessibleSecondaryDark
    }
}

// Technically not information button as this is using the actionButtonTextUnsupported
struct InformationButtonAsAction: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            UIUtilities().openMoreInfo()
            UIUtilities().postUpdateDeviceActions(userClicked: true, unSupportedUI: true)
        }) {
            Text(.init(UserInterfaceVariables.actionButtonTextUnsupported.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale))))
        }
        .help("Click for more information about replacing your device.".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        InformationButton()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("InformationButton (\(id))")
    }
}
#endif
