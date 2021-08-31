//
//  InformationButton.swift
//  InformationButton
//
//  Created by Bart Reardon on 1/9/21.
//

import SwiftUI

struct InformationButton: View {
    var body: some View {
        HStack {
            // informationButton
            if aboutUpdateURL != "" {
                Button(action: Utils().openMoreInfo, label: {
                    Text(informationButtonText)
                        .foregroundColor(.secondary)
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

struct InformationButton_Previews: PreviewProvider {
    static var previews: some View {
        InformationButton()
    }
}
