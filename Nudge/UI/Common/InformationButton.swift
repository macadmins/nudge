//
//  InformationButton.swift
//  InformationButton
//
//  Created by Bart Reardon on 1/9/21.
//

import SwiftUI

struct InformationButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // informationButton
            if aboutUpdateURL != "" {
                Button(action: Utils().openMoreInfo, label: {
                    Text(informationButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                )
                .buttonStyle(.plain)
                .help("Click for more information about the security update".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
            }
            // Force the button to the left with a spacer
            Spacer()
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct InformationButton_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            InformationButton()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("InformationButton (\(id))")
        }
    }
}
#endif
