//
//  StandardMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Standard Mode
struct StandardMode: View {
    @ObservedObject var viewObserved: ViewState

    // enforce a fixed width for the left hand side
    let leftSideWidth: CGFloat = 300

    let bottomPadding: CGFloat = 10
    let contentWidthPadding: CGFloat = 25

    // Nudge UI
    var body: some View {
        VStack {
            HStack {
                // Left side of Nudge
                StandardModeLeftSide(viewObserved: viewObserved)
                    .frame(width: leftSideWidth)

                // Vertical Line
                VStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1)
                }
                
                // Right side of Nudge
                StandardModeRightSide(viewObserved: viewObserved)
            }
            // Bottom buttons
            HStack {
                // informationButton
                InformationButton()
                
                if viewObserved.allowButtons || Utils().demoModeEnabled() {
                    PrimaryQuitButton(viewObserved: viewObserved)
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.leading, contentWidthPadding)
            .padding(.trailing, contentWidthPadding)
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardMode_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                StandardMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
