//
//  InformationButton.swift
//  InformationButton
//
//  Created by Bart Reardon on 1/9/21.
//

import SwiftUI

struct InformationButton: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack {
            // informationButton
            if aboutUpdateURL != "" {
                Button(action: Utils().openMoreInfo, label: {
                    Text(informationButtonText)
                        .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                }
                )
                .buttonStyle(.plain)
                .help("Click for more information about the security update".localized(desiredLanguage: getDesiredLanguage()))
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
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                InformationButton()
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                InformationButton()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
